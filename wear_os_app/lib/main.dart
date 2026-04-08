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
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border(
                      left: BorderSide(color: accentColor, width: 4),
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
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

  Widget _buildActionBubble(String text, double fontSize) {
    return Container(
      // Dynamic width for 2 columns: roughly half the screen width minus padding
      width: 80, 
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: _buildRichText(
          text,
          fontSize: fontSize,
          isBold: true,
          defaultColor: Colors.white,
        ),
      ),
    );
  }

  TextSpan _buildRichText(String text,
      {required double fontSize,
      required bool isBold,
      required Color defaultColor}) {
    final List<TextSpan> spans = [];
    
    // Pattern that matches words, symbols, or whitespace as individual tokens.
    // This ensures NOTHING is lost during processing.
    final pattern = RegExp(r'(↳|➜|\+|\.|:|\/|\(|\)|↵|↑|—|↓|\s+|[^\s↳➜\+\.:\/\(\)↵↑—↓]+)');
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final part = match.group(0)!;
      if (part.isEmpty) continue;

      Color color = defaultColor;
      double finalFontSize = fontSize;
      final trimmed = part.trim();
      final normalized = trimmed.toUpperCase();

      // Keyword and Symbol identification
      if (['CROSS', 'HOOK', 'JAB'].contains(normalized)) {
        color = Colors.green;
      } else if (normalized == 'L') {
        color = Colors.blue;
      } else if (normalized == 'R') {
        color = Colors.red;
      } else if (['↳', '➜', '+', '↵', '/'].contains(trimmed)) {
        color = Colors.orangeAccent;
        finalFontSize = fontSize * 1.2;
      } else if (['↑', '—', '↓'].contains(trimmed)) {
        color = Colors.cyanAccent;
        finalFontSize = fontSize * 1.1;
      } else if (part.contains(RegExp(r'\s+'))) {
        // Pure whitespace tokens
        spans.add(TextSpan(
          text: part,
          style: TextStyle(color: defaultColor, fontSize: fontSize),
        ));
        continue;
      }

      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          color: color,
          fontSize: finalFontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: ['↳', '➜', '+', '↵', '↑', '—', '↓'].contains(trimmed)
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

    String displayName = _getFullMoveText(move);

    if (displayName.startsWith('Combo: ')) displayName = displayName.substring(7);
    if (displayName.startsWith('Chain: ')) displayName = displayName.substring(7);

    // Apply semantic delimiters and split into vertical chunks
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
            // Discreet Progress Overlay at the very top
            Positioned(
              top: isRound ? 22 : 8,
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
                top: isRound ? 38 : 24, // Adjusted to clear the overlay
                bottom: isRound ? 35 : 16,
                left: 12,
                right: 12,
              ),
              child: Column(
                children: [
                  // Action bubbles now occupy all available vertical space
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4, 
                          runSpacing: 4,
                          children: actions
                              .map((a) => _buildActionBubble(a, baseFontSize))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
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
