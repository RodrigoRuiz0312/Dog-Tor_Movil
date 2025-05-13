import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:math';
import 'package:particles_flutter/component/particle/particle.dart';
import 'package:particles_flutter/particles_engine.dart';
import '../widgets/custom_appbar.dart';
import 'ops_mascotas.dart';
import 'perfil_cliente.dart';
import '../widgets/huellaParticle.dart';

//import 'listar_veterinarios.dart'; // Asumo que crearás este archivo
//import 'gestion_citas.dart'; // Asumo que crearás este archivo

class InicioCliente extends StatefulWidget {
  final User user;

  const InicioCliente({super.key, required this.user});

  @override
  State<InicioCliente> createState() => _InicioClienteState();
}

class _InicioClienteState extends State<InicioCliente>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _nombreCompleto;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _drawerAnimationController;
  final List<String> _options = ['Perfil', 'Cerrar sesión'];
  int _selectedIndex = -1;
  bool _isHovered = false;

  // Cambia esto:
  List<bool> _hoverStates = [false, false]; // Para Perfil y Cerrar sesión
  List<AnimationController> _hoverControllers = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.1,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Inicializa los controladores de hover
    for (int i = 0; i < 2; i++) {
      _hoverControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: this,
        ),
      );
    }

    _loadUserData();
  }

  void _onHover(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleHover(int index, bool isHovering) {
    setState(() {
      _hoverStates[index] = isHovering;
      if (isHovering) {
        _hoverControllers[index].forward();
      } else {
        _hoverControllers[index].reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _drawerAnimationController.dispose();
    for (var controller in _hoverControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.user.uid).get();

      if (userDoc.exists && mounted) {
        setState(() {
          _nombreCompleto = userDoc['nombre'] ?? userDoc['nombre'];
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos del usuario: $e");
    }
  }

  void _cerrarSesion() async {
    // Mostrar AwesomeDialog personalizado
    final confirmacion =
        await AwesomeDialog(
          context: context,
          dialogType:
              DialogType
                  .question, // Tipo de ícono (puede ser INFO, WARNING, ERROR, etc.)
          animType: AnimType.scale, // Animación de entrada
          //title: 'Cerrar Sesión',
          desc: '¿Desea cerrar sesión?',
          btnCancelText: 'Cancelar', // Texto botón cancelar
          btnOkText: 'Cerrar Sesión', // Texto botón aceptar
          btnCancelOnPress: () {}, // Al cancelar no hace nada (retornará false)
          btnOkOnPress: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          // Personalización adicional
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
          descTextStyle: TextStyle(fontSize: 30),
          buttonsBorderRadius: BorderRadius.circular(10),
          dismissOnTouchOutside: false, // No se cierra al tocar fuera
        ).show();

    // No necesitas el if(confirmacion) porque AwesomeDialog maneja las acciones internamente
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(user: widget.user, scaffoldKey: _scaffoldKey),
      endDrawer: _buildDrawer(context),
      onEndDrawerChanged: (isOpened) {
        if (isOpened) {
          _drawerAnimationController.forward();
        } else {
          _drawerAnimationController.reset();
          setState(() => _selectedIndex = -1);
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Partículas flotantes de fondo
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: HuellitasParticles(
                      cantidad: 30,
                      ancho: MediaQuery.of(context).size.width - 40,
                      alto: 200,
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(16),
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animation.value,
                          child: Text(
                            _nombreCompleto != null
                                ? '¡Bienvenido, $_nombreCompleto!'
                                : '¡Bienvenido!',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurpleAccent,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.white,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // Opciones en columna
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 2.0,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildOptionCard(
                    context,
                    icon: Icons.pets,
                    title: 'Mascotas',
                    onTap:
                        () => _navigateToScreen(
                          OperacionesMascota(user: widget.user),
                        ),
                  ),
                  /*
                  _buildOptionCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Citas',
                    onTap: () => _navigateToScreen(
                      GestionCitasScreen(user: widget.user), // Asume que existe
                    ),
                  ),
                  _buildOptionCard(
                    context,
                    icon: Icons.medical_services,
                    title: 'Veterinarios',
                    onTap: () => _navigateToScreen(
                      ListaVeterinariosScreen(user: widget.user), // Asume que existe
                    ),
                  ),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Particle> _createParticles() {
    final rng = Random();
    return List<Particle>.generate(25, (index) {
      return Particle(
        color: Colors.blueAccent.withOpacity(0.5),
        size: rng.nextDouble() * 6 + 2, // Tamaño entre 2 y 8
        velocity: Offset(
          rng.nextDouble() * 100 * (rng.nextBool() ? 1 : -1),
          rng.nextDouble() * 100 * (rng.nextBool() ? 1 : -1),
        ),
      );
    });
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 234, 255),
              Color.fromARGB(255, 0, 255, 94),
            ],
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 50),
                Icon(icon, size: 90, color: Colors.white),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 234, 255),
              Color.fromARGB(255, 0, 255, 94),
            ],
          ),
        ),
        child: Column(
          children: [
            // Encabezado
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _drawerAnimationController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/playstore-icon.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Opciones
            Expanded(
              child: Column(
                children: [
                  // Opción Perfil
                  MouseRegion(
                    onEnter: (_) => _handleHover(0, true),
                    onExit: (_) => _handleHover(0, false),
                    child: AnimatedBuilder(
                      animation: _hoverControllers[0],
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_hoverControllers[0].value * 10, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                _hoverControllers[0].value * 0.2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: RotationTransition(
                                turns: _hoverControllers[0],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: const Text(
                                'Perfil',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PerfilClienteScreen(
                                          user: widget.user,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(color: Colors.white54),

                  // Opción Cerrar sesión
                  MouseRegion(
                    onEnter: (_) => _handleHover(1, true),
                    onExit: (_) => _handleHover(1, false),
                    child: AnimatedBuilder(
                      animation: _hoverControllers[1],
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_hoverControllers[1].value * 10, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                _hoverControllers[1].value * 0.2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: RotationTransition(
                                turns: _hoverControllers[1],
                                child: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                ),
                              ),
                              title: const Text(
                                'Cerrar sesión',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: _cerrarSesion,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _defaultLogoutAction(BuildContext context) async {
  await AwesomeDialog(
    context: context,
    dialogType: DialogType.question,
    desc: '¿Desea cerrar sesión?',
    btnCancelText: 'Cancelar',
    btnOkText: 'Cerrar Sesión',
    btnCancelOnPress: () {},
    btnOkOnPress: () async {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    },
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple,
    ),
    descTextStyle: const TextStyle(fontSize: 30),
    buttonsBorderRadius: BorderRadius.circular(10),
    dismissOnTouchOutside: false,
  ).show();
}
