import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListaMascotasScreen extends StatefulWidget {
  final User user;

  const ListaMascotasScreen({super.key, required this.user});

  @override
  State<ListaMascotasScreen> createState() => _ListaMascotasScreenState();
}

class _ListaMascotasScreenState extends State<ListaMascotasScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String uid;

  @override
  void initState() {
    super.initState();
    uid = _auth.currentUser!.uid;
  }

  void _mostrarDetallesMascota(BuildContext context, DocumentSnapshot mascota) {
    final nombre = mascota['nombre'];
    final especie = mascota['especie'];
    final raza = mascota['raza'] ?? 'No especificada';
    final edad = mascota['edad'];
    final senas = mascota['senas'] ?? 'No especificadas';
    final imagenUrl = mascota['imagenUrl'];
    final fechaRegistro = (mascota['fechaRegistro'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(nombre, textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imagenUrl != null)
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
                  SizedBox(height: 20),
                  _buildInfoRow('Especie', especie),
                  _buildInfoRow('Raza', raza),
                  _buildInfoRow('Edad', '$edad años'),
                  _buildInfoRow(
                    'Registrado el',
                    '${fechaRegistro.day}/${fechaRegistro.month}/${fechaRegistro.year}',
                  ),
                  _buildInfoRow('Señas Particulares', senas),
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
      appBar: AppBar(title: const Text('Mis Mascotas')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('users')
                .doc(uid)
                .collection('mascotas')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes mascotas registradas.'));
          }

          final mascotas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: mascotas.length,
            itemBuilder: (context, index) {
              final mascota = mascotas[index];
              final nombre = mascota['nombre'];
              final especie = mascota['especie'];
              final edad = mascota['edad'];
              final imagenUrl = mascota['imagenUrl'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading:
                      imagenUrl != null
                          ? CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              imagenUrl,
                            ),
                            radius: 25,
                          )
                          : CircleAvatar(child: Icon(Icons.pets), radius: 25),
                  title: Text(
                    nombre,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$especie - $edad años'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _mostrarDetallesMascota(context, mascota),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
