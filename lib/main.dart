import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/series_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => SeriesProvider()..loadSeries(),
      child: const JkdApp(),
    ),
  );
}

class JkdApp extends StatelessWidget {
  const JkdApp({super.key});

  ThemeData _buildLightTheme(Color seedColor) {
    return ThemeData(
      colorSchemeSeed: seedColor,
      brightness: Brightness.light,
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme(Color seedColor, {bool amoled = false}) {
    return ThemeData(
      colorSchemeSeed: seedColor,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: amoled ? Colors.black : null,
      appBarTheme: amoled
          ? const AppBarTheme(backgroundColor: Colors.black)
          : null,
      cardTheme: amoled ? const CardThemeData(color: Color(0xFF121212)) : null,
      bottomSheetTheme: amoled
          ? const BottomSheetThemeData(backgroundColor: Colors.black)
          : null,
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeriesProvider>();
    final themeMode = provider.themeMode;
    final seedColor = provider.themeColor;

    ThemeMode mode;
    ThemeData theme;
    ThemeData darkTheme;

    switch (themeMode) {
      case JkdThemeMode.light:
        mode = ThemeMode.light;
        theme = _buildLightTheme(seedColor);
        darkTheme = _buildDarkTheme(seedColor);
        break;
      case JkdThemeMode.dark:
        mode = ThemeMode.dark;
        theme = _buildLightTheme(seedColor);
        darkTheme = _buildDarkTheme(seedColor);
        break;
      case JkdThemeMode.amoled:
        mode = ThemeMode.dark;
        theme = _buildLightTheme(seedColor);
        darkTheme = _buildDarkTheme(seedColor, amoled: true);
        break;
      case JkdThemeMode.system:
        mode = ThemeMode.system;
        theme = _buildLightTheme(seedColor);
        darkTheme = _buildDarkTheme(seedColor);
        break;
    }

    return MaterialApp(
      title: 'JKD',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: mode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(provider.fontSizeScale)),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
