import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      // Verificar y solicitar permisos con más control
      PermissionStatus status;
      if (fromCamera) {
        status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
          if (status.isDenied || status.isPermanentlyDenied) {
            return null;
          }
        }

        // En algunos dispositivos necesitamos también el almacenamiento para guardar la foto tomada
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (status.isDenied || status.isPermanentlyDenied) {
            return null;
          }
        }
      } else {
        status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
          if (status.isDenied || status.isPermanentlyDenied) {
            // Si es negado permanentemente, guiamos al usuario a ajustes
            if (status.isPermanentlyDenied) {
              await openAppSettings();
            }
            return null;
          }
        }
      }

      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      print('Error en pickImage: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImage(File image, String userId) async {
    try {
      // Crear referencia única para la imagen de perfil
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('profile.jpg'); // Siempre el mismo nombre para sobrescribir

      // Subir el archivo
      await ref.putFile(image);

      // Obtener URL de descarga
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen de perfil: $e');
      return null;
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('profile.jpg');

      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen de perfil: $e');
    }
  }

  Future<String?> uploadPetImage(
    File image,
    String userId,
    String petId,
  ) async {
    try {
      // Crear referencia única para la imagen
      final ref = _storage
          .ref()
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
