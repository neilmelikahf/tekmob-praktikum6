import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo == null) return null; 
      return File(photo.path);
    } catch (e) {
      throw Exception('Gagal mengakses kamera: $e');
    }
  }

  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Gagal mengakses galeri: $e');
    }
  }
}
