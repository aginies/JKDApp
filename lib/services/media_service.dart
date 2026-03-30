import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<List<File>> getImagesForMove(
    String baseGalleryPath,
    String category,
    String moveName,
  ) async {
    final String categoryDir = _getCategoryDirName(category);
    final String fullPath = p.join(baseGalleryPath, categoryDir);
    final Directory dir = Directory(fullPath);

    if (!await dir.exists()) return [];

    final String prefix = _slugify(moveName);
    try {
      final List<FileSystemEntity> files = dir.listSync();
      return files
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith(prefix))
          .toList();
    } catch (e) {
      debugPrint('Error listing images: $e');
      return [];
    }
  }

  Future<File?> captureAndSaveImage(
    String baseGalleryPath,
    String category,
    String moveName,
  ) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return null;
    return _saveImage(photo, baseGalleryPath, category, moveName);
  }

  Future<File?> pickAndSaveImage(
    String baseGalleryPath,
    String category,
    String moveName,
  ) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return null;
    return _saveImage(photo, baseGalleryPath, category, moveName);
  }

  Future<File?> _saveImage(
    XFile photo,
    String baseGalleryPath,
    String category,
    String moveName,
  ) async {
    final String categoryDir = _getCategoryDirName(category);
    final String targetDirPath = p.join(baseGalleryPath, categoryDir);
    final Directory targetDir = Directory(targetDirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 1. Load image
    final bytes = await photo.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    // 2. Resize (width 500, maintain aspect ratio)
    img.Image resized = img.copyResize(image, width: 500);

    // 3. Generate Filename (move-name-ImageNumber.jpg)
    final String prefix = _slugify(moveName);
    final existing = await getImagesForMove(
      baseGalleryPath,
      category,
      moveName,
    );
    final int nextNum = existing.length + 1;
    final String fileName = '$prefix-$nextNum.jpg';
    final String finalPath = p.join(targetDirPath, fileName);

    // 4. Save as JPG 75%
    final List<int> jpg = img.encodeJpg(resized, quality: 75);
    final File savedFile = File(finalPath);
    await savedFile.writeAsBytes(jpg);

    return savedFile;
  }

  String _getCategoryDirName(String category) {
    // Capitalize first letter: punches -> Punches
    if (category.isEmpty) return 'Other';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
