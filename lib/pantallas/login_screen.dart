import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'registro_screen.dart';
import '../main.dart';
import 'reestablecer_contraseña_screen.dart';
import '../widgets/loading.dart';
import 'package:lottie/lottie.dart';

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

  // Método mejorado para mostrar errores
  void _showErrorAnimation(BuildContext context, String errorType) {
    final errorConfig = _getErrorConfig(errorType);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //Lottie.asset(errorConfig['animation'], height: 120, width: 120),
                SizedBox(height: 16),
                Text(
                  errorConfig['title']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  errorConfig['message']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ENTENDIDO',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  Map<String, String> _getErrorConfig(String errorType) {
    switch (errorType) {
      case 'user_not_found':
        return {
          'animation': 'assets/animaciones/user_not_found.json',
          'title': 'Usuario no encontrado',
          'message': 'No existe una cuenta con este nombre de usuario/correo',
        };
      case 'wrong_password':
        return {
          'animation': 'assets/animaciones/wrong_password.json',
          'title': 'Contraseña incorrecta',
          'message': 'La contraseña ingresada no es válida para esta cuenta',
        };
      case 'too_many_attempts':
        return {
          'animation': 'assets/animaciones/too_many_attempts.json',
          'title': 'Demasiados intentos',
          'message':
              'Por seguridad, tu cuenta ha sido temporalmente bloqueada. Intenta nuevamente más tarde.',
        };
      case 'account_disabled':
        return {
          'animation': 'assets/animaciones/account_disabled.json',
          'title': 'Cuenta deshabilitada',
          'message':
              'Esta cuenta ha sido desactivada. Contacta al soporte técnico.',
        };
      case 'invalid_credentials':
        return {
          'animation': 'assets/animaciones/invalid_credentials.json',
          'title': 'Credenciales inválidas',
          'message': 'El usuario o contraseña son incorrectos',
        };
      case 'username_empty':
        return {
          'animation': 'assets/animaciones/empty_field.json',
          'title': 'Campo vacío',
          'message': 'Por favor ingresa tu nombre de usuario o correo',
        };
      case 'password_empty':
        return {
          'animation': 'assets/animaciones/empty_field.json',
          'title': 'Campo vacío',
          'message': 'Por favor ingresa tu contraseña',
        };
      case 'both_fields_empty':
        return {
          'animation': 'assets/animaciones/empty_field.json',
          'title': 'Campos vacíos',
          'message': 'Por favor completa los campos de usuario y contraseña',
        };
      case 'pending_approval':
        return {
          'animation': 'assets/animaciones/pending.json',
          'title': 'Pendiente de aprobación',
          'message': 'Tu cuenta aún no ha sido aprobada por un administrador',
        };
      case 'account_rejected':
        return {
          'animation': 'assets/animaciones/rejected.json',
          'title': 'Cuenta rechazada',
          'message':
              'Tu solicitud de cuenta ha sido rechazada. Contacta soporte.',
        };
      default:
        return {
          'animation': 'assets/animaciones/generic_error.json',
          'title': 'Error inesperado',
          'message': 'Ocurrió un error al intentar iniciar sesión',
        };
    }
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
                    hintText: 'Usuario o correo electrónico',
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

                              final username = _usernameController.text.trim();
                              final password = _passwordController.text.trim();

                              // Validar campos vacíos primero
                              if (username.isEmpty && password.isEmpty) {
                                _showErrorAnimation(
                                  context,
                                  'both_fields_empty',
                                );
                                return;
                              } else if (username.isEmpty) {
                                _showErrorAnimation(context, 'username_empty');
                                return;
                              } else if (password.isEmpty) {
                                _showErrorAnimation(context, 'password_empty');
                                return;
                              }

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
                                        username,
                                        password,
                                      );

                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(); // Cierra Lottie

                                  if (user != null) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AuthWrapper(),
                                      ),
                                    );
                                    print("Login exitoso");
                                  } else {
                                    _showErrorAnimation(
                                      context,
                                      'invalid_credentials',
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();

                                  switch (e.code) {
                                    case 'user-not-found':
                                    case 'invalid-email':
                                      _showErrorAnimation(
                                        context,
                                        'user_not_found',
                                      );
                                      break;
                                    case 'wrong-password':
                                      _showErrorAnimation(
                                        context,
                                        'wrong_password',
                                      );
                                      break;
                                    case 'too-many-requests':
                                      _showErrorAnimation(
                                        context,
                                        'too_many_attempts',
                                      );
                                      break;
                                    case 'user-disabled':
                                      _showErrorAnimation(
                                        context,
                                        'account_disabled',
                                      );
                                      break;
                                    case 'pending-approval':
                                      _showErrorAnimation(
                                        context,
                                        'pending_approval',
                                      );
                                      break;
                                    case 'account-rejected':
                                      _showErrorAnimation(
                                        context,
                                        'account_rejected',
                                      );
                                      break;
                                    default:
                                      _showErrorAnimation(
                                        context,
                                        'generic_error',
                                      );
                                  }
                                } catch (e) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();
                                  _showErrorAnimation(context, 'generic_error');
                                } finally {
                                  setState(() => _isLoading = false);
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
