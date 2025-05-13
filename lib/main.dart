import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/pantallas/inicio_cliente.dart';
import 'package:login/services/image_service.dart';
import '../pantallas/login_screen.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'pantallas/admin_panel.dart';
import 'pantallas/inicio_vet.dart';
import 'pantallas/cuenta_pendiente.dart';
import 'pantallas/cuenta_rechazada.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../widgets/loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA4NBMrpHWjuV1LiIJFLcCAO9cUAo6tr2w",
        authDomain: "petassist-76989.firebaseapp.com",
        projectId: "petassist-76989",
        storageBucket: "petassist-76989.firebasestorage.app",
        messagingSenderId: "658759085303",
        appId: "1:658759085303:web:997598cbef2ee1d6b877f2",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ImageService>(create: (_) => ImageService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
        routes: {
          '/admin': (context) => AdminPanel(),
          '/cliente':
              (context) =>
                  InicioCliente(user: FirebaseAuth.instance.currentUser!),
          '/veterinario':
              (context) =>
                  InicioVeterinario(user: FirebaseAuth.instance.currentUser!),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _auth = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          }

          // Usamos FutureBuilder para manejar todas las verificaciones juntas
          return FutureBuilder<Map<String, dynamic>>(
            future: _getUserAuthData(user.uid),
            builder: (context, authDataSnapshot) {
              if (authDataSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              final authData = authDataSnapshot.data;
              if (authData == null) {
                return LoginScreen(); // O algún manejo de error
              }

              // Lógica de redirección simplificada
              if (authData['isAdmin'] == true) {
                return AdminPanel();
              } else if (authData['tipoUsuario'] == 'Veterinario') {
                switch (authData['estado']) {
                  case 'aceptado':
                    return InicioVeterinario(user: user);
                  case 'pendiente':
                    return CuentaPendienteScreen();
                  default:
                    return CuentaRechazadaScreen();
                }
              } else {
                return InicioCliente(user: user);
              }
            },
          );
        }
        return _buildLoadingScreen();
      },
    );
  }

  Future<Map<String, dynamic>> _getUserAuthData(String uid) async {
    final isAdmin = await _auth.isAdmin(uid);
    final userDoc = await _auth.getUserDoc(uid);
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    return {
      'isAdmin': isAdmin,
      'tipoUsuario': userData['tipoUsuario'] ?? 'Cliente',
      'estado': userData['estado'] ?? '',
    };
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child:
            LottieLoadingDialog(), // Reemplaza con tu widget Lottie personalizado
      ),
    );
  }
}

// Constantes compartidas
class AppConstants {
  static const primaryBlue = Color.fromARGB(255, 33, 149, 243);
  static const gradientColors = [
    Color.fromARGB(255, 0, 234, 255),
    Color.fromARGB(255, 0, 255, 94),
  ];
  static const whiteWithOpacity = Colors.white;
  static const buttonTextStyle = TextStyle(
    color: Colors.blue,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}

// Widget reutilizable para el fondo
class BackgroundImage extends StatelessWidget {
  final String imagePath;

  const BackgroundImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
    );
  }
}

// Widget reutilizable para el formulario container
class AuthFormContainer extends StatelessWidget {
  final Widget child;
  final double heightPercentage;

  const AuthFormContainer({
    super.key,
    required this.child,
    this.heightPercentage = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
          width: screenWidth * 0.9,
          height: MediaQuery.of(context).size.height * heightPercentage,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  AppConstants.gradientColors
                      .map((color) => color.withOpacity(0.9))
                      .toList(),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Widget reutilizable para los campos de texto
class AuthTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onSuffixIconTap; // Nueva propiedad
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onSuffixIconTap, // Nueva propiedad
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: Colors.white),
        suffixIcon:
            suffixIcon != null
                ? IconButton(
                  icon: Icon(suffixIcon, color: Colors.white),
                  onPressed: onSuffixIconTap,
                )
                : null,
        hintText: hintText,
        filled: true,
        fillColor: const Color.fromARGB(183, 146, 203, 150).withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}

// Widget reutilizable para el botón de acción
class AuthButton extends StatelessWidget {
  final String text;
  final void Function()? onPressed;

  const AuthButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed:
            onPressed == null
                ? null
                : () {
                  // Ejecuta la función async
                  onPressed!();
                },
        child: Text(text, style: AppConstants.buttonTextStyle),
      ),
    );
  }
}

// Widget reutilizable para el encabezado de la pantalla
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Texto "Dog-Tor" (subtítulo) - Ahora en la parte superior
        Positioned(
          top:
              40, // Ajusta este valor para posicionarlo exactamente donde quieras
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Short',
                  letterSpacing: 7.0,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(subtitle),
              ),
            ),
          ),
        ),
        // Contenido original (imagen y título)
        Column(
          children: [
            // Texto "BIENVENIDO A"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: const Color.fromARGB(222, 33, 149, 243),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 58),
            // Imagen
            Image.asset(imagePath, width: 160, height: 160),
          ],
        ),
      ],
    );
  }
}
