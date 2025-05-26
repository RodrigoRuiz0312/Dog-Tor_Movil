import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login/widgets/appbar_diseño.dart';

class CitasProgramadasScreen extends StatefulWidget {
  final User user;

  const CitasProgramadasScreen({super.key, required this.user});

  @override
  State<CitasProgramadasScreen> createState() => _CitasProgramadasScreenState();
}

class _CitasProgramadasScreenState extends State<CitasProgramadasScreen> {
  late Future<List<Map<String, dynamic>>> _citasFuturas;

  @override
  void initState() {
    super.initState();
    _citasFuturas = obtenerCitasConDetalles();
  }

  Future<List<Map<String, dynamic>>> obtenerCitasConDetalles() async {
    final firestore = FirebaseFirestore.instance;
    final citasSnapshot =
        await firestore
            .collection('citas')
            .where('veterinarioId', isEqualTo: widget.user.uid)
            .where('estado', isEqualTo: 'pendiente')
            .orderBy('fecha')
            .get();

    List<Map<String, dynamic>> citasConDetalles = [];

    for (var citaDoc in citasSnapshot.docs) {
      final cita = citaDoc.data();
      final clienteId = cita['clienteId'];
      final mascotaId = cita['mascotaId'];

      final clienteDoc =
          await firestore.collection('users').doc(clienteId).get();
      final mascotaDoc =
          await firestore
              .collection('users')
              .doc(clienteId)
              .collection('mascotas')
              .doc(mascotaId)
              .get();

      final Timestamp timestamp = cita['fecha'];
      final DateTime fechaDateTime = timestamp.toDate();
      final String fechaFormateada = DateFormat(
        'dd/MM/yyyy',
      ).format(fechaDateTime);

      citasConDetalles.add({
        'id': citaDoc.id,
        'mascota': mascotaDoc.data()?['nombre'] ?? 'Mascota desconocida',
        'duenio': clienteDoc.data()?['nombre'] ?? 'Dueño desconocido',
        'duenioApellido':
            clienteDoc.data()?['apellidos'] ?? 'Dueño desconocido',
        'fecha': fechaFormateada,
        'fechaDateTime': fechaDateTime,
        'hora': cita['hora'],
        'motivo': cita['motivo'],
        'notas': cita['notas'],
      });
    }

    return citasConDetalles;
  }

  Future<void> actualizarEstadoCita(
    String citaId,
    String nuevoEstado, {
    DateTime? nuevaFecha,
  }) async {
    final Map<String, dynamic> data = {'estado': nuevoEstado};
    if (nuevaFecha != null) {
      data['fecha'] = Timestamp.fromDate(nuevaFecha);
    }

    await FirebaseFirestore.instance
        .collection('citas')
        .doc(citaId)
        .update(data);
  }

  Future<void> mostrarDialogoReagendar(
    BuildContext context,
    String citaId,
    DateTime fechaActual,
  ) async {
    DateTime? nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaActual,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (nuevaFecha != null) {
      TimeOfDay? nuevaHora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaActual),
      );

      if (nuevaHora != null) {
        final nuevaFechaHora = DateTime(
          nuevaFecha.year,
          nuevaFecha.month,
          nuevaFecha.day,
          nuevaHora.hour,
          nuevaHora.minute,
        );

        final nuevaHoraTexto = nuevaHora.format(context);

        await FirebaseFirestore.instance
            .collection('citas')
            .doc(citaId)
            .update({
              'estado': 'reagendada',
              'fecha': Timestamp.fromDate(nuevaFechaHora),
              'hora': nuevaHoraTexto,
            });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cita reagendada.')));

        setState(() {
          _citasFuturas = obtenerCitasConDetalles();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, 'Citas pendientes'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _citasFuturas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay citas programadas.'));
          }

          final citas = snapshot.data!;
          return ListView.builder(
            itemCount: citas.length,
            itemBuilder: (context, index) {
              final cita = citas[index];
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paciente: ${cita['mascota']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Dueño: ${cita['duenio']} ${cita['duenioApellido']}',
                      ),
                      Text('Fecha: ${cita['fecha']}'),
                      Text('Hora: ${cita['hora']}'),
                      Text('Motivo: ${cita['motivo']}'),
                      if (cita['notas'] != null &&
                          cita['notas'].toString().isNotEmpty)
                        Text('Notas: ${cita['notas']}'),
                      const SizedBox(height: 8),
                      ButtonBar(
                        alignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await actualizarEstadoCita(
                                cita['id'],
                                'confirmada',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cita confirmada.'),
                                ),
                              );
                              setState(() {
                                _citasFuturas = obtenerCitasConDetalles();
                              });
                            },
                            child: const Text('Confirmar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await actualizarEstadoCita(
                                cita['id'],
                                'rechazada',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cita rechazada.'),
                                ),
                              );
                              setState(() {
                                _citasFuturas = obtenerCitasConDetalles();
                              });
                            },
                            child: const Text('Rechazar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await mostrarDialogoReagendar(
                                context,
                                cita['id'],
                                cita['fechaDateTime'],
                              );
                            },
                            child: const Text('Reagendar'),
                          ),
                        ],
                      ),
                    ],
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
