import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class RegistrarMascotaScreen extends StatefulWidget {
  final User user;

  const RegistrarMascotaScreen({super.key, required this.user});

  @override
  _RegistrarMascotaScreenState createState() => _RegistrarMascotaScreenState();
}

class _RegistrarMascotaScreenState extends State<RegistrarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController especieController = TextEditingController();
  final TextEditingController razaController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController senasController = TextEditingController();

  Future<void> _pickImage(bool fromCamera) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final petId = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pet_images')
          .child(widget.user.uid)
          .child('$petId.jpg');

      await storageRef.putFile(_selectedImage!);
      _imageUrl = await storageRef.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> registrarMascota() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una imagen')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Subir imagen primero
      await _uploadImage();

      // Registrar mascota en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('mascotas')
          .add({
            'nombre': nombreController.text,
            'especie': especieController.text,
            'raza': razaController.text,
            'edad': int.tryParse(edadController.text) ?? 0,
            'imagenUrl': _imageUrl,
            'fechaRegistro': FieldValue.serverTimestamp(),
            'senas': senasController.text,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mascota registrada exitosamente")),
      );

      // Limpiar formulario
      _formKey.currentState!.reset();
      setState(() {
        _selectedImage = null;
        _imageUrl = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar mascota: ${e.toString()}")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Seleccionar imagen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(true);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Elegir de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(false);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrar Mascota"), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección de imagen
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      _selectedImage != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Agregar foto',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                ),
              ),
              SizedBox(height: 20),

              // Campo de nombre
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Campo de especie
              TextFormField(
                controller: especieController,
                decoration: InputDecoration(
                  labelText: 'Especie',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la especie';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Campo de raza
              TextFormField(
                controller: razaController,
                decoration: InputDecoration(
                  labelText: 'Raza',
                  prefixIcon: Icon(Icons.emoji_nature),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),

              // Campo de edad
              TextFormField(
                controller: edadController,
                decoration: InputDecoration(
                  labelText: 'Edad',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la edad';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Campo de edad
              TextFormField(
                controller: senasController,
                decoration: InputDecoration(
                  labelText: 'Señas particulares',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 30),

              // Botón de registro
              ElevatedButton(
                onPressed:
                    _isSubmitting || _isUploading ? null : registrarMascota,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isSubmitting || _isUploading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'REGISTRAR MASCOTA',
                          style: TextStyle(fontSize: 16),
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
    nombreController.dispose();
    especieController.dispose();
    razaController.dispose();
    edadController.dispose();
    senasController.dispose();
    super.dispose();
  }
}
