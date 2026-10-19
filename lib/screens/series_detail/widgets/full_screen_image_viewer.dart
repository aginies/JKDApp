import '../../../utils/platform_io.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Show full screen image viewer (page view when multiple images).
void showFullScreenImage(
  BuildContext context,
  List<File> images,
  int initialIndex,
) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setState) {
          int currentIndex = initialIndex;
          final PageController pageController = PageController(
            initialPage: initialIndex,
          );

          return Stack(
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      // Image.file needs a real dart:io File (native only);
                      // the viewer is unreachable on web anyway. The dynamic
                      // cast keeps the web stub File from clashing with
                      // Flutter's dart:io File parameter type.
                      child: kIsWeb
                          ? const Icon(
                              Icons.photo,
                              size: 48,
                              color: Colors.grey,
                            )
                          : Image.file(
                              images[index] as dynamic,
                              fit: BoxFit.contain,
                            ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} / ${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
