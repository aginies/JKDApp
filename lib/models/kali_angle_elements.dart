import 'dart:math' as math;
import 'dart:ui';

abstract class DrawingElement {
  void paint(Canvas canvas, Paint paint, {bool isThumbnail = false});
  void paintAnimatedDot(Canvas canvas, Paint paint, double progress);
  Map<String, dynamic> toJson();
  
  static DrawingElement fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'line': return LineElement.fromJson(json);
      case 'curve': return CurveElement.fromJson(json);
      case 'circle': return CircleElement.fromJson(json);
      case 'ellipse': return EllipseElement.fromJson(json);
      case 'path': return PathElement.fromJson(json);
      default: throw Exception('Unknown element type: ${json['type']}');
    }
  }
}

class LineElement extends DrawingElement {
  final Offset start;
  final Offset end;
  final bool hasArrow;

  LineElement({required this.start, required this.end, required this.hasArrow});

  LineElement copyWith({Offset? start, Offset? end, bool? hasArrow}) {
    return LineElement(
      start: start ?? this.start,
      end: end ?? this.end,
      hasArrow: hasArrow ?? this.hasArrow,
    );
  }
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'line',
    'start': [start.dx, start.dy],
    'end': [end.dx, end.dy],
    'hasArrow': hasArrow,
  };
  
  static LineElement fromJson(Map<String, dynamic> json) => LineElement(
    start: Offset((json['start'][0] as num).toDouble(), (json['start'][1] as num).toDouble()),
    end: Offset((json['end'][0] as num).toDouble(), (json['end'][1] as num).toDouble()),
    hasArrow: json['hasArrow'] as bool,
  );

  @override
  void paint(Canvas canvas, Paint paint, {bool isThumbnail = false}) {
    canvas.drawLine(start, end, paint);
    if (hasArrow) {
      drawArrowHead(canvas, start, end, paint);
    }
  }

  @override
  void paintAnimatedDot(Canvas canvas, Paint paint, double progress) {
    final pos = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );
    canvas.drawCircle(pos, paint.strokeWidth * 1.2, paint..style = PaintingStyle.fill);
  }
}

class CurveElement extends DrawingElement {
  final Offset start;
  final Offset control;
  final Offset end;
  final bool hasArrow;

  CurveElement({required this.start, required this.control, required this.end, required this.hasArrow});

  CurveElement copyWith({Offset? start, Offset? control, Offset? end, bool? hasArrow}) {
    return CurveElement(
      start: start ?? this.start,
      control: control ?? this.control,
      end: end ?? this.end,
      hasArrow: hasArrow ?? this.hasArrow,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'curve',
    'start': [start.dx, start.dy],
    'control': [control.dx, control.dy],
    'end': [end.dx, end.dy],
    'hasArrow': hasArrow,
  };
  
  static CurveElement fromJson(Map<String, dynamic> json) => CurveElement(
    start: Offset((json['start'][0] as num).toDouble(), (json['start'][1] as num).toDouble()),
    control: Offset((json['control'][0] as num).toDouble(), (json['control'][1] as num).toDouble()),
    end: Offset((json['end'][0] as num).toDouble(), (json['end'][1] as num).toDouble()),
    hasArrow: json['hasArrow'] as bool,
  );

  @override
  void paint(Canvas canvas, Paint paint, {bool isThumbnail = false}) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
    if (hasArrow) {
      final tangentSource = Offset(
        (control.dx + end.dx) / 2,
        (control.dy + end.dy) / 2,
      );
      drawArrowHead(canvas, tangentSource, end, paint);
    }
  }

  @override
  void paintAnimatedDot(Canvas canvas, Paint paint, double progress) {
    final t = progress;
    final dotX = math.pow(1 - t, 2) * start.dx +
        2 * (1 - t) * t * control.dx +
        math.pow(t, 2) * end.dx;
    final dotY = math.pow(1 - t, 2) * start.dy +
        2 * (1 - t) * t * control.dy +
        math.pow(t, 2) * end.dy;
    canvas.drawCircle(Offset(dotX, dotY), paint.strokeWidth * 1.2, paint..style = PaintingStyle.fill);
  }
}

class CircleElement extends DrawingElement {
  final Offset center;
  final double radius;

  CircleElement({required this.center, required this.radius});

