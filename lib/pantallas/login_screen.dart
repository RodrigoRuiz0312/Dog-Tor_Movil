import 'package:flutter/material.dart';
import 'package:login/pantallas/inicio_cliente.dart';
import 'package:login/pantallas/inicio_vet.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registro_screen.dart';
import '../main.dart';
import 'reestablecer_contraseña_screen.dart';
import '../widgets/loading.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _toogglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const BackgroundImage(imagePath: 'assets/fondoLogin.png'),
          AuthFormContainer(
            heightPercentage: 0.75,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 210),
                  const Text(
                    'INICIA SESION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Campo de texto para el nombre de usuario
                  AuthTextField(
                    controller: _usernameController,
                    hintText: 'Nombre de usuario',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un nombre de usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'Contraseña',
                    prefixIcon: Icons.lock,
                    suffixIcon:
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese una contraseña';
                      }
                      return null;
                    },
                    onSuffixIconTap: _toogglePasswordVisibility,
                  ),
                  const SizedBox(height: 20),
                  // Botón para iniciar sesión
                  AuthButton(
                    text: 'Entrar',
                    onPressed:
                        _isLoading
                            ? null
                            : () async {
                              print("Botón 'Entrar' presionado");

                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() => _isLoading = true);

                                final loadingDialog = showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => LottieLoadingDialog(),
                                );

                                final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                );

                                try {
                                  final user = await authService
                                      .signInWithUsernameAndPassword(
                                        _usernameController.text,
                                        _passwordController.text,
                                      );

                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(); // Cierra el dialog de Lottie

                                  if (user != null) {
                                    // Elimina la navegación manual y deja que AuthWrapper maneje la redirección
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AuthWrapper(),
                                      ),
                                    );
                                    print("Login exitoso");
                                  } else {
                                    setState(() {
                                      _error =
                                          'Error en las credenciales. Intenta de nuevo.';
                                      _isLoading = false;
                                    });
                                  }
                                } catch (e) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();

                                  setState(() {
                                    _error =
                                        'Error al iniciar sesión: ${e.toString()}';
                                    _isLoading = false;
                                  });

                                  // Mostrar error al usuario
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_error),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 1),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistroScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Registrate ahora',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 55, 255),
                            fontSize: 18,
                            decorationColor: Color.fromARGB(171, 33, 149, 243),
                            decorationThickness: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ReestablecerContrasenaScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 53,
            left: 0,
            right: 0,
            child: Center(
              child: AuthHeader(
                title: 'BIENVENIDO A',
                subtitle: 'Dog-Tor',
                imagePath: 'assets/pluto.png',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
