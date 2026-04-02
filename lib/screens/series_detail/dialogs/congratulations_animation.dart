import 'package:flutter/material.dart';
import 'dart:math' as math;

class CongratulationsAnimation extends StatefulWidget {
  final bool isDayComplete;
  const CongratulationsAnimation({super.key, this.isDayComplete = false});

  static void show(BuildContext context, {bool isDayComplete = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CongratulationsAnimation(isDayComplete: isDayComplete),
    );
  }

  @override
  State<CongratulationsAnimation> createState() =>
      _CongratulationsAnimationState();
}

class _CongratulationsAnimationState extends State<CongratulationsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    // Auto-close after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: ConfettiPainter(animation: _controller),
            size: const Size(double.infinity, double.infinity),
          ),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isDayComplete ? 'DAY COMPLETED!' : 'SERIES DONE!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isDayComplete
                      ? 'You have finished today\'s program!'
                      : 'Great job on your training!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
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

class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<ConfettiPiece> confetti = List.generate(
    100,
    (i) => ConfettiPiece(),
  );

  ConfettiPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in confetti) {
      final progress = animation.value;
      final opacity = 1.0 - progress;
      final x = piece.x * size.width;
      final y = (piece.y * size.height) + (progress * size.height * 0.5);

      final paint = Paint()
        ..color = piece.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * piece.rotationSpeed);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 12),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class ConfettiPiece {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble() * 0.5;
  final Color color =
      Colors.primaries[math.Random().nextInt(Colors.primaries.length)];
  final double rotationSpeed = math.Random().nextDouble() * 10;
}
