import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'registro_mascota.dart';
import 'listar_mascotas.dart';
import '../widgets/appbar_diseño.dart';

class PanelCitas extends StatelessWidget {
  final User user;

  const PanelCitas({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, 'Citas Medicas'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 1,
          childAspectRatio: 2.0,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildOptionCard(
              context,
              icon: CupertinoIcons.paw,
              title: 'Agendar nueva cita',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListaMascotasScreen(user: user),
                    ),
                  ),
            ),
            _buildOptionCard(
              context,
              icon: CupertinoIcons.add,
              title: 'Historial Medico',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrarMascotaScreen(user: user),
                    ),
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
