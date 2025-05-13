import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../widgets/appbar_diseño.dart';

class PerfilClienteScreen extends StatefulWidget {
  final User user;

  const PerfilClienteScreen({super.key, required this.user});

  @override
  State<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late String uid;
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    uid = widget.user.uid;
    _loadProfileImage();
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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Opciones de foto de perfil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
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
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, 'Perfil'),/* AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edicion de perfil en desarrollo'),
                ),
              );
            },
          ),
        ],
      ),*/
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('No se encontraron datos del usuario'),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final nombre = userData['nombre'] ?? 'No especificado';
          final apellidos = userData['apellidos'] ?? 'No especificado';
          final correo = userData['email'] ?? 'No especificado';
          final nombreUsuario = userData['username'] ?? 'No especificado';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto de perfil con opción de cambiarla
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _showImageOptions,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue[100],
                        backgroundImage:
                            _profileImageUrl != null
                                ? CachedNetworkImageProvider(_profileImageUrl!)
                                : null,
                        child:
                            _profileImageUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blue,
                                )
                                : null,
                      ),
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(60),
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
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isUploading
                      ? 'Subiendo imagen...'
                      : 'Toca para cambiar foto',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Tarjeta con la información del usuario
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow('Nombre', nombre),
                        const Divider(),
                        _buildInfoRow('Apellidos', apellidos),
                        const Divider(),
                        _buildInfoRow('Correo electrónico', correo),
                        const Divider(),
                        _buildInfoRow('Nombre de usuario', nombreUsuario),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Botón para editar perfil
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad de edición en desarrollo'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Editar Perfil'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
