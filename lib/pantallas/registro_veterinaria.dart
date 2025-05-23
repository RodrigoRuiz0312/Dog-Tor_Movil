import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/appbar_diseño.dart';

class RegistrarVeterinariaScreen extends StatefulWidget {
  final User user;

  const RegistrarVeterinariaScreen({super.key, required this.user});

  @override
  State<RegistrarVeterinariaScreen> createState() =>
      _RegistrarVeterinariaScreenState();
}

class _RegistrarVeterinariaScreenState
    extends State<RegistrarVeterinariaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final Map<String, TextEditingController> _horariosControllers = {
    'lunes': TextEditingController(text: '9:00-18:00'),
    'martes': TextEditingController(text: '9:00-18:00'),
    'miércoles': TextEditingController(text: '9:00-18:00'),
    'jueves': TextEditingController(text: '9:00-18:00'),
    'viernes': TextEditingController(text: '9:00-18:00'),
    'sábado': TextEditingController(text: '9:00-14:00'),
    'domingo': TextEditingController(text: 'Cerrado'),
  };
  final List<String> _serviciosSeleccionados = ['Consulta'];
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
  bool _subiendo = false;

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
    if (_imagen == null) return null;

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
      return null;
    }
  }

  Future<void> _registrarVeterinaria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _subiendo = true);

    try {
      // Subir imagen primero si existe
      final imagenUrl = await _subirImagen();

      // Preparar datos de horarios
      final horarios = {};
      _horariosControllers.forEach((dia, controller) {
        horarios[dia] = controller.text;
      });

      // Crear documento de veterinaria
      final nuevaVeterinaria = {
        'nombre': _nombreController.text,
        'direccion': _direccionController.text,
        'telefono': _telefonoController.text,
        'servicios': _serviciosSeleccionados,
        'horarios': horarios,
        'imagenUrl': imagenUrl,
        'veterinarioId': widget.user.uid,
        'fechaRegistro': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('veterinarias')
          .add(nuevaVeterinaria);

      // Actualizar usuario para marcar que ya tiene veterinaria
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'tieneVeterinaria': true});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veterinaria registrada exitosamente!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    } finally {
      setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, 'Registrar mi veterinaria'),
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
                        _imagen != null ? FileImage(_imagen!) : null,
                    child:
                        _imagen == null
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

              // Botón de registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _subiendo ? null : _registrarVeterinaria,
                  child:
                      _subiendo
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Registrar Veterinaria',
                            style: TextStyle(fontSize: 16),
                          ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
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
