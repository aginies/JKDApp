import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import existing business logic from parent project using package dependency
import 'package:jkd_app/services/series_provider.dart';
import 'package:jkd_app/models/series.dart';
import 'package:jkd_app/models/move.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => SeriesProvider(),
      child: const WearJkdApp(),
    ),
  );
}

class WearJkdApp extends StatelessWidget {
  const WearJkdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JKD Wear',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const WearSplashScreen(),
    );
  }
}

class WearSplashScreen extends StatefulWidget {
  const WearSplashScreen({super.key});

  @override
  State<WearSplashScreen> createState() => _WearSplashScreenState();
}

class _WearSplashScreenState extends State<WearSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WatchScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/icon/JKD.png',
          width: 400,
          height: 400,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRound = MediaQuery.of(context).size.width == MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(
            vertical: isRound ? 40 : 20,
            horizontal: 10,
          ),
          children: [
            // Larger, glowing JKD logo on a white circle
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white24,
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icon/JKD.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'JKD Training',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Start Button with 3D Effect
            Center(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WearSeriesList(),
                  ),
                ),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF448AFF), Color(0xFF2979FF)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'START',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Settings Button with 3D Effect
            Center(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WearSettingsScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      const Text(
                        'SETTINGS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WearSettingsScreen extends StatelessWidget {
  const WearSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeriesProvider>();
    final isRound = MediaQuery.of(context).viewPadding.top > 0;
    
    // Expanded options as requested
    final options = [0, 2, 3, 4, 5, 6, 7, 10, 15, 30];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: isRound ? 30 : 10, bottom: 8),
                child: const Text(
                  'Auto-Advance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: options.map((sec) {
                    final isSelected = provider.autoAdvanceSec == sec;
                    return InkWell(
                      onTap: () {
                        provider.setAutoAdvanceSec(sec);
                      },
                      borderRadius: BorderRadius.circular(isSelected ? 25 : 20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 60 : 45,
                        height: isSelected ? 40 : 35,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white38 : Colors.white10,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            sec == 0 ? 'Off' : '${sec}s',
                            style: TextStyle(
                              fontSize: isSelected ? 12 : 10,
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class WearSeriesList extends StatelessWidget {
  const WearSeriesList({super.key});

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('jun fan') || cat.contains('gung fu')) return Colors.blueAccent;
    if (cat.contains('kali') || cat.contains('escrima')) return Colors.redAccent;
    if (cat.contains('jeet kune do') || cat.contains('jkd')) return Colors.orangeAccent;
    if (cat.contains('trapping')) return Colors.greenAccent;
    if (cat.contains('kick')) return Colors.purpleAccent;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeriesProvider>();
    final series = provider.series;

    if (provider.isLoading && series.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListWheelScrollView.useDelegate(
        itemExtent: 70, // Slightly taller for category label
        perspective: 0.005,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: series.length,
          builder: (context, index) {
            final s = series[index];
            final accentColor = _getCategoryColor(s.category);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WearTrainingView(series: s),
                  ),
                ),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Category color indicator strip
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: accentColor.withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class WearTrainingView extends StatefulWidget {
  final JkdSeries series;
  const WearTrainingView({super.key, required this.series});

  @override
  State<WearTrainingView> createState() => _WearTrainingViewState();
}

class _WearTrainingViewState extends State<WearTrainingView>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  AnimationController? _progressController;
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _initAnimation() {
    final provider = context.read<SeriesProvider>();
    if (provider.autoAdvanceSec > 0) {
      _progressController = AnimationController(
        vsync: this,
        duration: Duration(seconds: provider.autoAdvanceSec),
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _next();
          }
        });
      _progressController!.forward();
    }
  }

  void _startAutoScroll() {
    if (!_scrollController.hasClients || _isAutoScrolling) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _isAutoScrolling = true;
    _runScrollLoop();
  }

  Future<void> _runScrollLoop() async {
    while (mounted && _isAutoScrolling) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) break;

      // Initial delay of 1 second before starting to scroll down
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted || !_isAutoScrolling) break;

      // Scroll a bit further (half bubble size ~20px) to ensure bottom readability
      final targetScroll = maxExtent + 20;
      final duration = Duration(milliseconds: (targetScroll * 25).toInt() + 500);

      // 1. Scroll Down
      await _scrollController.animateTo(
        targetScroll,
        duration: duration,
        curve: Curves.linear,
      );

      // Pause at bottom
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_isAutoScrolling) break;

      // 2. Scroll back Up (smoothly)
      await _scrollController.animateTo(
        0,
        duration: duration,
        curve: Curves.linear,
      );

      // Pause at top
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _isAutoScrolling = false;
    _progressController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _next() {
    if (!mounted) return;
    if (_currentIndex < widget.series.moves.length - 1) {
      setState(() {
        _currentIndex++;
        _isAutoScrolling = false; // Stop current loop
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        if (_progressController != null) {
          _progressController!.reset();
          _progressController!.forward();
        }
        // Restart loop for next item after layout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoScroll();
        });
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildActionBubble(String text, double fontSize, int totalActions) {
    // 1 column if 1-2 actions, 2 columns if 3+
    final isSingleColumn = totalActions <= 2;
    
    return Container(
      width: isSingleColumn ? 150 : 88, 
      margin: const EdgeInsets.all(3),
      padding: EdgeInsets.symmetric(
        vertical: isSingleColumn ? 10 : 6, 
        horizontal: isSingleColumn ? 16 : 6
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Text.rich(
        _buildRichText(
          text,
          fontSize: isSingleColumn ? fontSize + 2 : fontSize,
          isBold: true,
          defaultColor: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  TextSpan _buildRichText(String text,
      {required double fontSize,
      required bool isBold,
      required Color defaultColor}) {
    final List<TextSpan> spans = [];
    
    // Character-by-character tokenization to ensure NO spaces are lost
    final List<String> parts = [];
    String currentPart = '';
    
    final symbols = {'↳', '➜', '+', '.', ':', '/', '(', ')', '↵', '↑', '—', '↓'};
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (symbols.contains(char) || char == ' ') {
        if (currentPart.isNotEmpty) {
          parts.add(currentPart);
          currentPart = '';
        }
        parts.add(char);
      } else {
        currentPart += char;
      }
    }
    if (currentPart.isNotEmpty) parts.add(currentPart);

    for (final part in parts) {
      Color color = defaultColor;
      double finalFontSize = fontSize;
      final trimmed = part.trim();
      final normalized = trimmed.toUpperCase();

      if (['CROSS', 'HOOK', 'JAB'].contains(normalized)) {
        color = Colors.green;
      } else if (normalized == 'L') {
        color = Colors.blue;
      } else if (normalized == 'R') {
        color = Colors.red;
      } else if (normalized == 'F') {
        color = Colors.teal;
      } else if (normalized == 'B') {
        color = Colors.brown;
      } else if (['↳', '➜', '+', '↵', '/'].contains(trimmed)) {
        color = Colors.orangeAccent;
        finalFontSize = fontSize * 1.2;
      } else if (['↑', '—', '↓'].contains(trimmed)) {
        color = Colors.cyanAccent;
        finalFontSize = fontSize * 1.1;
      }

      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          color: color,
          fontSize: finalFontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: symbols.contains(trimmed)
              ? FontStyle.normal
              : (isBold ? FontStyle.normal : FontStyle.italic),
        ),
      ));
    }
    
    return TextSpan(
      children: spans,
      style: TextStyle(color: defaultColor, fontSize: fontSize),
    );
  }

  String _getFullMoveText(Move m) {
    if (m.subMoves.isNotEmpty) {
      return m.subMoves.map(_getFullMoveText).join(' + ');
    }
    if (m.chain.isNotEmpty) {
      return m.chain.map(_getFullMoveText).join(' ➜ ');
    }

    String res = '';
    if (m.side.isNotEmpty) {
      res += '${m.side} '; // Removed the dot for a cleaner "L Jab" look
    }
    res += m.name;
    
    if (m.level.isNotEmpty) {
      final lv = m.level.toLowerCase();
      if (lv.contains('high') || lv == 'h') {
        res += ' ↑';
      } else if (lv.contains('low') || lv == 'l') {
        res += ' ↓';
      } else if (lv.contains('mid') || lv == 'm') {
        res += ' —';
      } else {
        res += ' ($lv)';
      }
    }

    if (m.counterSubMoves.isNotEmpty) {
      res += ' / ${m.counterSubMoves.map(_getFullMoveText).join(' + ')}';
    } else if (m.counterChain.isNotEmpty) {
      res += ' / ${m.counterChain.map(_getFullMoveText).join(' ➜ ')}';
    } else if (m.counterName != null && m.counterName!.isNotEmpty) {
      res += ' / ${m.counterName}';
    }

    return res;
  }

  @override
  Widget build(BuildContext context) {
    final move = widget.series.moves[_currentIndex];
    final provider = context.watch<SeriesProvider>();
    final isRound =
        MediaQuery.of(context).size.width == MediaQuery.of(context).size.height;

    // Build the descriptive text
    String displayName = _getFullMoveText(move);

    // Initial cleanup
    if (displayName.startsWith('Combo: ')) displayName = displayName.substring(7);
    if (displayName.startsWith('Chain: ')) displayName = displayName.substring(7);

    // Standardize separators and force newlines for Wear OS
    displayName = displayName
        .replaceAll(RegExp(r'\s*/\s*'), '\n↳ ')
        .replaceAll(RegExp(r'\s*Counter:\s*', caseSensitive: false), '\n↳ ')
        .replaceAll(RegExp(r'\s*Answer:\s*', caseSensitive: false), '\n↳ ')
        .replaceAll(RegExp(r'\s*➜\s*'), '\n➜ ')
        .replaceAll(RegExp(r'\s*\+\s*'), '\n+ ');

    final List<String> actions = displayName
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Dynamic scaling based on total content
    double baseFontSize = 18.0;
    if (actions.length > 3) baseFontSize = 15.0;
    if (displayName.length > 60) baseFontSize = 14.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _next,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Visual Countdown Border
            if (_progressController != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _progressController!,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ProgressPainter(
                        progress: 1.0 - _progressController!.value,
                      ),
                    );
                  },
                ),
              ),
            // Discreet Progress Overlay at the very top - Moved higher
            Positioned(
              top: isRound ? 14 : 4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_currentIndex + 1}/${widget.series.moves.length}',
                    style: TextStyle(
                      color: Colors.blueAccent.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (provider.autoAdvanceSec > 0) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.timer, 
                         size: 10, 
                         color: Colors.blueAccent.withValues(alpha: 0.8)),
                  ],
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.only(
                top: isRound ? 30 : 18, // Reduced top padding
                bottom: isRound ? 20 : 8, // Reduced bottom padding
                left: 8,
                right: 8,
              ),
              child: Column(
                children: [
                  // Dynamic Column Grid of Action Bubbles - Now uses all space
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4, 
                          runSpacing: 4,
                          children: actions
                              .map((a) => _buildActionBubble(a, baseFontSize, actions.length))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressPainter extends CustomPainter {
  final double progress;

  ProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [Colors.red, Colors.yellow, Colors.green],
        stops: [0.0, 0.5, 1.0],
        transform: GradientRotation(-1.5708), // Start at top (-pi/2)
      ).createShader(rect)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from top (-pi/2)
    canvas.drawArc(
      rect,
      -1.5708, // -pi/2
      2 * 3.14159 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
