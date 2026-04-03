import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A widget that lays out children in a Wrap and draws subtle horizontal
/// separator lines between visual rows when children overflow to a new line.
class SeparatedWrap extends StatelessWidget {
  final double spacing;
  final double runSpacing;
  final List<Widget> children;
  final Color? separatorColor;

  const SeparatedWrap({
    super.key,
    required this.children,
    this.spacing = 4,
    this.runSpacing = 10,
    this.separatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return _SeparatedWrapLayout(
      spacing: spacing,
      runSpacing: runSpacing,
      separatorColor: separatorColor,
      children: children,
    );
  }
}

class _SeparatedWrapLayout extends StatefulWidget {
  final double spacing;
  final double runSpacing;
  final List<Widget> children;
  final Color? separatorColor;

  const _SeparatedWrapLayout({
    required this.spacing,
    required this.runSpacing,
    required this.children,
    this.separatorColor,
  });

  @override
  State<_SeparatedWrapLayout> createState() => _SeparatedWrapLayoutState();
}

class _SeparatedWrapLayoutState extends State<_SeparatedWrapLayout> {
  final GlobalKey _wrapKey = GlobalKey();
  List<double> _rowBottoms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeRows());
  }

  @override
  void didUpdateWidget(covariant _SeparatedWrapLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeRows());
  }

  void _computeRows() {
    final renderBox = _wrapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final wrapRender = renderBox;
    final List<double> bottoms = [];
    double currentRowTop = -1;
    double currentRowBottom = 0;

    void visitChild(RenderObject child) {
      if (child is RenderBox && child.hasSize) {
        final offset = child.localToGlobal(Offset.zero, ancestor: wrapRender);
        final top = offset.dy;
        final bottom = top + child.size.height;

        if (currentRowTop < 0) {
          currentRowTop = top;
          currentRowBottom = bottom;
        } else if (top > currentRowBottom - 1) {
          bottoms.add((currentRowBottom + top) / 2);
          currentRowTop = top;
          currentRowBottom = bottom;
        } else {
          if (bottom > currentRowBottom) currentRowBottom = bottom;
        }
      }
    }

    wrapRender.visitChildren(visitChild);

    if (!mounted) return;
    if (_rowBottoms.length != bottoms.length ||
        !listEquals(_rowBottoms, bottoms)) {
      setState(() {
        _rowBottoms = bottoms;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _RowSeparatorPainter(
        rowBottoms: _rowBottoms,
        color: widget.separatorColor ?? Colors.grey.withValues(alpha: 0.4),
      ),
      child: Wrap(
        key: _wrapKey,
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: widget.children,
      ),
    );
  }
}

class _RowSeparatorPainter extends CustomPainter {
  final List<double> rowBottoms;
  final Color color;

  _RowSeparatorPainter({required this.rowBottoms, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (rowBottoms.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (final y in rowBottoms) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RowSeparatorPainter oldDelegate) {
    return oldDelegate.rowBottoms != rowBottoms || oldDelegate.color != color;
  }
}
