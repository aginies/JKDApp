import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/series_provider.dart';
import 'series_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _timer;
  bool _isShowingLoading = false;
  int _seriesCount = 0; // Track loaded count for loading indicator

  @override
  void initState() {
    super.initState();
    // Duration for rotation: 800ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Full 360 rotation (two full spins for effect)
    _rotateAnimation = Tween<double>(begin: 0.0, end: 4 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Scale animation - start small, grow, then return to normal for Hero
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50.0,
      ),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Start the rotation animation
    _controller.forward().then((_) {
      // After rotation completes, wait a bit then check for data
      _timer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkForData();
        }
      });
    });
  }

  void _checkForData() async {
    // Use provider to check for loaded series
    final provider = Provider.of<SeriesProvider>(context, listen: false);

    while (mounted) {
      // Check if series list is populated
      final count = provider.series.length;
      _seriesCount = count;

      if (count > 0) {
        if (mounted) {
          _navigateToShowApp();
        }
        return;
      }

      // Poll every 200ms
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // If still not ready after polling
    _setState(() {});

    if (mounted) {
      _navigateToShowApp();
    }
  }

  void _setState(VoidCallback cb) {
    setState(() {
      _isShowingLoading = true;
    });
    cb();
  }

  void _navigateToShowApp() async {
    // Brief delay to ensure rotation is settled at 0
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // Use PageRouteBuilder with longer duration for visible Hero transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SeriesListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade in the new screen gradually
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeIn,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Center(
        child: _isShowingLoading
            ? _buildLoadingIndicator()
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Use modulo to keep rotation at 0 when animation completes
                  // This ensures Hero transition starts from non-rotated state
                  final angle = _controller.status == AnimationStatus.completed
                      ? 0.0
                      : _rotateAnimation.value;

                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.rotate(
                      angle: angle,
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

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF666666)),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(height: 16),
        Text(
          _seriesCount > 0 ? '$_seriesCount series loaded' : 'Loading...',
          style: TextStyle(
            color: _seriesCount > 0 ? Colors.black87 : Colors.black54,
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
