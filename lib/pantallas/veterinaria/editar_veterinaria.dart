import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:login/widgets/appbar_diseño.dart';

class EditarVeterinariaScreen extends StatefulWidget {
  final User user;

  const EditarVeterinariaScreen({super.key, required this.user});

  @override
  State<EditarVeterinariaScreen> createState() =>
      _EditarVeterinariaScreenState();
}

class _EditarVeterinariaScreenState extends State<EditarVeterinariaScreen> {
  final _formKey = GlobalKey<FormState>();
  late DocumentReference _veterinariaRef;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final Map<String, TextEditingController> _horariosControllers = {};
  final List<String> _serviciosSeleccionados = [];
  final List<String> _opcionesServicios = [
    'Consulta',
    'Vacunación',
    'Cirugía',
    'Peluquería',
    'Hospitalización',
    'Laboratorio',
    'Rayos X',
  ];

  File? _imagen;
  String? _imagenUrlActual;
  bool _cargando = true;
  bool _subiendo = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosVeterinaria();
  }

  Future<void> _cargarDatosVeterinaria() async {
    try {
      // Obtener referencia a la veterinaria del usuario
      final query =
          await FirebaseFirestore.instance
              .collection('veterinarias')
              .where('veterinarioId', isEqualTo: widget.user.uid)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        Navigator.pop(context);
        return;
      }

      _veterinariaRef = query.docs.first.reference;
      final data = query.docs.first.data();

      // Cargar datos en los controllers
      _nombreController.text = data['nombre'];
      _direccionController.text = data['direccion'];
      _telefonoController.text = data['telefono'];
      _serviciosSeleccionados.addAll(List<String>.from(data['servicios']));
      _imagenUrlActual = data['imagenUrl'];

      // Inicializar controllers de horarios
      final horarios = data['horarios'] as Map<String, dynamic>;
      horarios.forEach((dia, valor) {
        _horariosControllers[dia] = TextEditingController(text: valor);
      });

      setState(() => _cargando = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      Navigator.pop(context);
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagen = File(pickedFile.path);
      });
    }
  }

  Future<String?> _subirImagen() async {
    if (_imagen == null) return _imagenUrlActual;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('veterinarias')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(_imagen!);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return _imagenUrlActual;
    }
  }

  Future<void> _actualizarVeterinaria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _subiendo = true);

    try {
      // Subir imagen si hay una nueva
      final imagenUrl = await _subirImagen();

      // Preparar datos de horarios
      final horarios = {};
      _horariosControllers.forEach((dia, controller) {
        horarios[dia] = controller.text;
      });

      // Actualizar documento
      await _veterinariaRef.update({
        'nombre': _nombreController.text,
        'direccion': _direccionController.text,
        'telefono': _telefonoController.text,
        'servicios': _serviciosSeleccionados,
        'horarios': horarios,
        'imagenUrl': imagenUrl,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos actualizados exitosamente!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    } finally {
      setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: buildCustomAppBar(context, 'Editar veterinaria'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: buildCustomAppBar(context, 'Editar veterinaria'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo de imagen
              Center(
                child: GestureDetector(
                  onTap: _seleccionarImagen,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        _imagen != null
                            ? FileImage(_imagen!)
                            : (_imagenUrlActual != null
                                ? NetworkImage(_imagenUrlActual!)
                                : null),
                    child:
                        _imagen == null && _imagenUrlActual == null
                            ? Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Veterinaria',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 16),

              // Servicios
              Text('Servicios ofrecidos:', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 8,
                children:
                    _opcionesServicios.map((servicio) {
                      final estaSeleccionado = _serviciosSeleccionados.contains(
                        servicio,
                      );
                      return FilterChip(
                        label: Text(servicio),
                        selected: estaSeleccionado,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _serviciosSeleccionados.add(servicio);
                            } else {
                              _serviciosSeleccionados.remove(servicio);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),

              // Horarios
              Text('Horarios de atención:', style: TextStyle(fontSize: 16)),
              ..._horariosControllers.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 100, child: Text(entry.key)),
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 24),

              // Botón de actualización
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _subiendo ? null : _actualizarVeterinaria,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child:
                      _subiendo
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Guardar Cambios',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _horariosControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
