import 'package:flutter/material.dart';

class DiagonalCross extends StatelessWidget {
  final Widget child;
  final bool show;
  final Color color;

  const DiagonalCross({
    super.key,
    required this.child,
    required this.show,
    this.color = Colors.purple,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: DiagonalCrossPainter(color: color)),
          ),
        ),
      ],
    );
  }
}

class DiagonalCrossPainter extends CustomPainter {
  final Color color;

  DiagonalCrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
