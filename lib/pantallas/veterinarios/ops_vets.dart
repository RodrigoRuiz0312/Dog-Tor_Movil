import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../veterinaria/registro_veterinaria.dart';
import 'package:login/widgets/appbar_diseño.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../veterinaria/editar_veterinaria.dart';

class OperacionesVeterinaria extends StatelessWidget {
  final User user;

  const OperacionesVeterinaria({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, '¿Qué desea hacer?'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 1,
          childAspectRatio: 2.0,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            // Primer Card - Registrar Veterinaria
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                bool habilitadoRegistro = false;
                bool tieneVeterinaria = false;

                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  tieneVeterinaria = userData['tieneVeterinaria'] ?? false;
                  final esVeterinarioAceptado =
                      userData['estado'] == 'aceptado' &&
                      userData['tipoUsuario'] == 'Veterinario';

                  habilitadoRegistro =
                      esVeterinarioAceptado && !tieneVeterinaria;
                }

                return _buildOptionCard(
                  context,
                  icon: Icons.add_business,
                  title: 'Registrar veterinaria',
                  onTap:
                      habilitadoRegistro
                          ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      RegistrarVeterinariaScreen(user: user),
                            ),
                          )
                          : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tieneVeterinaria
                                      ? 'Ya tienes una veterinaria registrada.'
                                      : 'Tu cuenta aún no ha sido aprobada por el administrador.',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                );
              },
            ),
            // Segundo Card - Editar Veterinaria
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                bool tieneVeterinaria = false;

                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  tieneVeterinaria = userData['tieneVeterinaria'] ?? false;
                }

                return _buildOptionCard(
                  context,
                  icon: Icons.edit,
                  title: 'Editar veterinaria',
                  onTap:
                      tieneVeterinaria
                          ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      EditarVeterinariaScreen(user: user),
                            ),
                          )
                          : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No tienes una veterinaria registrada para editar.',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                );
              },
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
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
                  style: const TextStyle(
                    fontSize: 20,
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
                Icon(icon, size: 50, color: Colors.white),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
