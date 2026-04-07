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
            // Larger, glowing JKD logo
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icon/JKD.png',
                  width: 120,
                  height: 120,
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
            // Start Button
            Center(
              child: SizedBox(
                width: 100,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WearSeriesList(),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Settings Button
            Center(
              child: SizedBox(
                width: 100,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WearSettingsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.settings, size: 14),
                  label: const Text(
                    'Settings',
                    style: TextStyle(fontSize: 12),
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
    final options = [0, 3, 5, 10, 15, 30];

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
            padding: EdgeInsets.symmetric(
              vertical: isRound ? 40 : 20,
              horizontal: 10,
            ),
            children: [
              const Text(
                'Auto-Advance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              ...options.map((sec) {
                final isSelected = provider.autoAdvanceSec == sec;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: InkWell(
                    onTap: () {
                      provider.setAutoAdvanceSec(sec);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sec == 0 ? 'Manual' : '$sec seconds',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
    );
  }
}

class WearSeriesList extends StatelessWidget {
  const WearSeriesList({super.key});

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
            itemExtent: 60,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: series.length,
              builder: (context, index) {
                final s = series[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WearTrainingView(series: s),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          s.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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

  @override
  void initState() {
    super.initState();
    _initAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
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
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    // Wait a moment, then scroll down slowly
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _scrollController
          .animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 40).toInt() + 1000),
        curve: Curves.linear,
      )
          .then((_) {
        if (!mounted) return;
        // Wait at bottom, then scroll back up
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
          );
        });
      });
    });
  }

  @override
  void dispose() {
    _progressController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _next() {
    if (!mounted) return;
    if (_currentIndex < widget.series.moves.length - 1) {
      setState(() {
        _currentIndex++;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        if (_progressController != null) {
          _progressController!.reset();
          _progressController!.forward();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
      });
    } else {
      Navigator.pop(context);
    }
  }

  TextSpan _buildRichText(String text,
      {required double fontSize,
      required bool isBold,
      required Color defaultColor}) {
    final List<TextSpan> spans = [];
    // Capturing delimiters with () in RegExp keeps them in the result
    // Explicitly include ->, ↳, and + in the split/capture
    final allParts = text.split(RegExp(r'(\s+|↳|->|\+|\.|:|\/|\(|\)|↵)'));

    for (var part in allParts) {
      if (part.isEmpty) continue;

      Color color = defaultColor;
      final normalized = part.trim().toUpperCase();

      if (['CROSS', 'HOOK', 'JAB'].contains(normalized)) {
        color = Colors.green;
      } else if (normalized == 'L') {
        color = Colors.blue;
      } else if (normalized == 'R') {
        color = Colors.red;
      } else if (['↳', '->', '+', '↵', '/'].contains(part.trim())) {
        // Make separators stand out
        color = Colors.orangeAccent;
      }

      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          // Symbols should not be italicized even in translation (if we ever restore it)
          fontStyle: ['↳', '->', '+', '↵'].contains(part.trim())
              ? FontStyle.normal
              : (isBold ? FontStyle.normal : FontStyle.italic),
        ),
      ));
    }
    return TextSpan(children: spans);
  }

  String _getFullMoveText(Move m) {
    if (m.subMoves.isNotEmpty) {
      return m.subMoves.map(_getFullMoveText).join(' + ');
    }
    if (m.chain.isNotEmpty) {
      return m.chain.map(_getFullMoveText).join(' -> ');
    }

    String res = '';
    if (m.side.isNotEmpty) {
      res += '${m.side}. ';
    }
    res += m.name;
    if (m.level.isNotEmpty) {
      res += ' (${m.level})';
    }

    // Counters
    if (m.counterSubMoves.isNotEmpty) {
      res += ' / ${m.counterSubMoves.map(_getFullMoveText).join(' + ')}';
    } else if (m.counterChain.isNotEmpty) {
      res += ' / ${m.counterChain.map(_getFullMoveText).join(' -> ')}';
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

    // Get the full descriptive text for the move
    String displayName = _getFullMoveText(move);

    if (displayName.startsWith('Combo: ')) {
      displayName = displayName.substring(7);
    } else if (displayName.startsWith('Chain: ')) {
      displayName = displayName.substring(7);
    }

    // Apply semantic delimiters for Wear OS
    // ↳ for counters, -> for sequences, \n for items
    displayName = displayName
        .replaceAll(' / ', '\n↳ ')
        .replaceAll('Counter: ', '\n↳ ')
        .replaceAll('Answer: ', '\n↳ ')
        .replaceAll(' -> ', '\n-> ')
        .replaceAll(' + ', '\n+ ');

    // Dynamic font size based on content length
    double baseFontSize = 20.0;
    if (displayName.length > 40) baseFontSize = 16.0;
    if (displayName.length > 80) baseFontSize = 14.0;

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
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.only(
                top: isRound ? 35 : 16,
                bottom: isRound ? 35 : 16,
                left: 10,
                right: 10,
              ),
              child: Column(
                children: [
                  // Progress Bubble on Top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${_currentIndex + 1}/${widget.series.moves.length}',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (provider.autoAdvanceSec > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.timer,
                            size: 12, color: Colors.blueAccent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Centered Move Content - Expanded to fill most of the screen
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: _buildRichText(
                            displayName,
                            fontSize: baseFontSize,
                            isBold: true,
                            defaultColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Small indicator if more content below
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.withValues(alpha: 0.3),
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
