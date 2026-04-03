import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';
import 'move_display_widgets.dart';

class BuilderHelpContent extends StatelessWidget {
  final String lang;
  const BuilderHelpContent({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STRUCTURE (now at the top)
          _buildSectionTitle(
            theme,
            LocalizationService.translate('help_structure', lang),
          ),
          _buildStructureDesc(
            'CHAIN',
            LocalizationService.translate('help_chain_desc', lang),
          ),
          _buildStructureDesc(
            'SIMULTANEOUS',
            LocalizationService.translate('help_simultaneous_long_desc', lang),
          ),
          _buildStructureDesc(
            'ANSWER',
            LocalizationService.translate('help_answer_long_desc', lang),
          ),

          const SizedBox(height: 24),

          // CONTROLS
          _buildSectionTitle(
            theme,
            LocalizationService.translate('help_controls', lang),
          ),
          _buildActionRow(
            context,
            icon: Icons.add,
            color: Colors.blue,
            label: LocalizationService.translate('help_start_next', lang),
            desc: LocalizationService.translate('help_start_next_desc', lang),
          ),
          _buildActionRow(
            context,
            color: Colors.blueAccent,
            label: 'A + B',
            desc: LocalizationService.translate('help_simultaneous_desc', lang),
            customChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Colors.blueAccent,
                ),
                const Text(
                  'B',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          _buildActionRow(
            context,
            color: Colors.teal,
            label: 'A -> B',
            desc: LocalizationService.translate('help_sequence_desc', lang),
            customChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.teal),
                const Icon(Icons.add, size: 14, color: Colors.teal),
              ],
            ),
          ),
          _buildActionRow(
            context,
            icon: Icons.subdirectory_arrow_right,
            color: Colors.orange,
            label: LocalizationService.translate('answer', lang),
            desc: LocalizationService.translate('help_answer_desc', lang),
          ),
          _buildActionRow(
            context,
            icon: Icons.check,
            color: Colors.green,
            label: LocalizationService.translate('finish', lang),
            desc: LocalizationService.translate('help_finish_desc', lang),
          ),
          _buildActionRow(
            context,
            icon: Icons.close,
            color: Colors.red,
            label: LocalizationService.translate('cancel', lang),
            desc: LocalizationService.translate('help_cancel_desc', lang),
          ),

          const SizedBox(height: 24),

          // ACTIONS OPTIONS (renamed from Card Options)
          _buildSectionTitle(
            theme,
            LocalizationService.translate('help_actions_options', lang),
          ),

          _buildOptionRow(
            context,
            widget: MoveDisplayWidgets.sideCircle('L', 'L', mini: true),
            label: LocalizationService.translate('left', lang),
          ),
          _buildOptionRow(
            context,
            widget: MoveDisplayWidgets.sideCircle('R', 'R', mini: true),
            label: LocalizationService.translate('right', lang),
          ),
          _buildOptionRow(
            context,
            widget: MoveDisplayWidgets.sideCircle('M', 'M', mini: true),
            label: LocalizationService.translate('mid', lang),
          ),
          const Divider(),
          _buildOptionRow(
            context,
            widget: MoveDisplayWidgets.levelIcon('High', mini: true),
            label: LocalizationService.translate('high', lang),
          ),
          _buildOptionRow(
            context,
            widget: MoveDisplayWidgets.levelIcon('Mid', mini: true),
            label: LocalizationService.translate('mid', lang),
          ),
          _buildOptionRow(
            context,
            widget: MoveDisplayWidgets.levelIcon('Low', mini: true),
            label: LocalizationService.translate('low', lang),
          ),
          const Divider(),
          _buildOptionRow(
            context,
            widget: MoveDisplayWidgets.drawBox(mini: true),
            label: LocalizationService.translate('draw', lang),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    IconData? icon,
    required Color color,
    required String label,
    required String desc,
    Widget? customChild,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double bgAlpha = isDark ? 0.3 : 0.1;
    final Color fgColor = isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.7), Colors.white)
        : color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: bgAlpha),
              borderRadius: BorderRadius.circular(8),
              border: isDark
                  ? Border.all(color: color.withValues(alpha: 0.4))
                  : null,
            ),
            child: Center(
              child:
                  customChild ??
                  (icon != null
                      ? Icon(icon, size: 20, color: fgColor)
                      : Text(
                          label,
                          style: TextStyle(
                            color: fgColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(
    BuildContext context, {
    required Widget widget,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Center(child: widget)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStructureDesc(String tag, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.grey, fontSize: 13),
          children: [
            TextSpan(
              text: '$tag: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            TextSpan(text: desc),
          ],
        ),
      ),
    );
  }
}
