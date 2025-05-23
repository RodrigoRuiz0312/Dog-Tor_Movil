import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/appbar_diseño.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListaVeterinariosScreen extends StatefulWidget {
  final User user;

  const ListaVeterinariosScreen({super.key, required this.user});

  @override
  State<ListaVeterinariosScreen> createState() =>
      _ListaVeterinariosScreenState();
}

class _ListaVeterinariosScreenState extends State<ListaVeterinariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _mostrarDetallesVeterinario(
    BuildContext context,
    DocumentSnapshot veterinario,
  ) {
    final nombre = veterinario['nombre'];
    final apellidos = veterinario['apellidos'] ?? '';
    //final especialidad = veterinario['especialidad'] ?? 'No especificada';
    //final telefono = veterinario['telefono'] ?? 'No especificado';
    final email = veterinario['email'];
    //final imagenUrl = veterinario['imagenUrl'];
    final estado = veterinario['estado'] ?? 'pendiente';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Dr. $nombre $apellidos', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*if (imagenUrl != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imagenUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                    ),
                    */
                  SizedBox(height: 20),
                  //_buildInfoRow('Especialidad', especialidad),
                  //_buildInfoRow('Teléfono', telefono),
                  _buildInfoRow('Email', email),
                  _buildInfoRow('Estado', estado),
                  SizedBox(height: 20),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, 'Veterinarios Disponibles en Dog-Tor'),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('users')
                .where('tipoUsuario', isEqualTo: 'Veterinario')
                .where('estado', isEqualTo: 'aceptado')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.pets, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay veterinarios disponibles en este momento.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final veterinarios = snapshot.data!.docs;

          return ListView.builder(
            itemCount: veterinarios.length,
            itemBuilder: (context, index) {
              final veterinario = veterinarios[index];
              final nombre = veterinario['nombre'];
              final apellidos = veterinario['apellidos'] ?? '';
              //final especialidad = veterinario['especialidad'] ?? 'No especificada';
              //final imagenUrl = veterinario['imagenUrl'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading:CircleAvatar(
                            child: Icon(Icons.medical_services),
                            radius: 25,
                          ),
                  title: Text(
                    'Dr. $nombre $apellidos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('gg'),
                  trailing: Icon(Icons.chevron_right),
                  onTap:
                      () => _mostrarDetallesVeterinario(context, veterinario),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
