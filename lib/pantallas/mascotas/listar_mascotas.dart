import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:login/widgets/appbar_diseño.dart';

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

  Future<void> _eliminarMascota(String mascotaId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('mascotas')
          .doc(mascotaId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mascota eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la mascota: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      appBar: buildCustomAppBar(context, 'Mis Mascotas'),
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
                        'No tienes mascotas registradas.',
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

          final mascotas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: mascotas.length,
            itemBuilder: (context, index) {
              final mascota = mascotas[index];
              final nombre = mascota['nombre'];
              final especie = mascota['especie'];
              final edad = mascota['edad'];
              final imagenUrl = mascota['imagenUrl'];

              return Dismissible(
                key: Key(mascota.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Confirmar eliminación'),
                          content: Text(
                            '¿Estas seguro de que quieres eliminar a $nombre?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                onDismissed: (direction) {
                  _eliminarMascota(mascota.id);
                },
                child: SizedBox(
                  child: Card(
                    elevation: 7,
                    shadowColor: Colors.greenAccent,
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: ListTile(
                      leading:
                          imagenUrl != null
                              ? CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                  imagenUrl,
                                ),
                                radius: 30,
                              )
                              : CircleAvatar(
                                child: Icon(Icons.pets),
                                radius: 30,
                              ),
                      title: Text(
                        nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text('$especie - $edad años'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => _mostrarDetallesMascota(context, mascota),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
