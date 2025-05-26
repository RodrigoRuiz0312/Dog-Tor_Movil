import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/pantallas/login_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _updateVetStatus(String uid, String status) async {
    try {
      await _firestore.collection('users').doc(uid).update({'estado': status});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validación de Veterinarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _buildVeterinariosList(),
    );
  }

  Widget _buildVeterinariosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('tipoUsuario', isEqualTo: 'Veterinario')
          .where('estado', isEqualTo: 'pendiente')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay veterinarios pendientes'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildVetCard(doc);
          },
        );
      },
    );
  }

  Widget _buildVetCard(DocumentSnapshot doc) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${doc['nombre']} ${doc['apellidos']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${doc['email']}'),
            Text('Cédula: ${doc['cedulaProfesional']}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _updateVetStatus(doc.id, 'rechazado'),
                  child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateVetStatus(doc.id, 'aceptado'),
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}