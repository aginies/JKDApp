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
    // Duration for the turn: 500ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Full 360 rotation (0 to 0.5s)
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );

    // Constant scale
    _scaleAnimation = ConstantTween<double>(1.0).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Start the rotation animation
    _controller.forward();

    // Start checking for data readiness after logo rotation
    _timer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _checkForData();
      }
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
    // Smooth fade transition
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SeriesListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
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
      backgroundColor: const Color(0xFF111111),
      body: Center(
        child: _isShowingLoading
            ? _buildLoadingIndicator()
            : AnimatedBuilder(
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

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF666666)),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(height: 16),
        Text(
          _seriesCount > 0 ? '$_seriesCount series loaded' : 'Loading...',
          style: TextStyle(
            color: _seriesCount > 0 ? Colors.white60 : Colors.white38,
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
