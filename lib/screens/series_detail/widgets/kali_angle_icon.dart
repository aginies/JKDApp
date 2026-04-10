import 'dart:math' as math;
import 'package:flutter/material.dart';

class KaliAngleIcon extends StatefulWidget {
  final int angle;
  final double size;
  final Color color;
  final bool showCircle;
  final bool animated;

  const KaliAngleIcon({
    super.key,
    required this.angle,
    this.size = 40,
    this.color = Colors.brown,
    this.showCircle = true,
    this.animated = true,
  });

  @override
  State<KaliAngleIcon> createState() => _KaliAngleIconState();
}

class _KaliAngleIconState extends State<KaliAngleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(KaliAngleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _KaliAnglePainter(
              angle: widget.angle,
              color: widget.color,
              showCircle: widget.showCircle,
              progress: widget.animated ? _controller.value : 1.0,
            ),
          ),
        );
      },
    );
  }
}

class _KaliAnglePainter extends CustomPainter {
  final int angle;
  final Color color;
  final bool showCircle;
  final double progress;

  _KaliAnglePainter({
    required this.angle,
    required this.color,
    required this.showCircle,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.4) // Faded background path
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (showCircle) {
      final circlePaint = Paint()
        ..color = color.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, circlePaint);
      
      final borderPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius, borderPaint);
    }

    switch (angle) {
      case 1:
        _drawAnimatedLine(canvas, center, radius, 225, 45, paint, dotPaint);
        break;
      case 2:
        _drawAnimatedLine(canvas, center, radius, 315, 135, paint, dotPaint);
        break;
      case 3:
        _drawAnimatedLine(canvas, center, radius, 180, 0, paint, dotPaint);
        break;
      case 4:
        _drawAnimatedLine(canvas, center, radius, 0, 180, paint, dotPaint);
        break;
      case 5:
        // Straight Thrust (Center) - Big to Small animation
        final thrustRadius = (size.width * 0.2) * (1.0 - (progress * 0.7));
        canvas.drawCircle(center, thrustRadius, dotPaint);
        break;
      case 6:
        _drawAnimatedThrust(canvas, center, radius, true, paint, dotPaint);
        break;
      case 7:
        _drawAnimatedThrust(canvas, center, radius, false, paint, dotPaint);
        break;
      case 8: // Vertical Down
        _drawAnimatedLine(canvas, center, radius, 270, 90, paint, dotPaint);
        break;
      case 9: // Uppercut Left
        _drawAnimatedCurve(canvas, center, radius, false, paint, dotPaint);
        break;
      case 10: // Was Thrust HR, now Uppercut Right
        _drawAnimatedCurve(canvas, center, radius, true, paint, dotPaint);
        break;
      case 11: // Thrust High Left
        _drawAnimatedLine(canvas, center, radius, 210, 30, paint, dotPaint);
        break;
      case 12: // Was Uppercut R, now Thrust High Right
        _drawAnimatedLine(canvas, center, radius, 330, 150, paint, dotPaint);
        break;
      case 13: // Abanico (Fan strike) - 180 degree arc
        _drawAnimatedArc(canvas, center, radius, 180, 0, paint, dotPaint);
        break;
      case 14: // Pugno hit - Vertical line + CCW circle
        _drawAnimatedPugno(canvas, center, radius, paint, dotPaint);
        break;
    }
  }

  void _drawAnimatedPugno(Canvas canvas, Offset center, double radius, Paint pathPaint, Paint dotPaint) {
    final start = Offset(center.dx, center.dy - radius * 0.7);
    final endLine = Offset(center.dx, center.dy + radius * 0.1);
    
    // Circle at the bottom of the line
    final circleRadius = radius * 0.25;
    final circleCenter = Offset(center.dx + circleRadius, center.dy + radius * 0.1);
    final rect = Rect.fromCircle(center: circleCenter, radius: circleRadius);
    
    // Draw background path
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(endLine.dx, endLine.dy);
    path.addArc(rect, math.pi, 2 * math.pi); // CCW circle
    canvas.drawPath(path, pathPaint);
    
    // Arrow on top of the line pointing down
    final p1 = Offset(start.dx, start.dy);
    final p2 = Offset(start.dx, start.dy + 1);
    _drawArrowHead(canvas, p1, p2, pathPaint);

    // Animate dot through the two segments
    Offset currentPos;
    if (progress < 0.5) {
      // First part: Vertical line (0.0 to 1.0)
      final t = progress / 0.5;
      currentPos = Offset(
        lerpDouble(start.dx, endLine.dx, t)!,
        lerpDouble(start.dy, endLine.dy, t)!
      );
    } else {
      // Second part: CCW Circle (0.0 to 1.0)
      final t = (progress - 0.5) / 0.5;
      final angle = math.pi + (2 * math.pi * t);
      currentPos = Offset(
        circleCenter.dx + circleRadius * math.cos(angle),
        circleCenter.dy + circleRadius * math.sin(angle)
      );
    }
    canvas.drawCircle(currentPos, pathPaint.strokeWidth * 0.8, dotPaint);
  }

  void _drawAnimatedArc(Canvas canvas, Offset center, double radius, double startAngleDeg, double endAngleDeg, Paint pathPaint, Paint dotPaint) {
    final startRad = startAngleDeg * math.pi / 180;
    final sweepRad = (endAngleDeg - startAngleDeg) * math.pi / 180;
    
    final rect = Rect.fromCircle(center: center, radius: radius * 0.85);
    
    // Draw background arc
    canvas.drawArc(rect, startRad, sweepRad, false, pathPaint);
    
    // Calculate looping progress (0 -> 1 -> 0)
    final loopProgress = 1.0 - (progress * 2 - 1).abs();

    // Draw tracking dot
    final currentRad = startRad + (sweepRad * loopProgress);
    final currentPos = Offset(
      center.dx + radius * 0.85 * math.cos(currentRad),
      center.dy + radius * 0.85 * math.sin(currentRad)
    );
    canvas.drawCircle(currentPos, pathPaint.strokeWidth * 0.8, dotPaint);
  }

  void _drawAnimatedLine(Canvas canvas, Offset center, double radius, double startAngleDeg, double endAngleDeg, Paint pathPaint, Paint dotPaint) {
    final startRad = startAngleDeg * math.pi / 180;
    final endRad = endAngleDeg * math.pi / 180;
    
    final p1 = Offset(center.dx + radius * 0.95 * math.cos(startRad), center.dy + radius * 0.95 * math.sin(startRad));
    final p2 = Offset(center.dx + radius * 0.95 * math.cos(endRad), center.dy + radius * 0.95 * math.sin(endRad));
    
    // Draw background line
    canvas.drawLine(p1, p2, pathPaint);
    
    // Draw arrow head at end
    _drawArrowHead(canvas, p1, p2, pathPaint);

    // Draw tracking dot
    final currentPos = Offset(
      lerpDouble(p1.dx, p2.dx, progress)!,
      lerpDouble(p1.dy, p2.dy, progress)!
    );
    canvas.drawCircle(currentPos, pathPaint.strokeWidth * 0.8, dotPaint);
  }

  void _drawAnimatedCurve(Canvas canvas, Offset center, double radius, bool isRight, Paint pathPaint, Paint dotPaint) {
    final p1 = isRight 
        ? Offset(center.dx - radius * 0.8, center.dy + radius * 0.2)
        : Offset(center.dx + radius * 0.8, center.dy + radius * 0.2);
    final ctrl = Offset(center.dx - radius * 0.2, center.dy + radius * 1.0);
    final p2 = isRight
        ? Offset(center.dx + radius * 0.8, center.dy - radius * 0.8)
        : Offset(center.dx - radius * 0.8, center.dy - radius * 0.8);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
    canvas.drawPath(path, pathPaint);

    // Arrowhead
    final tangentSource = Offset(
      lerpDouble(ctrl.dx, p2.dx, 0.8)!,
      lerpDouble(ctrl.dy, p2.dy, 0.8)!
    );
    _drawArrowHead(canvas, tangentSource, p2, pathPaint);

    // Calculate dot position on quadratic bezier: (1-t)^2*P0 + 2(1-t)t*P1 + t^2*P2
    final t = progress;
    final dotX = math.pow(1 - t, 2) * p1.dx + 2 * (1 - t) * t * ctrl.dx + math.pow(t, 2) * p2.dx;
    final dotY = math.pow(1 - t, 2) * p1.dy + 2 * (1 - t) * t * ctrl.dy + math.pow(t, 2) * p2.dy;
    
    canvas.drawCircle(Offset(dotX, dotY), pathPaint.strokeWidth * 0.8, dotPaint);
  }

  void _drawAnimatedThrust(Canvas canvas, Offset center, double radius, bool isLeftHand, Paint pathPaint, Paint dotPaint) {
    final start = isLeftHand
        ? Offset(center.dx - radius * 0.7, center.dy + radius * 0.5)
        : Offset(center.dx + radius * 0.7, center.dy + radius * 0.5);
    final mid = isLeftHand
        ? Offset(center.dx - radius * 0.9, center.dy + radius * 0.1)
        : Offset(center.dx + radius * 0.9, center.dy + radius * 0.1);
    final end = isLeftHand
        ? Offset(center.dx + radius * 0.6, center.dy - radius * 0.6)
        : Offset(center.dx - radius * 0.6, center.dy - radius * 0.6);

    // Using a more identifiable point for the "loading" part of the thrust
    final midPoint = Offset(center.dx + (isLeftHand ? -radius * 0.2 : radius * 0.2), center.dy + radius * 0.1);

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(mid.dx, mid.dy, midPoint.dx, midPoint.dy);
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, pathPaint);
    
    _drawArrowHead(canvas, midPoint, end, pathPaint);

    // Animate dot through the two segments
    Offset currentPos;
    if (progress < 0.3) {
      // First part: Curve (normalized progress 0.0 to 1.0)
      final t = progress / 0.3;
      final x = math.pow(1 - t, 2) * start.dx + 2 * (1 - t) * t * mid.dx + math.pow(t, 2) * midPoint.dx;
      final y = math.pow(1 - t, 2) * start.dy + 2 * (1 - t) * t * mid.dy + math.pow(t, 2) * midPoint.dy;
      currentPos = Offset(x, y);
    } else {
      // Second part: Straight line (normalized progress 0.0 to 1.0)
      final t = (progress - 0.3) / 0.7;
      currentPos = Offset(
        lerpDouble(midPoint.dx, end.dx, t)!,
        lerpDouble(midPoint.dy, end.dy, t)!
      );
    }
    canvas.drawCircle(currentPos, pathPaint.strokeWidth * 0.8, dotPaint);
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 8.0;
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize * math.cos(angle - math.pi / 6), to.dy - arrowSize * math.sin(angle - math.pi / 6))
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize * math.cos(angle + math.pi / 6), to.dy - arrowSize * math.sin(angle + math.pi / 6));
    
    final headPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.8)
      ..strokeWidth = paint.strokeWidth * 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    canvas.drawPath(path, headPaint);
  }

  double? lerpDouble(num a, num b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _KaliAnglePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.angle != angle;
  }
}
