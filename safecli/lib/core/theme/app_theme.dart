import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Configuration
  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: Color.fromARGB(255, 29, 103, 163), // Strong Blue
      primaryContainer: Color(0xFF1976D2),
      secondary: Color(0xFF42A5F5), // Balanced Blue
      secondaryContainer: Color(0xFFE3F2FD),
      surface: Colors.white,
      error: Color(0xFFD32F2F),
      tertiary: Color(0xFF0A4779), // Accent Blue 
      tertiaryContainer: Color(0xFF90CAF9),
      surfaceContainerHighest: Color(0xFFF5F7FA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF101820),
      onSurfaceVariant: Color(0xFF546E7A),
      outline: Color(0xFFCFD8DC),
    );

    return _buildTheme(colorScheme, const Color(0xFFF8FAFC), Brightness.light);
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: Color.fromARGB(255, 29, 103, 163), // Soft Accessible Blue
      primaryContainer: Color(0xFF1976D2),
      secondary: Color(0xFF42A5F5), // Balanced Blue
      secondaryContainer: Color(0xFF0D47A1),
      surface: Color(0xFF101B2B), // Deep Navy
      error: Color(0xFFEF5350),
      tertiary: Color.fromARGB(255, 26, 123, 202), 
      tertiaryContainer: Color(0xFF0A2440), 
      surfaceContainerHighest: Color(0xFF1A283C),
      onPrimary: Color.fromARGB(255, 255, 255, 255),
      onSecondary: Color(0xFF0B131D),
      onTertiary: Colors.white,
      onSurface: Color(0xFFECEFF1),
      onSurfaceVariant: Color(0xFFB0BEC5),
      outline: Color(0xFF455A64),
    );

    return _buildTheme(colorScheme, const Color(0xFF0B131D), Brightness.dark); // Dark Slate tone
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Color scaffoldBackground, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      primaryColor: colorScheme.primary,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      shadowColor: brightness == Brightness.dark 
          ? Colors.black.withValues(alpha: 0.5) 
          : Colors.black.withValues(alpha: 0.1),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: brightness == Brightness.dark ? 2 : 2,
        shadowColor: brightness == Brightness.dark 
            ? Colors.black.withValues(alpha: 0.5) 
            : Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: brightness == Brightness.dark ? 4 : 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.primary,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        bodyLarge: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        bodySmall: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
