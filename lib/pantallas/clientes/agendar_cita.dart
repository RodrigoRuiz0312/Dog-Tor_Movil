import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/widgets/appbar_diseño.dart';

class AgendarCitaScreen extends StatefulWidget {
  final Map<String, dynamic> veterinario;
  final Map<String, dynamic>? clinica;
  final String userId;

  const AgendarCitaScreen({
    super.key,
    required this.veterinario,
    required this.clinica,
    required this.userId,
  });

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _mascotas = [];
  Map<String, dynamic>? _mascotaSeleccionada;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarMascotas();
  }

  Future<void> _cargarMascotas() async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('mascotas')
            .get();

    setState(() {
      _mascotas =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  Future<void> _agendarCita() async {
    if (_mascotaSeleccionada == null ||
        _fechaSeleccionada == null ||
        _horaSeleccionada == null ||
        _motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Completa todos los campos')));
      return;
    }

    final DateTime fechaCompleta = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    try {
      await _firestore.collection('citas').add({
        'mascotaId': _mascotaSeleccionada!['id'],
        'clienteId': widget.userId,
        'veterinarioId': widget.veterinario['id'],
        'veterinariaId': widget.clinica?['id'],
        'fecha': Timestamp.fromDate(fechaCompleta),
        'hora': _horaSeleccionada!.format(context),
        'motivo': _motivoController.text.trim(),
        'estado': 'pendiente',
        'notas':
            _notasController.text.trim().isEmpty
                ? 'No especificadas'
                : _notasController.text.trim(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cita agendada correctamente')));
      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar cita: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al agendar la cita')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreVet =
        widget.veterinario['nombre'] +
        ' ' +
        (widget.veterinario['apellidos'] ?? '');
    final nombreClinica = widget.clinica?['nombre'] ?? 'Sin clínica';

    return Scaffold(
      appBar: buildCustomAppBar(context, 'Agendar cita'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _mascotas.isEmpty
                ? Center(child: Text('No tienes mascotas registradas'))
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        margin: EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: Icon(Icons.person, color: Colors.teal),
                                title: Text(
                                  'Veterinario: $nombreVet',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.local_hospital,
                                  color: Colors.teal,
                                ),
                                title: Text('Clínica: $nombreClinica'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecciona una mascota:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              DropdownButton<Map<String, dynamic>>(
                                value: _mascotaSeleccionada,
                                hint: Text('Elige una mascota'),
                                isExpanded: true,
                                items:
                                    _mascotas.map((mascota) {
                                      return DropdownMenuItem(
                                        value: mascota,
                                        child: Text(mascota['nombre']),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _mascotaSeleccionada = value;
                                  });
                                },
                              ),
                              SizedBox(height: 16),
                              TextField(
                                controller: _motivoController,
                                decoration: InputDecoration(
                                  labelText: 'Motivo de la cita',
                                  prefixIcon: Icon(Icons.edit_note_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                maxLines: 2,
                              ),
                              SizedBox(height: 16),
                              TextField(
                                controller: _notasController,
                                decoration: InputDecoration(
                                  labelText: 'Notas adicionales',
                                  hintText: 'Opcional',
                                  prefixIcon: Icon(Icons.notes),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              SizedBox(height: 16),
                              ListTile(
                                title: Text(
                                  _fechaSeleccionada == null
                                      ? 'Seleccionar fecha'
                                      : 'Fecha: ${_fechaSeleccionada!.toLocal().toString().split(' ')[0]}',
                                ),
                                leading: Icon(
                                  Icons.calendar_today,
                                  color: Colors.teal,
                                ),
                                onTap: _seleccionarFecha,
                              ),
                              ListTile(
                                title: Text(
                                  _horaSeleccionada == null
                                      ? 'Seleccionar hora'
                                      : 'Hora: ${_horaSeleccionada!.format(context)}',
                                ),
                                leading: Icon(
                                  Icons.access_time,
                                  color: Colors.teal,
                                ),
                                onTap: _seleccionarHora,
                              ),
                              SizedBox(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.teal,
                                  ),
                                  onPressed: _agendarCita,
                                  icon: Icon(Icons.calendar_today_outlined),
                                  label: Text('Agendar cita'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
