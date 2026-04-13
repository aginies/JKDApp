import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/series_provider.dart';
import '../../../models/kali_angle_elements.dart';
import '../../../models/custom_kali_angle.dart';

enum KaliTool { select, line, curve, circle, ellipse, path }

class KaliAngleDesigner extends StatefulWidget {
  final CustomKaliAngle? existingAngle;
  const KaliAngleDesigner({super.key, this.existingAngle});

  @override
  State<KaliAngleDesigner> createState() => _KaliAngleDesignerState();
}

class _KaliAngleDesignerState extends State<KaliAngleDesigner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  KaliTool _activeTool = KaliTool.line;
  bool _showArrow = true;
  bool _snapEnabled = true;
  final List<DrawingElement> _elements = [];
  DrawingElement? _currentElement;

  int? _selectedElementIndex;
  int? _selectedControlPointIndex;
  String? _initialName;

  bool _isAnimated = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    if (widget.existingAngle != null) {
      _elements.addAll(widget.existingAngle!.elements);
      _initialName = widget.existingAngle!.name;
      _activeTool = KaliTool.select;
    }
  }

  void _toggleAnimation(bool val) {
    setState(() {
      _isAnimated = val;
      if (_isAnimated) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Offset _toDesignCoords(Offset local, Size size) {
    const designSize = KaliDesignerPainter.designSize;
    final scaleX = size.width / designSize;
    final scaleY = size.height / designSize;
    final scale = math.min(scaleX, scaleY);
    final dx = (size.width - designSize * scale) / 2;
    final dy = (size.height - designSize * scale) / 2;
    return Offset((local.dx - dx) / scale, (local.dy - dy) / scale);
  }

  Offset _snapPoint(Offset point) {
    if (!_snapEnabled) return point;
    const gridSize = 15.0;
    const center = Offset(150, 150);

    // Snap to center if very close
    if ((point - center).distance < 10) return center;

    // Grid snapping
    return Offset(
      (point.dx / gridSize).roundToDouble() * gridSize,
      (point.dy / gridSize).roundToDouble() * gridSize,
    );
  }

  double _getDistanceToElement(Offset point, DrawingElement el) {
    if (el is LineElement) {
      return _distanceToLineSegment(point, el.start, el.end);
    } else if (el is CurveElement) {
      // Simplified: check distance to start, end, and control
      final d1 = (point - el.start).distance;
      final d2 = (point - el.end).distance;
      final d3 = (point - el.control).distance;
      return math.min(math.min(d1, d2), d3);
    } else if (el is CircleElement) {
      final d = (point - el.center).distance;
      return (d - el.radius).abs();
    } else if (el is EllipseElement) {
      return (point - el.center).distance; // Simplified
    } else if (el is PathElement) {
      double minD = double.infinity;
      for (int i = 0; i < el.points.length - 1; i++) {
        minD = math.min(
          minD,
          _distanceToLineSegment(point, el.points[i], el.points[i + 1]),
        );
      }
      return minD;
    }
    return double.infinity;
  }

  double _distanceToLineSegment(Offset p, Offset a, Offset b) {
    final l2 = (a - b).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    var t =
        ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = math.max(0, math.min(1, t));
    return (p - Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy)))
        .distance;
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    final point = _toDesignCoords(details.localPosition, size);

    if (_activeTool == KaliTool.select) {
      // 1. Check if clicking on an existing control point of selected element (High Priority)
      if (_selectedElementIndex != null &&
          _selectedElementIndex! < _elements.length) {
        final el = _elements[_selectedElementIndex!];
        final points = el.getControlPoints();
        for (int i = 0; i < points.length; i++) {
          if ((point - points[i]).distance < 30) {
            // Increased hit area
            setState(() {
              _selectedControlPointIndex = i;
            });
            return;
          }
        }
      }

      // 2. Try to select a control point of ANY element
      for (int i = _elements.length - 1; i >= 0; i--) {
        final points = _elements[i].getControlPoints();
        for (int j = 0; j < points.length; j++) {
          if ((point - points[j]).distance < 30) {
            setState(() {
              _selectedElementIndex = i;
              _selectedControlPointIndex = j;
            });
            return;
          }
        }
      }

      // 3. Try to select by tapping the SHAPE itself
      int? bestMatch;
      double minD = 30.0; // Max selection distance

      for (int i = _elements.length - 1; i >= 0; i--) {
        final dist = _getDistanceToElement(point, _elements[i]);
        if (dist < minD) {
          minD = dist;
          bestMatch = i;
        }
      }

      if (bestMatch != null) {
        setState(() {
          _selectedElementIndex = bestMatch;
          _selectedControlPointIndex = null;
        });
        return;
      }

      setState(() {
        _selectedElementIndex = null;
        _selectedControlPointIndex = null;
      });
      return;
    }

    setState(() {
      final snapped = _snapPoint(point);
      switch (_activeTool) {
        case KaliTool.line:
          _currentElement = LineElement(
            start: snapped,
            end: snapped,
            hasArrow: _showArrow,
          );
          break;
        case KaliTool.curve:
          _currentElement = CurveElement(
            start: snapped,
            control: snapped,
            end: snapped,
            hasArrow: _showArrow,
          );
          break;
        case KaliTool.circle:
          _currentElement = CircleElement(center: snapped, radius: 0);
          break;
        case KaliTool.ellipse:
          _currentElement = EllipseElement(
            center: snapped,
            radiusX: 0,
            radiusY: 0,
          );
          break;
        case KaliTool.path:
          _currentElement = PathElement(
            points: [snapped],
            hasArrow: _showArrow,
          );
          break;
        case KaliTool.select:
          break;
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final point = _toDesignCoords(details.localPosition, size);
    final snapped = _snapPoint(point);

    if (_activeTool == KaliTool.select &&
        _selectedElementIndex != null &&
        _selectedControlPointIndex != null) {
      setState(() {
        _elements[_selectedElementIndex!] = _elements[_selectedElementIndex!]
            .updateControlPoint(_selectedControlPointIndex!, snapped);
      });
      return;
    }

    setState(() {
      final current = _currentElement;
      if (current == null) return;

      if (current is LineElement) {
        _currentElement = current.copyWith(end: snapped);
      } else if (current is CurveElement) {
        _currentElement = current.copyWith(
          end: snapped,
          control: Offset(
            (current.start.dx + snapped.dx) / 2,
            (current.start.dy + snapped.dy) / 2 - 30,
          ),
        );
      } else if (current is CircleElement) {
        final radius = (snapped - current.center).distance;
        _currentElement = current.copyWith(radius: radius);
      } else if (current is EllipseElement) {
        final rx = (snapped.dx - current.center.dx).abs();
        final ry = (snapped.dy - current.center.dy).abs();
        _currentElement = current.copyWith(radiusX: rx, radiusY: ry);
      } else if (current is PathElement) {
        _currentElement = current.copyWith(points: [...current.points, point]);
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      if (_currentElement != null) {
        _elements.add(_currentElement!);
        _currentElement = null;
        // Auto select the new element
        _selectedElementIndex = _elements.length - 1;
      }
      _selectedControlPointIndex = null;
    });
  }

  void _saveAngle() async {
    if (_elements.isEmpty) return;

    final controller = TextEditingController(text: _initialName ?? "");
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          widget.existingAngle == null
              ? 'Save Kali Angle'
              : 'Update Kali Angle',
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Angle Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      if (!mounted) return;
      final provider = context.read<SeriesProvider>();
      final trimmedName = name.trim();

      if (widget.existingAngle != null) {
        final updated = CustomKaliAngle(
          id: widget.existingAngle!.id,
          name: trimmedName,
          elements: _elements,
        );
        await provider.updateCustomAngle(updated);
      } else {
        await provider.addCustomAngle(trimmedName, _elements);
      }

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kali Angle Designer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.blue),
            onPressed: _elements.isEmpty ? null : _saveAngle,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _elements.isEmpty
                ? null
                : () => setState(() {
                    _elements.removeLast();
                    _selectedElementIndex = null;
                    _selectedControlPointIndex = null;
                  }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _elements.isEmpty
                ? null
                : () => setState(() {
                    _elements.clear();
                    _selectedElementIndex = null;
                    _selectedControlPointIndex = null;
                  }),
          ),

          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolButton(
                    icon: Icons.near_me,
                    label: 'Select',
                    isActive: _activeTool == KaliTool.select,
                    onPressed: () =>
                        setState(() => _activeTool = KaliTool.select),
                  ),
                  const SizedBox(width: 8, child: VerticalDivider()),
                  _ToolButton(
                    icon: Icons.linear_scale,
                    label: 'Line',
                    isActive: _activeTool == KaliTool.line,
                    onPressed: () =>
                        setState(() => _activeTool = KaliTool.line),
                  ),
                  _ToolButton(
                    icon: Icons.gesture,
                    label: 'Curve',
                    isActive: _activeTool == KaliTool.curve,
                    onPressed: () =>
                        setState(() => _activeTool = KaliTool.curve),
                  ),
                  _ToolButton(
                    icon: Icons.panorama_fish_eye,
                    label: 'Circle',
                    isActive: _activeTool == KaliTool.circle,
                    onPressed: () =>
                        setState(() => _activeTool = KaliTool.circle),
                  ),
                  _ToolButton(
                    icon: Icons.exposure_zero,
                    label: 'Ellipse',
                    isActive: _activeTool == KaliTool.ellipse,
                    onPressed: () =>
                        setState(() => _activeTool = KaliTool.ellipse),
                  ),
                  _ToolButton(
                    icon: Icons.polyline,
                    label: 'Path',
                    isActive: _activeTool == KaliTool.path,
                    onPressed: () =>
                        setState(() => _activeTool = KaliTool.path),
                  ),
                  const VerticalDivider(),
                  _ToolButton(
                    icon: _snapEnabled ? Icons.grid_on : Icons.grid_off,
                    label: 'Snap',
                    isActive: _snapEnabled,
                    onPressed: () =>
                        setState(() => _snapEnabled = !_snapEnabled),
                  ),
                  const VerticalDivider(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Arrow', style: TextStyle(fontSize: 10)),
                      Switch(
                        value: _showArrow,
                        onChanged: (val) => setState(() => _showArrow = val),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Move', style: TextStyle(fontSize: 10)),
                      Switch(value: _isAnimated, onChanged: _toggleAnimation),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return GestureDetector(
                      onPanStart: (d) => _handlePanStart(d, size),
                      onPanUpdate: (d) => _handlePanUpdate(d, size),
                      onPanEnd: _handlePanEnd,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: KaliDesignerPainter(
                              elements: _elements,
                              currentElement: _currentElement,
                              selectedElementIndex: _selectedElementIndex,
                              progress: _isAnimated
                                  ? _animationController.value
                                  : 1.0,
                            ),
                            size: Size.infinite,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Preview: '),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: KaliDesignerPainter(
                          elements: _elements,
                          isThumbnail: true,
                          selectedElementIndex: _selectedElementIndex,
                          progress: _isAnimated
                              ? _animationController.value
                              : 1.0,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          color: isActive ? Theme.of(context).colorScheme.primary : null,
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class KaliDesignerPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final bool isThumbnail;
  final double progress;
  final int? selectedElementIndex;

  static const double designSize = 300.0;

  KaliDesignerPainter({
    required this.elements,
    this.currentElement,
    this.isThumbnail = false,
    this.progress = 1.0,
    this.selectedElementIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isThumbnail) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = math.min(size.width, size.height) / 2 * 0.9;
      final refPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, refPaint);

      final borderPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius, borderPaint);

      // Draw grid if in select mode or designing
      if (selectedElementIndex != null || currentElement != null) {
        final gridPaint = Paint()
          ..color = Colors.grey.withValues(alpha: 0.05)
          ..strokeWidth = 0.5;
        for (
          double i = 0;
          i <= size.width;
          i += (size.width / (designSize / 15))
        ) {
          canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
        }
        for (
          double i = 0;
          i <= size.height;
          i += (size.height / (designSize / 15))
        ) {
          canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
        }
      }
    }

    final scaleX = size.width / designSize;
    final scaleY = size.height / designSize;
    final scale = math.min(scaleX, scaleY);

    final dx = (size.width - designSize * scale) / 2;
    final dy = (size.height - designSize * scale) / 2;

    canvas.translate(dx, dy);
    canvas.scale(scale);

    // Use thinner lines in the designer for better visibility of control points,
    // but keep them thick in the thumbnail (preview).
    final strokeWidth = isThumbnail ? 36.0 : 12.0;

    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < elements.length; i++) {
      final isSelected = i == selectedElementIndex;
      final p = isSelected
          ? (Paint()
              ..color = Colors.blue.withValues(alpha: 0.8)
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke)
          : paint;
      elements[i].paint(canvas, p, isThumbnail: isThumbnail);

      if (isSelected && !isThumbnail) {
        // Draw control points
        final cpPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
        final controlPoints = elements[i].getControlPoints();
        for (var pt in controlPoints) {
          canvas.drawCircle(pt, 6, cpPaint); // Slightly smaller control points
          canvas.drawCircle(
            pt,
            4,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill,
          );
        }
      }
    }

    if (currentElement != null) {
      final currentPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      currentElement!.paint(canvas, currentPaint);
    }

    if (elements.isNotEmpty) {
      final dotPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill
        ..strokeWidth = strokeWidth;

      final numElements = elements.length;
      final elementDuration = 1.0 / numElements;

      final clampedProgress = progress.clamp(0.0, 0.999);
      final int currentIdx = (clampedProgress / elementDuration).floor().clamp(
        0,
        numElements - 1,
      );
      final double elementProgress =
          (clampedProgress % elementDuration) / elementDuration;

      elements[currentIdx].paintAnimatedDot(canvas, dotPaint, elementProgress);
    }
  }

  @override
  bool shouldRepaint(covariant KaliDesignerPainter oldDelegate) => true;
}