  CircleElement copyWith({Offset? center, double? radius}) {
    return CircleElement(
      center: center ?? this.center,
      radius: radius ?? this.radius,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'circle',
    'center': [center.dx, center.dy],
    'radius': radius,
  };
  
  static CircleElement fromJson(Map<String, dynamic> json) => CircleElement(
    center: Offset((json['center'][0] as num).toDouble(), (json['center'][1] as num).toDouble()),
    radius: (json['radius'] as num).toDouble(),
  );

  @override
  void paint(Canvas canvas, Paint paint, {bool isThumbnail = false}) {
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paintAnimatedDot(Canvas canvas, Paint paint, double progress) {
    final angle = 2 * math.pi * progress;
    final pos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(pos, paint.strokeWidth * 1.2, paint..style = PaintingStyle.fill);
  }
}

class EllipseElement extends DrawingElement {
  final Offset center;
  final double radiusX;
  final double radiusY;

  EllipseElement({required this.center, required this.radiusX, required this.radiusY});

  EllipseElement copyWith({Offset? center, double? radiusX, double? radiusY}) {
    return EllipseElement(
      center: center ?? this.center,
      radiusX: radiusX ?? this.radiusX,
      radiusY: radiusY ?? this.radiusY,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ellipse',
    'center': [center.dx, center.dy],
    'radiusX': radiusX,
    'radiusY': radiusY,
  };
  
  static EllipseElement fromJson(Map<String, dynamic> json) => EllipseElement(
    center: Offset((json['center'][0] as num).toDouble(), (json['center'][1] as num).toDouble()),
    radiusX: (json['radiusX'] as num).toDouble(),
    radiusY: (json['radiusY'] as num).toDouble(),
  );

  @override
  void paint(Canvas canvas, Paint paint, {bool isThumbnail = false}) {
    canvas.drawOval(Rect.fromLTRB(center.dx - radiusX, center.dy - radiusY, center.dx + radiusX, center.dy + radiusY), paint);
  }

  @override
  void paintAnimatedDot(Canvas canvas, Paint paint, double progress) {
    final angle = 2 * math.pi * progress;
    final pos = Offset(
      center.dx + radiusX * math.cos(angle),
      center.dy + radiusY * math.sin(angle),
    );
    canvas.drawCircle(pos, paint.strokeWidth * 1.2, paint..style = PaintingStyle.fill);
  }
}

class PathElement extends DrawingElement {
  final List<Offset> points;
  final bool hasArrow;

  PathElement({required this.points, required this.hasArrow});

  PathElement copyWith({List<Offset>? points, bool? hasArrow}) {
    return PathElement(
      points: points ?? this.points,
      hasArrow: hasArrow ?? this.hasArrow,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'path',
    'points': points.map((p) => [p.dx, p.dy]).toList(),
    'hasArrow': hasArrow,
  };
  
  static PathElement fromJson(Map<String, dynamic> json) => PathElement(
    points: (json['points'] as List).map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList(),
    hasArrow: json['hasArrow'] as bool,
  );

  @override
  void paint(Canvas canvas, Paint paint, {bool isThumbnail = false}) {
    if (points.length < 2) return;
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
    if (hasArrow && points.length >= 2) {
      drawArrowHead(canvas, points[points.length - 2], points.last, paint);
    }
  }

  @override
  void paintAnimatedDot(Canvas canvas, Paint paint, double progress) {
    if (points.length < 2) return;
    final totalSegments = points.length - 1;
    final segmentIdx = (progress * totalSegments).floor().clamp(0, totalSegments - 1);
    final segmentProgress = (progress * totalSegments) - segmentIdx;
    
    final p1 = points[segmentIdx];
    final p2 = points[segmentIdx + 1];
    
    final pos = Offset(
      p1.dx + (p2.dx - p1.dx) * segmentProgress,
      p1.dy + (p2.dy - p1.dy) * segmentProgress,
    );
    canvas.drawCircle(pos, paint.strokeWidth * 1.2, paint..style = PaintingStyle.fill);
  }
}

void drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
  final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
  final strokeWidth = paint.strokeWidth;
  final tip = Offset(
    to.dx + math.cos(angle) * (strokeWidth / 2),
    to.dy + math.sin(angle) * (strokeWidth / 2),
  );
  final arrowSize = strokeWidth * 3.5;
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(tip.dx - arrowSize * math.cos(angle - 0.6),
        tip.dy - arrowSize * math.sin(angle - 0.6))
    ..lineTo(tip.dx - arrowSize * math.cos(angle + 0.6),
        tip.dy - arrowSize * math.sin(angle + 0.6))
    ..close();
  final headPaint = Paint()
    ..color = paint.color.withValues(alpha: 0.9)
    ..style = PaintingStyle.fill;
  canvas.drawPath(path, headPaint);
}
