import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/sessions_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set Android-specific configurations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style for Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const PrinterApp());
}

class PrinterApp extends StatelessWidget {
  const PrinterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermal Printer',
      theme: _buildMaterial3Theme(),
      darkTheme: _buildMaterial3DarkTheme(),
      themeMode: ThemeMode.system, // Follows system theme
      home: const SessionsListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildMaterial3Theme() {
    // Modern Material 3 color scheme for thermal printer app
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2), // Modern blue for thermal printer app
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      
      // Material 3 Typography with custom brand font weights
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontWeight: FontWeight.w500),
      ),
      
      // Material 3 Shapes - more expressive rounded corners
      cardTheme: CardTheme(
        elevation: 2, // Reduced for Material 3 tonal elevation
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Larger radius for M3
        ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ),
      
      // Material 3 AppBar with surface tint
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0, // Material 3 uses tonal elevation
        scrolledUnderElevation: 3,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Material 3 Button themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Pill shape for M3
          ),
        ),
      ),
      
      // Material 3 FAB with larger corner radius
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  ThemeData _buildMaterial3DarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontWeight: FontWeight.w500),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}
