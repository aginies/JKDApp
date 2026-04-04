import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';

/// A visually appealing empty state illustration with stylized shapes and animations.
class EmptyStateIllustration extends StatelessWidget {
  final String titleKey;
  final String? subtitleKey;
  final IconData? icon;

  const EmptyStateIllustration({
    super.key,
    required this.titleKey,
    this.subtitleKey,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context);
    final themeColor = provider.themeColor;
    final lang = provider.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stylized Icon with shapes
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        themeColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Decorative shape 1
                Positioned(
                  top: 10,
                  right: 10,
                  child: _DecorativeCircle(
                    size: 20,
                    color: themeColor.withValues(alpha: 0.3),
                  ),
                ),
                // Decorative shape 2
                Positioned(
                  bottom: 20,
                  left: 15,
                  child: _DecorativeCircle(
                    size: 14,
                    color: themeColor.withValues(alpha: 0.2),
                  ),
                ),
                // Main Icon
                Icon(
                  icon ?? Icons.search_off_rounded,
                  size: 64,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationService.translate(titleKey, lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (subtitleKey != null) ...[
              const SizedBox(height: 8),
              Text(
                LocalizationService.translate(subtitleKey!, lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
