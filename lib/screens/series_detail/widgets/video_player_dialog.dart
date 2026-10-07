import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../services/localization_service.dart';
import '../../../services/series_provider.dart';

/// Full-screen instructional video player.
class VideoPlayerDialog extends StatefulWidget {
  final File videoFile;

  const VideoPlayerDialog({super.key, required this.videoFile});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.file(widget.videoFile);
    _controller = controller;
    try {
      await controller.initialize();
      controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _initialized = true);
      await controller.play();
    } catch (e) {
      debugPrint('VideoPlayerDialog init error: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          if (_failed)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  LocalizationService.translate('video_error', lang),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (!_initialized)
            const Center(child: CircularProgressIndicator())
          else
            Builder(
              builder: (context) {
                final controller = _controller!;
                return AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                );
              },
            ),
          // Controls overlay
          if (_initialized && !_failed)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: _buildControls(),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final controller = _controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          value: duration.inMilliseconds > 0
              ? position.inMilliseconds.toDouble()
              : 0,
          max: duration.inMilliseconds > 0
              ? duration.inMilliseconds.toDouble()
              : 1,
          activeColor: Colors.green,
          onChanged: (value) =>
              controller.seekTo(Duration(milliseconds: value.round())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(position),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () => controller.value.isPlaying
                  ? controller.pause()
                  : controller.play(),
            ),
            const SizedBox(width: 16),
            Text(
              _formatDuration(duration),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}
