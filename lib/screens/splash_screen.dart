import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'series_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Duration for the turn: 1s
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Full 360 rotation (0 to 1s)
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );

    // Constant scale (no punch impact)
    _scaleAnimation = ConstantTween<double>(1.0).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeIn)),
    );

    _controller.forward();

    // Navigate to the main screen after the rotation finishes
    Timer(const Duration(milliseconds: 1300), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SeriesListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/icon/JKD.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
