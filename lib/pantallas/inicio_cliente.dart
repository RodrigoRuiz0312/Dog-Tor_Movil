import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registro_mascota.dart';
import 'listar_mascotas.dart';
//import 'listar_veterinarios.dart'; // Asumo que crearás este archivo
//import 'gestion_citas.dart'; // Asumo que crearás este archivo

class InicioCliente extends StatefulWidget {
  final User user;

  const InicioCliente({super.key, required this.user});

  @override
  State<InicioCliente> createState() => _InicioClienteState();
}

class _InicioClienteState extends State<InicioCliente>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _nombreCompleto;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
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
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 0, 234, 255),
                Color.fromARGB(255, 0, 255, 94),
              ],
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: const Text(
            'Dog-Tor',
            style: TextStyle(
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
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Opciones en columna
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildOptionCard(
                    context,
                    icon: Icons.pets,
                    title: 'Mascotas',
                    onTap:
                        () => _navigateToScreen(
                          ListaMascotasScreen(user: widget.user),
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
                  _buildOptionCard(
                    context,
                    icon: Icons.add,
                    title: 'Registrar Mascota',
                    onTap:
                        () => _navigateToScreen(
                          RegistrarMascotaScreen(user: widget.user),
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

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
