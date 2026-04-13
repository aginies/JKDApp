import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/kali_angle_icon.dart';
import '../../../services/series_provider.dart';
import '../../../models/custom_kali_angle.dart';

class KaliHitSelector extends StatelessWidget {
  final int? selectedAngle;
  final String? selectedStrikeType;
  final Function(int angle) onAngleSelected;
  final Function(String strikeType) onStrikeTypeSelected;

  const KaliHitSelector({
    super.key,
    required this.selectedAngle,
    required this.selectedStrikeType,
    required this.onAngleSelected,
    required this.onStrikeTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SeriesProvider>(
      builder: (context, provider, child) {
        final customAngles = provider.customAngles;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Angles Kali',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.brown,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: 15,
              itemBuilder: (context, index) {
                final angle = index + 1;
                final isSelected = selectedAngle == angle;
                return _buildAngleItem(context, angle, isSelected, '$angle');
              },
            ),
            if (customAngles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Custom Angles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.brown,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1,
                ),
                itemCount: customAngles.length,
                itemBuilder: (context, index) {
                  final custom = customAngles[index];
                  final isSelected = selectedAngle == custom.id;
                  return _buildAngleItem(
                    context,
                    custom.id,
                    isSelected,
                    custom.name,
                    isCustom: true,
                    onDelete: () => _confirmDelete(context, provider, custom),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            // ... (Frappe selection remains the same)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Frappe:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Lobtik', 'Witik', 'Saksak'].map((type) {
                          final isSelected = selectedStrikeType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: ChoiceChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                type,
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) onStrikeTypeSelected(type);
                              },
                              selectedColor: Colors.brown.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAngleItem(
    BuildContext context,
    int angle,
    bool isSelected,
    String label, {
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: () => onAngleSelected(angle),
      onLongPress: isCustom ? onDelete : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.brown.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.brown : Colors.grey.shade300,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KaliAngleIcon(
              angle: angle,
              size: 40,
              color: isSelected ? Colors.brown : Colors.grey.shade600,
              showCircle: false,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.brown : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SeriesProvider provider,
    CustomKaliAngle custom,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Angle?'),
        content: Text('Delete "${custom.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteCustomAngle(custom.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
