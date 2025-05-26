import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../clientes/listar_veterinarios.dart';
import 'package:login/widgets/appbar_diseño.dart';

class PanelCitas extends StatefulWidget {
  final User user;

  const PanelCitas({super.key, required this.user});

  @override
  State<PanelCitas> createState() => _PanelCitasState();
}

class _PanelCitasState extends State<PanelCitas> {
  late Stream<QuerySnapshot> _citasStream;

  @override
  void initState() {
    super.initState();
    _citasStream =
        FirebaseFirestore.instance
            .collection('citas')
            .where('clienteId', isEqualTo: widget.user.uid)
            .orderBy('fecha', descending: false)
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: buildCustomAppBar(context, 'Citas Médicas'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _citasStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No tienes citas registradas."),
                    );
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user.uid)
                            .collection('mascotas')
                            .get(),
                    builder: (context, snapshotMascotas) {
                      if (snapshotMascotas.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshotMascotas.hasData ||
                          snapshotMascotas.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No se encontraron mascotas.'),
                        );
                      }

                      // Forzar tipos a Map<String, String>
                      final Map<String, String> mascotasMap = {
                        for (var doc in snapshotMascotas.data!.docs)
                          doc.id: (doc['nombre'] ?? 'Mascota').toString(),
                      };

                      final citasDocs = snapshot.data!.docs;

                      final citasFuturas =
                          citasDocs.where((doc) {
                            final fecha = (doc['fecha'] as Timestamp).toDate();
                            return fecha.isAfter(now);
                          }).toList();

                      final citasPasadas =
                          citasDocs.where((doc) {
                            final fecha = (doc['fecha'] as Timestamp).toDate();
                            return fecha.isBefore(now);
                          }).toList();

                      return ListView(
                        children: [
                          ExpansionTile(
                            title: const Text('Próximas citas'),
                            initiallyExpanded: true,
                            children:
                                citasFuturas
                                    .map(
                                      (cita) =>
                                          _buildCitaCard(cita, mascotasMap),
                                    )
                                    .toList(),
                          ),
                          ExpansionTile(
                            title: const Text('Citas pasadas'),
                            children:
                                citasPasadas
                                    .map(
                                      (cita) =>
                                          _buildCitaCard(cita, mascotasMap),
                                    )
                                    .toList(),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListaVeterinariosScreen(user: widget.user),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Agendar nueva cita"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitaCard(
    QueryDocumentSnapshot cita,
    Map<String, String> mascotasMap,
  ) {
    final fecha = (cita['fecha'] as Timestamp).toDate();
    final motivo = cita['motivo'] ?? 'Sin motivo';
    final hora = cita['hora'] ?? '';
    final mascotaId = cita['mascotaId'];
    final nombreMascota = mascotasMap[mascotaId] ?? 'Desconocida';

    final estado = cita['estado'] ?? 'pendiente';
    String estadoTexto;

    switch (estado) {
      case 'confirmada':
        estadoTexto = 'Confirmada';
        break;
      case 'rechazada':
        estadoTexto = 'Rechazada';
        break;
      case 'reagendada':
        estadoTexto = 'Reagendada';
        break;
      default:
        estadoTexto = 'Pendiente de confirmación';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: ListTile(
        title: Text('Paciente: $nombreMascota'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motivo: $motivo'),
            Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
            if (hora.isNotEmpty) Text('Hora: $hora'),
            Text('Estado: $estadoTexto'),
          ],
        ),
      ),
    );
  }
}
