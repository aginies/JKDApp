import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../utils/string_utils.dart';
import '../utils/category_utils.dart';

/// Thrown when a picked video exceeds [MediaService.maxVideoBytes].
class VideoTooLargeException implements Exception {
  final int sizeBytes;
  VideoTooLargeException(this.sizeBytes);
}

/// Thrown when no camera is available on the current platform.
class NoCameraAvailableException implements Exception {}

/// File extensions accepted as instructional photos.
const Set<String> kImageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.bmp',
  '.gif',
};

class MediaService {
  /// Soft limit for instructional videos (keeps backups reasonable).
  static const int maxVideoBytes = 200 * 1024 * 1024; // 200 MB

  final ImagePicker _picker = ImagePicker();

  Future<List<File>> getImagesForMove(
    String baseGalleryPath,
    String category,
    String moveName,
  ) async {
    final String categoryDir = CategoryUtils.getCategoryDirName(category);
    final String fullPath = p.join(baseGalleryPath, categoryDir);
    final Directory dir = Directory(fullPath);

    if (!await dir.exists()) return [];

    final String prefix = StringUtils.slugify(moveName);
    try {
      final List<FileSystemEntity> files = dir.listSync();
      return files
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith(prefix) &&
              kImageExtensions.contains(p.extension(f.path).toLowerCase()))
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
    // Desktop platforms (e.g. Linux) have no camera delegate and throw
    // when asked to capture. Convert that into a typed exception the UI
    // can surface as a snackbar.
    final XFile? photo;
    try {
      photo = await _picker.pickImage(source: ImageSource.camera);
    } catch (_) {
      throw NoCameraAvailableException();
    }
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
    final String categoryDir = CategoryUtils.getCategoryDirName(category);
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
    final String prefix = StringUtils.slugify(moveName);
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

  Future<bool> deleteImage(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// List instructional videos (`.mp4`) stored for a move.
  Future<List<File>> getVideosForMove(
    String baseGalleryPath,
    String category,
    String moveName,
  ) async {
    final String categoryDir = CategoryUtils.getCategoryDirName(category);
    final String fullPath = p.join(baseGalleryPath, categoryDir);
    final Directory dir = Directory(fullPath);

    if (!await dir.exists()) return [];

    final String prefix = StringUtils.slugify(moveName);
    try {
      final List<FileSystemEntity> files = dir.listSync();
      return files
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith(prefix) &&
              p.extension(f.path).toLowerCase() == '.mp4')
          .toList();
    } catch (e) {
      debugPrint('Error listing videos: $e');
      return [];
    }
  }

  /// Pick a video from the device gallery/files and store it for a move.
  ///
  /// Throws [VideoTooLargeException] when the picked file exceeds
  /// [maxVideoBytes]. Returns null when the user cancels.
  Future<File?> pickAndSaveVideo(
    String baseGalleryPath,
    String category,
    String moveName,
  ) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    final PlatformFile? picked = result?.files.first;
    final String? sourcePath = picked?.path;
    if (picked == null || sourcePath == null) return null;

    if (picked.size > maxVideoBytes) {
      throw VideoTooLargeException(picked.size);
    }

    final String categoryDir = CategoryUtils.getCategoryDirName(category);
    final String targetDirPath = p.join(baseGalleryPath, categoryDir);
    final Directory targetDir = Directory(targetDirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String prefix = StringUtils.slugify(moveName);
    final existing = await getVideosForMove(
      baseGalleryPath,
      category,
      moveName,
    );
    final int nextNum = existing.length + 1;
    final String fileName = '$prefix-$nextNum.mp4';
    final String finalPath = p.join(targetDirPath, fileName);

    final File source = File(sourcePath);
    final File savedFile = await source.copy(finalPath);
    return savedFile;
  }

  Future<bool> deleteVideo(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting video: $e');
      return false;
    }
  }
}
