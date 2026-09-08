import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/localization_service.dart';
import '../../../services/media_service.dart';
import '../../../services/series_provider.dart';
import 'full_screen_image_viewer.dart';
import 'video_player_dialog.dart';

/// Tabbed media gallery dialog for a move: instructional photos + videos.
class MediaGalleryDialog extends StatefulWidget {
  final String category;
  final String moveName;
  final String galleryPath;

  const MediaGalleryDialog({
    super.key,
    required this.category,
    required this.moveName,
    required this.galleryPath,
  });

  @override
  State<MediaGalleryDialog> createState() => _MediaGalleryDialogState();
}

class _MediaGalleryDialogState extends State<MediaGalleryDialog>
    with SingleTickerProviderStateMixin {
  final MediaService _mediaService = MediaService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _lang => Provider.of<SeriesProvider>(context, listen: false)
      .language;

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(widget.moveName)),
          if (_tabController.index == 0) ...[
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.green),
              tooltip: 'Select from files',
              onPressed: () async {
                final file = await _mediaService.pickAndSaveImage(
                  widget.galleryPath,
                  widget.category,
                  widget.moveName,
                );
                if (file != null && mounted) setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.add_a_photo,
                color: Colors.blueAccent,
              ),
              tooltip: LocalizationService.translate('capture_photo', lang),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final file = await _mediaService.captureAndSaveImage(
                    widget.galleryPath,
                    widget.category,
                    widget.moveName,
                  );
                  if (file != null && mounted) setState(() {});
                } on NoCameraAvailableException {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          LocalizationService.translate('no_camera', lang),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.green),
              tooltip: LocalizationService.translate('pick_video', lang),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final file = await _mediaService.pickAndSaveVideo(
                    widget.galleryPath,
                    widget.category,
                    widget.moveName,
                  );
                  if (file != null && mounted) setState(() {});
                } on VideoTooLargeException catch (_) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          LocalizationService.translate(
                            'video_too_large',
                            lang,
                          ),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.green,
            indicatorColor: Colors.green,
            tabs: [
              Tab(
                icon: const Icon(Icons.photo),
                text: LocalizationService.translate('photos_tab', lang),
              ),
              Tab(
                icon: const Icon(Icons.videocam),
                text: LocalizationService.translate('videos_tab', lang),
              ),
            ],
          ),
          SizedBox(
            width: double.maxFinite,
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _PhotosTab(
                  mediaService: _mediaService,
                  galleryPath: widget.galleryPath,
                  category: widget.category,
                  moveName: widget.moveName,
                  onChanged: () => setState(() {}),
                ),
                _VideosTab(
                  mediaService: _mediaService,
                  galleryPath: widget.galleryPath,
                  category: widget.category,
                  moveName: widget.moveName,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocalizationService.translate('finish', lang)),
        ),
      ],
    );
  }
}

/// Grid of instructional photos with delete support.
class _PhotosTab extends StatelessWidget {
  final MediaService mediaService;
  final String galleryPath;
  final String category;
  final String moveName;
  final VoidCallback onChanged;

  const _PhotosTab({
    required this.mediaService,
    required this.galleryPath,
    required this.category,
    required this.moveName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lang =
        Provider.of<SeriesProvider>(context, listen: false).language;
    return FutureBuilder<List<File>>(
      future: mediaService.getImagesForMove(
        galleryPath,
        category,
        moveName,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final images = snapshot.data ?? [];
        if (images.isEmpty) {
          return Center(
            child: Text(LocalizationService.translate('no_images', lang)),
          );
        }
        return GridView.builder(
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final imageFile = images[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => showFullScreenImage(context, images, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(imageFile, fit: BoxFit.cover),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _DeleteButton(
                    label: LocalizationService.translate(
                      'delete_image',
                      lang,
                    ),
                    message: LocalizationService.translate(
                      'delete_image_confirm',
                      lang,
                    ),
                    onDelete: () async {
                      final deleted = await mediaService.deleteImage(imageFile);
                      if (deleted) onChanged();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Grid of instructional videos with delete support.
class _VideosTab extends StatelessWidget {
  final MediaService mediaService;
  final String galleryPath;
  final String category;
  final String moveName;
  final VoidCallback onChanged;

  const _VideosTab({
    required this.mediaService,
    required this.galleryPath,
    required this.category,
    required this.moveName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lang =
        Provider.of<SeriesProvider>(context, listen: false).language;
    return FutureBuilder<List<File>>(
      future: mediaService.getVideosForMove(
        galleryPath,
        category,
        moveName,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final videos = snapshot.data ?? [];
        if (videos.isEmpty) {
          return Center(
            child: Text(LocalizationService.translate('no_videos', lang)),
          );
        }
        return GridView.builder(
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final videoFile = videos[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) =>
                          VideoPlayerDialog(videoFile: videoFile),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill,
                            size: 48,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _displayName(videoFile),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _DeleteButton(
                    label: LocalizationService.translate(
                      'delete_video',
                      lang,
                    ),
                    message: LocalizationService.translate(
                      'delete_video_confirm',
                      lang,
                    ),
                    onDelete: () async {
                      final deleted = await mediaService.deleteVideo(videoFile);
                      if (deleted) onChanged();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _displayName(File file) {
    final name = file.uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => file.path,
    );
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}

/// Small circular delete button with confirmation dialog.
class _DeleteButton extends StatelessWidget {
  final String label;
  final String message;
  final Future<void> Function() onDelete;

  const _DeleteButton({
    required this.label,
    required this.message,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lang =
        Provider.of<SeriesProvider>(context, listen: false).language;
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(label),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocalizationService.translate('cancel', lang)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  LocalizationService.translate('delete', lang),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await onDelete();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.remove,
          color: Colors.red,
          size: 16,
        ),
      ),
    );
  }
}
