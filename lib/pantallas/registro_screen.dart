import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../main.dart';

class RegistroScreen extends StatefulWidget {
  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _cedulaController = TextEditingController();

  // Variables de estado
  String _error = '';
  bool _isLoading = false;
  bool _usernameAvailable = true;
  String _selectedUserType = 'Cliente';
  int _currentStep = 0;

  // Constantes para evitar recrear widgets
  static const _textStyleTitle = TextStyle(
    color: Colors.white,
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static const _textStyleButton = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  Future<void> _checkUsernameAvailability() async {
    if (_usernameController.text.trim().isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final available = await authService.isUsernameAvailable(
      _usernameController.text.trim(),
    );

    if (mounted) {
      setState(() => _usernameAvailable = available);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        _nombreController.text.trim(),
        _apellidosController.text.trim(),
        _selectedUserType,
        _selectedUserType == 'Veterinario'
            ? _cedulaController.text.trim()
            : null,
      );

      if (user == null && mounted) {
        setState(() => _error = 'Error al registrar usuario');
      } else if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep >= 3) return;

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (mounted) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep <= 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (mounted) {
      setState(() => _currentStep--);
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _currentStep == index
                    ? Colors.blue
                    : Colors.grey.withOpacity(0.5),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const BackgroundImage(imagePath: 'assets/fondoLogin.png'),
          AuthFormContainer(
            heightPercentage: 0.80,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Text('REGÍSTRATE', style: _textStyleTitle),
                  const SizedBox(height: 20),
                  _buildStepIndicator(),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _PersonalInfoStep(),
                        _UserTypeStep(),
                        _CredentialsStep(),
                        _SummaryStep(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildNavigationButtons(),
                  const SizedBox(height: 10),
                  _buildLoginPrompt(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: Text('Atrás', style: _textStyleButton),
            ),
          ElevatedButton(
            onPressed: _currentStep == 3 ? _register : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            ),
            child: Text(
              _currentStep == 3
                  ? _isLoading
                      ? 'Registrando...'
                      : 'Confirmar'
                  : 'Siguiente',
              style: _textStyleButton,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Ya tienes cuenta?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 1),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Inicia sesión',
            style: TextStyle(
              color: Color.fromARGB(255, 0, 55, 255),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreController.dispose();
    _apellidosController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }
}

// Widgets separados para cada paso (mejor rendimiento)
class _PersonalInfoStep extends StatelessWidget {
  const _PersonalInfoStep();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_RegistroScreenState>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthTextField(
            controller: state._nombreController,
            hintText: 'Nombre (s)',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre completo';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          AuthTextField(
            controller: state._apellidosController,
            hintText: 'Apellido (s)',
            prefixIcon: Icons.person_2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa al menos un apellido';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          AuthTextField(
            controller: state._usernameController,
            hintText: 'Nombre de usuario',
            prefixIcon: Icons.person_pin,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un nombre de usuario';
              }
              if (!state._usernameAvailable) {
                return 'Nombre de usuario no disponible';
              }
              return null;
            },
            onChanged: (_) => state._checkUsernameAvailability(),
          ),
          if (!state._usernameAvailable)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Nombre de usuario no disponible',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTypeStep extends StatelessWidget {
  const _UserTypeStep();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_RegistroScreenState>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona tu tipo de usuario',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          FormField<String>(
            builder: (FormFieldState<String> fieldState) {
              return DropdownButtonFormField<String>(
                value: state._selectedUserType,
                items:
                    ['Cliente', 'Veterinario'].map<DropdownMenuItem<String>>((
                      String type,
                    ) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (String? value) {
                  if (value != null) {
                    state.setState(() => state._selectedUserType = value);
                  }
                  fieldState.didChange(value);
                },
              );
            },
            validator: (String? value) {
              if (value == null) {
                return 'Por favor selecciona un tipo de usuario';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (state._selectedUserType == 'Veterinario')
            AuthTextField(
              controller: state._cedulaController,
              hintText: 'Cédula profesional',
              prefixIcon: Icons.badge,
              validator: (value) {
                if (state._selectedUserType == 'Veterinario' &&
                    (value == null || value.isEmpty)) {
                  return 'Por favor ingresa tu cédula profesional';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }
}

class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_RegistroScreenState>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthTextField(
            controller: state._emailController,
            hintText: 'Correo electrónico',
            prefixIcon: Icons.email,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo electrónico';
              }
              if (!value.contains('@')) {
                return 'Ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          AuthTextField(
            controller: state._passwordController,
            hintText: 'Contraseña',
            prefixIcon: Icons.lock,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          AuthTextField(
            controller: state._confirmPasswordController,
            hintText: 'Confirmar contraseña',
            prefixIcon: Icons.lock,
            obscureText: true,
            validator: (value) {
              if (value != state._passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_RegistroScreenState>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de tu registro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryItem('Nombre completo', state._nombreController.text),
          _buildSummaryItem('Apellidos', state._apellidosController.text),
          _buildSummaryItem(
            'Nombre de usuario',
            state._usernameController.text,
          ),
          _buildSummaryItem('Tipo de usuario', state._selectedUserType),
          if (state._selectedUserType == 'Veterinario')
            _buildSummaryItem(
              'Cédula profesional',
              state._cedulaController.text,
            ),
          _buildSummaryItem('Correo electrónico', state._emailController.text),
          const SizedBox(height: 20),
          const Text(
            'Verifica que toda la información sea correcta antes de continuar.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (state._error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                state._error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
