import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/series_provider.dart';
import '../../../models/kali_angle_elements.dart';

enum KaliTool { line, curve, circle, ellipse, path }

class KaliAngleDesigner extends StatefulWidget {
  const KaliAngleDesigner({super.key});

  @override
  State<KaliAngleDesigner> createState() => _KaliAngleDesignerState();
}

class _KaliAngleDesignerState extends State<KaliAngleDesigner> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  KaliTool _activeTool = KaliTool.line;
  bool _showArrow = true;
  final List<DrawingElement> _elements = [];
  DrawingElement? _currentElement;

  bool _isAnimated = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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

  void _handlePanStart(DragStartDetails details, Size size) {
    setState(() {
      final point = _toDesignCoords(details.localPosition, size);
      switch (_activeTool) {
        case KaliTool.line:
          _currentElement = LineElement(start: point, end: point, hasArrow: _showArrow);
          break;
        case KaliTool.curve:
          _currentElement = CurveElement(start: point, control: point, end: point, hasArrow: _showArrow);
          break;
        case KaliTool.circle:
          _currentElement = CircleElement(center: point, radius: 0);
          break;
        case KaliTool.ellipse:
          _currentElement = EllipseElement(center: point, radiusX: 0, radiusY: 0);
          break;
        case KaliTool.path:
          _currentElement = PathElement(points: [point], hasArrow: _showArrow);
          break;
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      final point = _toDesignCoords(details.localPosition, size);
      final current = _currentElement;
      if (current == null) return;

      if (current is LineElement) {
        _currentElement = current.copyWith(end: point);
      } else if (current is CurveElement) {
        final mid = Offset((current.start.dx + point.dx) / 2, (current.start.dy + point.dy) / 2);
        _currentElement = current.copyWith(end: point, control: Offset(mid.dx, mid.dy - 30));
      } else if (current is CircleElement) {
        final radius = (point - current.center).distance;
        _currentElement = current.copyWith(radius: radius);
      } else if (current is EllipseElement) {
        final rx = (point.dx - current.center.dx).abs();
        final ry = (point.dy - current.center.dy).abs();
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
      }
    });
  }

  void _saveAngle() async {
    if (_elements.isEmpty) return;

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Kali Angle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Angle Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      if (!mounted) return;
      await context.read<SeriesProvider>().addCustomAngle(name.trim(), _elements);
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
            onPressed: _elements.isEmpty ? null : () => setState(() => _elements.removeLast()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _elements.isEmpty ? null : () => setState(() => _elements.clear()),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.linear_scale,
                  label: 'Line',
                  isActive: _activeTool == KaliTool.line,
                  onPressed: () => setState(() => _activeTool = KaliTool.line),
                ),
                _ToolButton(
                  icon: Icons.gesture,
                  label: 'Curve',
                  isActive: _activeTool == KaliTool.curve,
                  onPressed: () => setState(() => _activeTool = KaliTool.curve),
                ),
                _ToolButton(
                  icon: Icons.panorama_fish_eye,
                  label: 'Circle',
                  isActive: _activeTool == KaliTool.circle,
                  onPressed: () => setState(() => _activeTool = KaliTool.circle),
                ),
                _ToolButton(
                  icon: Icons.exposure_zero,
                  label: 'Ellipse',
                  isActive: _activeTool == KaliTool.ellipse,
                  onPressed: () => setState(() => _activeTool = KaliTool.ellipse),
                ),
                _ToolButton(
                  icon: Icons.polyline,
                  label: 'Path',
                  isActive: _activeTool == KaliTool.path,
                  onPressed: () => setState(() => _activeTool = KaliTool.path),
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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Move', style: TextStyle(fontSize: 10)),
                    Switch(
                      value: _isAnimated,
                      onChanged: _toggleAnimation,
                    ),
                  ],
                ),
              ],
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
                              progress: _isAnimated ? _animationController.value : 1.0,
                            ),
                            size: Size.infinite,
                          );
                        }
                      ),
                    );
                  }
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
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: KaliDesignerPainter(
                          elements: _elements,
                          isThumbnail: true,
                          progress: _isAnimated ? _animationController.value : 1.0,
                        ),
                      );
                    }
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
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? Theme.of(context).colorScheme.primary : null)),
      ],
    );
  }
}

class KaliDesignerPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final bool isThumbnail;
  final double progress;

  static const double designSize = 300.0;

  KaliDesignerPainter({
    required this.elements,
    this.currentElement,
    this.isThumbnail = false,
    this.progress = 1.0,
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
    }

    final scaleX = size.width / designSize;
    final scaleY = size.height / designSize;
    final scale = math.min(scaleX, scaleY);
    
    final dx = (size.width - designSize * scale) / 2;
    final dy = (size.height - designSize * scale) / 2;
    
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 36.0 // Standardized design-space width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final element in elements) {
      element.paint(canvas, paint, isThumbnail: isThumbnail);
    }

    if (currentElement != null) {
      final currentPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = 36.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      currentElement!.paint(canvas, currentPaint);
    }

    if (elements.isNotEmpty) {
      final dotPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill
        ..strokeWidth = 36.0;
      
      final numElements = elements.length;
      final elementDuration = 1.0 / numElements;
      
      final clampedProgress = progress.clamp(0.0, 0.999);
      final int currentIdx = (clampedProgress / elementDuration).floor().clamp(0, numElements - 1);
      final double elementProgress = (clampedProgress % elementDuration) / elementDuration;
      
      elements[currentIdx].paintAnimatedDot(canvas, dotPaint, elementProgress);
    }
  }

  @override
  bool shouldRepaint(covariant KaliDesignerPainter oldDelegate) => true;
}
