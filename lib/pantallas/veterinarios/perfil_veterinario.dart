import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:login/services/auth_service.dart';
import 'package:login/widgets/appbar_diseño.dart';

class PerfilVeterinarioScreen extends StatefulWidget {
  final User user;

  const PerfilVeterinarioScreen({super.key, required this.user});

  @override
  State<PerfilVeterinarioScreen> createState() =>
      _PerfilVeterinarioScreenState();
}

class _PerfilVeterinarioScreenState extends State<PerfilVeterinarioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late String uid;
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isUploading = false;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _usernameController = TextEditingController();
  final _especialidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    uid = widget.user.uid;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _profileImageUrl = data['profileImageUrl'];
        _nombreController.text = data['nombre'] ?? '';
        _apellidosController.text = data['apellidos'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _especialidadController.text = data['especialidad'] ?? '';
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('users').doc(uid).update({
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'username': _usernameController.text.trim(),
        'especialidad': _especialidadController.text.trim(),
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    }
  }

  Future<void> _loadProfileImage() async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data()?.containsKey('profileImageUrl') == true) {
      setState(() {
        _profileImageUrl = doc['profileImageUrl'];
      });
    }
  }

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
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      // Eliminar la imagen anterior si existe
      if (_profileImageUrl != null) {
        await _deleteImage(_profileImageUrl!);
      }

      // Subir nueva imagen
      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child(uid)
          .child('profile.jpg');

      await storageRef.putFile(_selectedImage!);
      final newImageUrl = await storageRef.getDownloadURL();

      // Actualizar en Firestore
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': newImageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = newImageUrl;
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      // Eliminar de Storage
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      // Eliminar referencia en Firestore
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto de perfil eliminada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar imagen: $e')));
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Elegir de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(false);
                  },
                ),
                if (_profileImageUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Eliminar foto',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteImage(_profileImageUrl!);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text('Cancelar'),
                  onTap: () => Navigator.pop(context),
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
      appBar: buildCustomAppBar(context, 'Perfil'),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final correo = userData['email'] ?? 'No especificado';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Sección de foto de perfil
                _buildProfilePictureSection(),
                const SizedBox(height: 24),
                
                // Tarjeta con información del perfil
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField('Nombre', _nombreController, Icons.person),
                          const SizedBox(height: 12),
                          _buildField('Apellidos', _apellidosController, Icons.people),
                          const SizedBox(height: 12),
                          _buildInfoRow('Correo electrónico', correo, Icons.email),
                          const SizedBox(height: 12),
                          _buildField('Nombre de usuario', _usernameController, Icons.alternate_email),
                          const SizedBox(height: 12),
                          _buildField('Especialidad', _especialidadController, Icons.medical_services),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: theme.primaryColor,
                    ),
                    onPressed: _isEditing ? _saveProfileChanges : () {
                      setState(() => _isEditing = true);
                    },
                    child: Text(
                      _isEditing ? 'GUARDAR CAMBIOS' : 'EDITAR PERFIL',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.shade100,
              width: 4,
            ),
          ),
          child: GestureDetector(
            onTap: _isUploading ? null : _showImageOptions,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _profileImageUrl != null
                  ? CachedNetworkImageProvider(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null
                  ? const Icon(Icons.person, size: 70, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(70),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ),
        if (!_isUploading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: !_isEditing,
        fillColor: Colors.grey.shade100,
      ),
      style: const TextStyle(fontSize: 16),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              )),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ],
      ),
    );
  }
}