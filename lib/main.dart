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

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.red,
      brightness: Brightness.light,
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme({bool amoled = false}) {
    return ThemeData(
      primarySwatch: Colors.red,
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
    final themeMode = context.watch<SeriesProvider>().themeMode;

    ThemeMode mode;
    ThemeData theme;
    ThemeData darkTheme;

    switch (themeMode) {
      case JkdThemeMode.light:
        mode = ThemeMode.light;
        theme = _buildLightTheme();
        darkTheme = _buildDarkTheme();
        break;
      case JkdThemeMode.dark:
        mode = ThemeMode.dark;
        theme = _buildLightTheme();
        darkTheme = _buildDarkTheme();
        break;
      case JkdThemeMode.amoled:
        mode = ThemeMode.dark;
        theme = _buildLightTheme();
        darkTheme = _buildDarkTheme(amoled: true);
        break;
      case JkdThemeMode.system:
        mode = ThemeMode.system;
        theme = _buildLightTheme();
        darkTheme = _buildDarkTheme();
        break;
    }

    return MaterialApp(
      title: 'JKD',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: mode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
