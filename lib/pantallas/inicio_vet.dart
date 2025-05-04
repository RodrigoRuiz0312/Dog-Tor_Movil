import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InicioVeterinario extends StatefulWidget {
  final User user;

  const InicioVeterinario({super.key, required this.user});

  @override
  State<InicioVeterinario> createState() => _InicioVeterinarioState();
}

class _InicioVeterinarioState extends State<InicioVeterinario>
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
          await _firestore
              .collection('users')
              .doc(widget.user.uid)
              .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _nombreCompleto = userDoc['nombre'] ?? 'Veterinario';
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos del veterinario: $e");
    }
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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
                            ? '¡Bienvenido Dr. $_nombreCompleto!'
                            : '¡Bienvenido Veterinario!',
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
            // Espacio reservado para futuras funcionalidades
            Expanded(
              child: Center(
                child: Text(
                  'Panel de veterinario en desarrollo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
