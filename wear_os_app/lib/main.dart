import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Import existing business logic from parent project using package dependency
import 'package:jkd_app/services/series_provider.dart';
import 'package:jkd_app/models/series.dart';
import 'package:jkd_app/models/move.dart';
import 'package:jkd_app/screens/series_detail/widgets/kali_angle_icon.dart';

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
    await Future.delayed(const Duration(seconds: 1));
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
    final isRound =
        MediaQuery.of(context).size.width == MediaQuery.of(context).size.height;

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
            // Warm Up Button
            Center(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WearWarmupScreen(),
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
                      colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
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
                      Icon(Icons.directions_run, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'WARM UP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0,
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
                      const Icon(
                        Icons.settings,
                        size: 14,
                        color: Colors.white70,
                      ),
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
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white.withValues(alpha: 0.1),
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
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
    if (cat.contains('jun fan') || cat.contains('gung fu')) {
      return Colors.blueAccent;
    }
    if (cat.contains('kali') || cat.contains('escrima')) {
      return Colors.redAccent;
    }
    if (cat.contains('jeet kune do') || cat.contains('jkd')) {
      return Colors.orangeAccent;
    }
    if (cat.contains('trapping')) {
      return Colors.greenAccent;
    }
    if (cat.contains('kick')) {
      return Colors.purpleAccent;
    }
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

    final controller = FixedExtentScrollController();

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 70,
        perspective: 0.005,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (_) {
          HapticFeedback.selectionClick();
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: series.length,
          builder: (context, index) {
            final s = series[index];
            final accentColor = _getCategoryColor(s.category);

            return ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final selectedIndex = controller.hasClients
                    ? controller.selectedItem
                    : 0;
                final isSelected = index == selectedIndex;

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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.2)
                            : accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 1.5 : 1,
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12, // was 9px
                                      color: accentColor.withValues(
                                        alpha: isSelected ? 1.0 : 0.7,
                                      ),
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
  int _repCount = 0;
  bool _showRepScreen = false;
  bool _mirrorMode = false;
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
      _progressController =
          AnimationController(
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

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted || !_isAutoScrolling) break;

      final targetScroll = maxExtent + 20;
      final duration = Duration(
        milliseconds: (targetScroll * 25).toInt() + 500,
      );

      await _scrollController.animateTo(
        targetScroll,
        duration: duration,
        curve: Curves.linear,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_isAutoScrolling) break;

      await _scrollController.animateTo(
        0,
        duration: duration,
        curve: Curves.linear,
      );

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
    HapticFeedback.lightImpact();
    if (_currentIndex < widget.series.moves.length - 1) {
      setState(() {
        _currentIndex++;
        _isAutoScrolling = false;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        if (_progressController != null) {
          _progressController!.reset();
          _progressController!.forward();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoScroll();
        });
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _repCount++;
        _showRepScreen = true;
        _isAutoScrolling = false;
        _progressController?.stop();
      });
    }
  }

  void _repeat() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = 0;
      _showRepScreen = false;
      _isAutoScrolling = false;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      if (_progressController != null) {
        _progressController!.reset();
        _progressController!.forward();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  Widget _buildActionBubble(String text, double fontSize, int totalActions) {
    final isSingleColumn = totalActions <= 2;

    return Container(
      width: isSingleColumn ? 150 : 88,
      margin: const EdgeInsets.all(3),
      padding: EdgeInsets.symmetric(
        vertical: isSingleColumn ? 10 : 6,
        horizontal: isSingleColumn ? 16 : 6,
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

  TextSpan _buildRichText(
    String text, {
    required double fontSize,
    required bool isBold,
    required Color defaultColor,
  }) {
    final List<TextSpan> spans = [];

    final List<String> parts = [];
    String currentPart = '';

    final symbols = {
      '↳',
      '➜',
      '+',
      '.',
      ':',
      '/',
      '(',
      ')',
      '↵',
      '↑',
      '—',
      '↓',
    };

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

      spans.add(
        TextSpan(
          text: part,
          style: TextStyle(
            color: color,
            fontSize: finalFontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: symbols.contains(trimmed)
                ? FontStyle.normal
                : (isBold ? FontStyle.normal : FontStyle.italic),
          ),
        ),
      );
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
      final side = _mirrorMode
          ? (m.side == 'L'
                ? 'R'
                : m.side == 'R'
                ? 'L'
                : m.side)
          : m.side;
      res += '$side ';
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
    if (_showRepScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _repeat,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_repCount×',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TAP TO REPEAT',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final move = widget.series.moves[_currentIndex];
    final provider = context.watch<SeriesProvider>();
    final isRound =
        MediaQuery.of(context).size.width == MediaQuery.of(context).size.height;

    String displayName = _getFullMoveText(move);

    if (displayName.startsWith('Combo: ')) {
      displayName = displayName.substring(7);
    }
    if (displayName.startsWith('Chain: ')) {
      displayName = displayName.substring(7);
    }

    // Filter out "Angle #" if we are showing the icon
    if (move.kaliAngle != null) {
      displayName = displayName.replaceAll(RegExp(r'Angle\s+\d+'), '').trim();
    }

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
            // Large Centered Kali Angle Icon
            if (move.kaliAngle != null)
              Center(
                child: Opacity(
                  opacity: 0.6,
                  child: KaliAngleIcon(
                    angle: move.kaliAngle!,
                    size: 140,
                    color: Colors.orangeAccent,
                    showCircle: true,
                    animated: true,
                  ),
                ),
              ),

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
            // Progress indicator
            Positioned(
              top: isRound ? 14 : 4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currentIndex + 1}/${widget.series.moves.length}',
                          style: TextStyle(
                            color: Colors.blueAccent.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (provider.autoAdvanceSec > 0) ...[
                          const SizedBox(width: 3),
                          Icon(
                            Icons.timer,
                            size: 10,
                            color: Colors.blueAccent.withValues(alpha: 0.9),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => setState(() => _mirrorMode = !_mirrorMode),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _mirrorMode
                            ? Colors.orangeAccent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _mirrorMode
                              ? Colors.orangeAccent.withValues(alpha: 0.6)
                              : Colors.white12,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '⇄',
                          style: TextStyle(
                            fontSize: 14,
                            color: _mirrorMode
                                ? Colors.orangeAccent
                                : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.only(
                top: isRound ? 30 : 18,
                bottom: isRound ? 20 : 8,
                left: 8,
                right: 8,
              ),
              child: Column(
                children: [
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
                              .map(
                                (a) => _buildActionBubble(
                                  a,
                                  baseFontSize,
                                  actions.length,
                                ),
                              )
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

// ──────────────────────────────────────────────
// WEAR OS WARMUP
// ──────────────────────────────────────────────

class WearWarmupScreen extends StatefulWidget {
  const WearWarmupScreen({super.key});

  @override
  State<WearWarmupScreen> createState() => _WearWarmupScreenState();
}

class _WearWarmupScreenState extends State<WearWarmupScreen> {
  // ── exercise data (mirrors warmup_screen.dart) ──
  static const Map<String, List<String>> _exerciseCategories = {
    'Squats': ['Squats (Classical)', 'Squats (Low)', 'Squats (Jump)', 'Squats (Beat)'],
    'Push-ups': ['Push-ups (Classical)', 'Push-ups (Diamond)', 'Push-ups (Wide)', 'Push-up 2026'],
    'Crunches': ['Crunches (Abs)', 'Crunches (Leg 90°)', 'Crunches (Leg 180°)', 'Ciseaux'],
    'Jumping Jacks': ['Jumping Jacks'],
    'Burpees': ['Burpees'],
    'Mountain Climbers': ['Mountain Climbers', 'Mountain Climbers Diagonal'],
    'Lunges': ['Lunges', 'Lunges (Beat)'],
  };

  // ── config ──
  final _durations = [5, 8, 10, 15, 20];
  final _works     = [20, 25, 30, 35, 40];
  final _rests     = [10, 15];
  int _durIdx  = 2; // 10 min
  int _workIdx = 0; // 20 s
  int _restIdx = 0; // 10 s
  late Set<String> _selectedCategories;

  // ── runtime ──
  bool _isRunning = false;
  bool _isPaused  = false;
  bool _isWork    = true;
  bool _finished  = false;
  int  _secondsRemaining = 0;
  int  _currentRound = 0;
  int  _totalRounds  = 0;
  List<String> _sequence = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(_exerciseCategories.keys);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _workDuration  => _works[_workIdx];
  int get _restDuration  => _rests[_restIdx];
  int get _totalMinutes  => _durations[_durIdx];

  void _buildSequence() {
    final pool = <String>[];
    for (final cat in _selectedCategories) {
      pool.addAll(_exerciseCategories[cat]!);
    }
    if (pool.isEmpty) return;

    final rng = math.Random();
    final totalSec = _totalMinutes * 60;
    final roundDur = _workDuration + _restDuration;
    _totalRounds = math.max(4, totalSec ~/ roundDur);

    _sequence = [];
    int lastIdx = -1;

    // Always start with a Jumping Jack or Squat if either category is selected
    final starters = <String>[
      if (_selectedCategories.contains('Jumping Jacks'))
        ..._exerciseCategories['Jumping Jacks']!,
      if (_selectedCategories.contains('Squats'))
        ..._exerciseCategories['Squats']!,
    ];
    if (starters.isNotEmpty) {
      final first = starters[rng.nextInt(starters.length)];
      _sequence.add(first);
      lastIdx = pool.indexOf(first);
    }

    for (int i = _sequence.length; i < _totalRounds; i++) {
      int idx;
      int tries = 0;
      do {
        idx = rng.nextInt(pool.length);
        tries++;
      } while (idx == lastIdx && pool.length > 1 && tries < 5);
      lastIdx = idx;
      _sequence.add(pool[idx]);
    }
  }

  void _start() {
    _buildSequence();
    if (_sequence.isEmpty) return;
    setState(() {
      _isRunning = true;
      _isPaused  = false;
      _isWork    = true;
      _finished  = false;
      _currentRound = 0;
      _secondsRemaining = _workDuration;
    });
    HapticFeedback.mediumImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_isPaused) return;
    setState(() {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
          HapticFeedback.selectionClick();
        }
      } else {
        _nextPeriod();
      }
    });
  }

  void _nextPeriod() {
    HapticFeedback.mediumImpact();
    if (_isWork) {
      _isWork = false;
      _secondsRemaining = _restDuration;
    } else {
      _currentRound++;
      if (_currentRound < _totalRounds) {
        _isWork = true;
        _secondsRemaining = _workDuration;
      } else {
        _timer?.cancel();
        _isRunning = false;
        _finished  = true;
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    HapticFeedback.lightImpact();
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused  = false;
      _finished  = false;
    });
  }

  // ── total progress (0..1) ──
  double get _totalProgress {
    final totalSec = _totalRounds * (_workDuration + _restDuration);
    final workElapsed = _isWork ? _workDuration - _secondsRemaining : _workDuration;
    final elapsed = _currentRound * (_workDuration + _restDuration)
        + (_isWork ? workElapsed : _workDuration + _restDuration - _secondsRemaining);
    return (elapsed / totalSec).clamp(0.0, 1.0);
  }

  // ── period progress (1 → 0 as time drains) ──
  double get _periodProgress {
    final limit = _isWork ? _workDuration : _restDuration;
    return (_secondsRemaining / limit).clamp(0.0, 1.0);
  }

  int get _totalRemainingSec {
    final totalSec = _totalRounds * (_workDuration + _restDuration);
    final workElapsed = _isWork ? _workDuration - _secondsRemaining : _workDuration;
    final elapsed = _currentRound * (_workDuration + _restDuration)
        + (_isWork ? workElapsed : _workDuration + _restDuration - _secondsRemaining);
    return math.max(0, totalSec - elapsed);
  }

  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildFinishedView();
    if (_isRunning) return _buildRunningView();
    return _buildSetupView();
  }

  // ── SETUP ────────────────────────────────────
  Widget _buildSetupView() {
    final isRound =
        MediaQuery.of(context).size.width == MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: isRound ? 36 : 16,
          horizontal: 10,
        ),
        child: Column(
          children: [
            const Text(
              'WARM UP',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // ── duration / work / rest ──
            _buildCycleRow('Duration', '${_durations[_durIdx]} min', () {
              setState(() => _durIdx = (_durIdx + 1) % _durations.length);
            }),
            const SizedBox(height: 4),
            _buildCycleRow('Work', '${_works[_workIdx]} s', () {
              setState(() => _workIdx = (_workIdx + 1) % _works.length);
            }),
            const SizedBox(height: 4),
            _buildCycleRow('Rest', '${_rests[_restIdx]} s', () {
              setState(() => _restIdx = (_restIdx + 1) % _rests.length);
            }),
            const SizedBox(height: 8),

            // ── category chips ──
            const Text(
              'EXERCISES',
              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: _exerciseCategories.keys.map((cat) {
                final on = _selectedCategories.contains(cat);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (on) {
                      _selectedCategories.remove(cat);
                    } else {
                      _selectedCategories.add(cat);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: on
                          ? Colors.green.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: on ? Colors.greenAccent : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 10,
                        color: on ? Colors.greenAccent : Colors.white38,
                        fontWeight: on ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // ── START ──
            GestureDetector(
              onTap: _selectedCategories.isEmpty ? null : _start,
              child: Container(
                width: 100,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedCategories.isEmpty
                      ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                        ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _selectedCategories.isEmpty
                      ? []
                      : [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 10)],
                ),
                child: const Text(
                  'START',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── RUNNING ──────────────────────────────────
  Widget _buildRunningView() {
    final color = _isPaused
        ? Colors.yellow
        : _isWork
            ? Colors.green
            : Colors.red;
    final phase = _isPaused ? 'PAUSED' : (_isWork ? 'WORK' : 'REST');
    final exercise = _sequence[_currentRound];
    final nextExercise = (!_isWork && _currentRound + 1 < _totalRounds)
        ? _sequence[_currentRound + 1]
        : null;
    final rem = _totalRemainingSec;
    final remStr =
        '${rem ~/ 60}:${(rem % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _togglePause,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── dual progress rings ──
            Positioned.fill(
              child: CustomPaint(
                painter: WarmupRingPainter(
                  totalProgress: _totalProgress,
                  periodProgress: _periodProgress,
                  periodColor: color,
                ),
              ),
            ),

            // ── content ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // round counter + total remaining
                  Text(
                    '${_currentRound + 1}/$_totalRounds  $remStr',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  // phase label
                  Text(
                    phase,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 2),
                  // exercise name (work) or next exercise (rest)
                  if (_isWork)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        exercise,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  else if (nextExercise != null) ...[
                    Text(
                      'Next',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        nextExercise,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 13),
                  const SizedBox(height: 4),
                  // countdown
                  Text(
                    '$_secondsRemaining',
                    style: TextStyle(
                        color: color,
                        fontSize: 38,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),

            // ── stop button ──
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _stop,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.stop, color: Colors.red, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FINISHED ─────────────────────────────────
  Widget _buildFinishedView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
              const SizedBox(height: 8),
              const Text(
                'DONE!',
                style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'TAP TO EXIT',
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WarmupRingPainter extends CustomPainter {
  final double totalProgress;   // 0..1 blue outer ring
  final double periodProgress;  // 1..0 colored inner ring
  final Color periodColor;

  const WarmupRingPainter({
    required this.totalProgress,
    required this.periodProgress,
    required this.periodColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const startAngle = -math.pi / 2;

    // ── outer ring (total progress, blue) ──
    final outerR = (size.shortestSide / 2) - 6;
    _drawArc(canvas, cx, cy, outerR, 10, Colors.white12, 2 * math.pi);
    _drawArc(canvas, cx, cy, outerR, 10, Colors.blue, totalProgress * 2 * math.pi);

    // ── inner ring (period countdown, color) ──
    final innerR = outerR - 14;
    _drawArc(canvas, cx, cy, innerR, 7, Colors.white12, 2 * math.pi);
    _drawArc(canvas, cx, cy, innerR, 7, periodColor, periodProgress * 2 * math.pi,
        startAngle: startAngle);
  }

  void _drawArc(Canvas canvas, double cx, double cy, double r, double stroke,
      Color color, double sweep,
      {double startAngle = -math.pi / 2}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WarmupRingPainter old) =>
      old.totalProgress != totalProgress ||
      old.periodProgress != periodProgress ||
      old.periodColor != periodColor;
}

// ──────────────────────────────────────────────

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
