import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/series_provider.dart';
import '../../../services/localization_service.dart';
import '../widgets/media_gallery_dialog.dart';

/// Service for handling media gallery functionality in series detail screen
class MediaGalleryService {
  /// Show media gallery dialog (photos + videos) for a specific move.
  /// Completes when the dialog is dismissed.
  Future<void> showMediaGallery(
    BuildContext context,
    String category,
    String moveName,
  ) async {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;
    final galleryPath = provider.galleryPath;

    if (galleryPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate('gallery_path', lang)),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => MediaGalleryDialog(
        category: category,
        moveName: moveName,
        galleryPath: galleryPath,
      ),
    );
  }
}
