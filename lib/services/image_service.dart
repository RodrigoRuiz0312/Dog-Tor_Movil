import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<File?> pickImage({bool fromCamera = false}) async {
    // Verificar y solicitar permisos
    if (fromCamera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return null;
    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted) return null;
    }

    final XFile? image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );

    return image != null ? File(image.path) : null;
  }

  Future<String?> uploadPetImage(File image, String userId, String petId) async {
    try {
      // Crear referencia única para la imagen
      final ref = _storage.ref()
          .child('pet_images')
          .child(userId)
          .child('$petId.jpg');
      
      // Subir el archivo
      await ref.putFile(image);
      
      // Obtener URL de descarga
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
}