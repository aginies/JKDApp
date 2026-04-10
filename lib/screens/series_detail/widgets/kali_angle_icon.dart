import 'dart:math' as math;
import 'package:flutter/material.dart';

class KaliAngleIcon extends StatelessWidget {
  final int angle;
  final double size;
  final Color color;
  final bool showCircle;

  const KaliAngleIcon({
    super.key,
    required this.angle,
    this.size = 40, // Increased from 32
    this.color = Colors.brown,
    this.showCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KaliAnglePainter(
          angle: angle,
          color: color,
          showCircle: showCircle,
        ),
      ),
    );
  }
}

class _KaliAnglePainter extends CustomPainter {
  final int angle;
  final Color color;
  final bool showCircle;

  _KaliAnglePainter({
    required this.angle,
    required this.color,
    required this.showCircle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.15 // Increased stroke width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (showCircle) {
      final circlePaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, circlePaint);
      
      final borderPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius, borderPaint);
    }

    switch (angle) {
      case 1: // Diagonal Down (Forehand) -> Arrow Down
        _drawArrow(canvas, center, radius, 225, 45, paint);
        break;
      case 2: // Diagonal Down (Backhand) -> Arrow Down
        _drawArrow(canvas, center, radius, 315, 135, paint);
        break;
      case 3: // Horizontal Right -> Arrow Right
        _drawArrow(canvas, center, radius, 180, 0, paint);
        break;
      case 4: // Horizontal Left -> Arrow Left
        _drawArrow(canvas, center, radius, 0, 180, paint);
        break;
      case 5: // Straight Thrust (Center)
        canvas.drawCircle(center, size.width * 0.15, paint..style = PaintingStyle.fill);
        break;
      case 6: // Straight to Opposite Shoulder with Curve
        _drawCurveThrust(canvas, center, radius, true, paint);
        break;
      case 7: // Straight to Opposite Shoulder with Curve
        _drawCurveThrust(canvas, center, radius, false, paint);
        break;
      case 8: // Was Thrust HR, now Vertical Down
        _drawArrow(canvas, center, radius, 270, 90, paint);
        break;
      case 9: // Was Vertical Down, now Uppercut Left
        _drawCurveWithArrow(canvas, center, radius, false, paint);
        break;
      case 10: // Was Thrust HL, now Thrust High Right
        _drawArrow(canvas, center, radius, 330, 150, paint);
        break;
      case 11: // Was Thrust HR, now Thrust High Left
        _drawArrow(canvas, center, radius, 210, 30, paint);
        break;
      case 12: // Was Vertical Down, now Uppercut Right
        _drawCurveWithArrow(canvas, center, radius, true, paint);
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset center, double radius, double startAngleDeg, double endAngleDeg, Paint paint) {
    final startRad = startAngleDeg * math.pi / 180;
    final endRad = endAngleDeg * math.pi / 180;
    
    final p1 = Offset(
      center.dx + radius * 0.95 * math.cos(startRad),
      center.dy + radius * 0.95 * math.sin(startRad),
    );
    final p2 = Offset(
      center.dx + radius * 0.95 * math.cos(endRad),
      center.dy + radius * 0.95 * math.sin(endRad),
    );
    
    canvas.drawLine(p1, p2, paint);
    _drawArrowHead(canvas, p1, p2, paint);
  }

  void _drawCurveThrust(Canvas canvas, Offset center, double radius, bool isLeftHand, Paint paint) {
    // Add a small curve before the straight thrust line
    final path = Path();
    if (isLeftHand) {
      // From Left hand to Opponent Left Shoulder (Top Right)
      final start = Offset(center.dx - radius * 0.8, center.dy + radius * 0.6);
      final mid = Offset(center.dx - radius * 1.0, center.dy + radius * 0.1);
      final end = Offset(center.dx + radius * 0.7, center.dy - radius * 0.7);
      
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(mid.dx, mid.dy, center.dx - radius * 0.2, center.dy + radius * 0.1);
      path.lineTo(end.dx, end.dy);
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, Offset(center.dx - radius * 0.2, center.dy + radius * 0.1), end, paint);
    } else {
      // From Right hand to Opponent Right Shoulder (Top Left)
      final start = Offset(center.dx + radius * 0.8, center.dy + radius * 0.6);
      final mid = Offset(center.dx + radius * 1.0, center.dy + radius * 0.1);
      final end = Offset(center.dx - radius * 0.7, center.dy - radius * 0.7);
      
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(mid.dx, mid.dy, center.dx + radius * 0.2, center.dy + radius * 0.1);
      path.lineTo(end.dx, end.dy);
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, Offset(center.dx + radius * 0.2, center.dy + radius * 0.1), end, paint);
    }
  }

  void _drawCurveWithArrow(Canvas canvas, Offset center, double radius, bool isRight, Paint paint) {
    final path = Path();
    Offset p1, p2, ctrl;
    
    if (isRight) {
      // Uppercut from middle left to upper right
      p1 = Offset(center.dx - radius * 0.9, center.dy + radius * 0.2);
      ctrl = Offset(center.dx - radius * 0.2, center.dy + radius * 1.0);
      p2 = Offset(center.dx + radius * 0.9, center.dy - radius * 0.9);
    } else {
      // Uppercut from middle right to upper left
      p1 = Offset(center.dx + radius * 0.9, center.dy + radius * 0.2);
      ctrl = Offset(center.dx + radius * 0.2, center.dy + radius * 1.0);
      p2 = Offset(center.dx - radius * 0.9, center.dy - radius * 0.9);
    }
    
    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
    canvas.drawPath(path, paint);
    
    // For arrowhead on curve, use tangent at the end
    final tangentSource = Offset(
      lerpDouble(ctrl.dx, p2.dx, 0.8)!,
      lerpDouble(ctrl.dy, p2.dy, 0.8)!
    );
    _drawArrowHead(canvas, tangentSource, p2, paint);
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 8.0; // Increased from 5.0
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize * math.cos(angle - math.pi / 6), to.dy - arrowSize * math.sin(angle - math.pi / 6))
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize * math.cos(angle + math.pi / 6), to.dy - arrowSize * math.sin(angle + math.pi / 6));
    
    final headPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth * 0.8 // Proportionate to general stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    canvas.drawPath(path, headPaint);
  }

  double? lerpDouble(num a, num b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
