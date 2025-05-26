import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/widgets/appbar_diseño.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'agendar_cita.dart';
import '../veterinaria/detalles_vetCliente.dart';

class ListaVeterinariosScreen extends StatefulWidget {
  final User user;

  const ListaVeterinariosScreen({super.key, required this.user});

  @override
  State<ListaVeterinariosScreen> createState() =>
      _ListaVeterinariosScreenState();
}

class _ListaVeterinariosScreenState extends State<ListaVeterinariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _veterinariosConClinica = [];

  @override
  void initState() {
    super.initState();
    _cargarVetsYClinicas();
  }

  Future<void> _cargarVetsYClinicas() async {
    try {
      final veterinarioSnapshot =
          await _firestore
              .collection('users')
              .where('tipoUsuario', isEqualTo: 'Veterinario')
              .where('estado', isEqualTo: 'aceptado')
              .get();

      final List<Map<String, dynamic>> resultados = [];

      for (final vetDoc in veterinarioSnapshot.docs) {
        final clinicaSnapshot =
            await _firestore
                .collection('veterinarias')
                .where('veterinarioId', isEqualTo: vetDoc.id)
                .get();

        for (final clinicaDoc in clinicaSnapshot.docs) {
          resultados.add({
            'veterinario': {...vetDoc.data(), 'id': vetDoc.id},
            'clinica': {...clinicaDoc.data(), 'id': clinicaDoc.id},
          });
        }

        if (clinicaSnapshot.docs.isEmpty) {
          resultados.add({
            'veterinario': {...vetDoc.data(), 'id': vetDoc.id},
            'clinica': null,
          });
        }
      }

      setState(() {
        _veterinariosConClinica = resultados;
      });
    } catch (e) {
      print('Error cargando datos: $e');
    }
  }

  void _mostrarDetallesVeterinario(
    BuildContext context,
    Map<String, dynamic> veterinario,
    Map<String, dynamic>? clinica,
  ) {
    final nombre = veterinario['nombre'];
    final apellidos = veterinario['apellidos'] ?? '';
    final especialidad = veterinario['especialidad'] ?? 'No especificada';
    //final telefono = veterinario['telefono'] ?? 'No especificado';
    final email = veterinario['email'];
    final imagenUrl = veterinario['profileImageUrl'];
    final cedula = veterinario['cedulaProfesional'];
    final nomClinica =
        clinica?['nombre'] ?? 'Sin clínica asignada'; // Manejo de nulos

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
                  _buildInfoRow('Especialidad', especialidad),
                  _buildInfoRow('Email', email),
                  _buildInfoRow('Cedula Profesional', cedula),
                  _buildInfoRow('Clinica', nomClinica),
                  SizedBox(height: 20),
                ],
              ),
            ),
            actions: [
              // Botón + Opciones con menú desplegable
              if (clinica != null)
                PopupMenuButton<String>(
                  tooltip: '+ Opciones',
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [SizedBox(width: 4), Text('+ Opciones')],
                  ),
                  onSelected: (value) {
                    Navigator.pop(
                      context,
                    ); // Cierra el diálogo antes de navegar
                    if (value == 'ver_veterinaria') {
                      final clinicaSegura = <String, dynamic>{
                        'nombre': clinica['nombre']?.toString() ?? 'Sin nombre',
                        'direccion':
                            clinica['direccion']?.toString() ?? 'Sin dirección',
                        'telefono':
                            clinica['telefono']?.toString() ?? 'Sin teléfono',
                        'horarios': clinica['horarios'] ?? {},
                        'servicios': clinica['servicios'] ?? [],
                        'imagenUrl': clinica['imagenUrl']?.toString(),
                      };
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  ClinicDetailsScreen(clinica: clinicaSegura),
                        ),
                      );
                    } else if (value == 'agendar_cita') {
                      final vetConId = {
                        ...veterinario,
                        'id': veterinario['uid'] ?? veterinario['id'],
                      };
                      final clinicaConId =
                          clinica != null
                              ? {
                                ...clinica,
                                'id': clinica['uid'] ?? clinica['id'],
                              }
                              : null;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AgendarCitaScreen(
                                veterinario: vetConId,
                                clinica: clinicaConId,
                                userId: widget.user.uid,
                              ),
                        ),
                      );
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'ver_veterinaria',
                          child: Row(
                            children: [
                              Icon(Icons.location_city, color: Colors.black54),
                              SizedBox(width: 8),
                              Text('Ver veterinaria'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'agendar_cita',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.black54),
                              SizedBox(width: 8),
                              Text('Agendar cita'),
                            ],
                          ),
                        ),
                      ],
                ),

              // Botón Cerrar siempre visible
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
      appBar: buildCustomAppBar(context, 'Veterinarios disponibles'),
      body:
          _veterinariosConClinica.isEmpty
              ? FutureBuilder(
                future: _cargarVetsYClinicas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (_veterinariosConClinica.isEmpty) {
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
                  } else {
                    return _buildVeterinarioList();
                  }
                },
              )
              : _buildVeterinarioList(),
    );
  }

  Widget _buildVeterinarioList() {
    return ListView.builder(
      itemCount: _veterinariosConClinica.length,
      itemBuilder: (context, index) {
        final vetData = _veterinariosConClinica[index]['veterinario'];
        final nombre = vetData['nombre'];
        final apellidos = vetData['apellidos'] ?? '';
        final especialidad = vetData['especialidad'] ?? 'No especificada';
        final imagenUrl = vetData['profileImageUrl'];

        return Card(
          elevation: 7,
          shadowColor: Colors.greenAccent,
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: ListTile(
            leading:
                imagenUrl != null
                    ? CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(imagenUrl),
                      radius: 30,
                    )
                    : CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.medical_services),
                    ),
            title: Text(
              'Dr. $nombre $apellidos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(especialidad),
            trailing: Icon(Icons.chevron_right),
            onTap:
                () => _mostrarDetallesVeterinario(
                  context,
                  vetData,
                  _veterinariosConClinica[index]['clinica'],
                ),
          ),
        );
      },
    );
  }
}
