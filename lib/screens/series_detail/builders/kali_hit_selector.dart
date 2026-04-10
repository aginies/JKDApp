import 'package:flutter/material.dart';
import '../widgets/kali_angle_icon.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Angles Kali',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6, // 2 rows of 6 instead of 4
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final angle = index + 1;
            final isSelected = selectedAngle == angle;
            return InkWell(
              onTap: () => onAngleSelected(angle),
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
                      size: 40, // Increased from 32
                      color: isSelected ? Colors.brown : Colors.grey.shade600,
                      showCircle: false, // More compact
                    ),
                    Text(
                      '$angle',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.brown : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Text(
                'Frappe:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
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
                          label: Text(type, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) onStrikeTypeSelected(type);
                          },
                          selectedColor: Colors.brown.withValues(alpha: 0.2),
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
  }
}
