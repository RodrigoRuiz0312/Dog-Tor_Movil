import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:login/widgets/appbar_diseño.dart';

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
            'senas':
                senasController.text.isEmpty
                    ? 'No especificadas'
                    : senasController.text,
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildCustomAppBar(context, 'Registrar Mascota'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección de imagen con mejor diseño
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: Stack(
                    children: [
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      if (_selectedImage == null)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agregar foto de la mascota',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campo de nombre con mejor diseño
              _buildFormField(
                controller: nombreController,
                label: 'Nombre',
                icon: Icons.pets,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de especie
              _buildFormField(
                controller: especieController,
                label: 'Especie',
                icon: Icons.category,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la especie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de raza
              _buildFormField(
                controller: razaController,
                label: 'Raza',
                icon: Icons.emoji_nature,
              ),
              const SizedBox(height: 16),

              // Campo de edad
              _buildFormField(
                controller: edadController,
                label: 'Edad',
                icon: Icons.cake,
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
              const SizedBox(height: 16),

              // Campo de señas particulares
              _buildFormField(
                controller: senasController,
                label: 'Señas particulares',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Botón de registro mejorado
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting || _isUploading ? null : registrarMascota,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSubmitting || _isUploading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'REGISTRAR MASCOTA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
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
