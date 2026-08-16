import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0F172A);
  static const Color panel = Color(0xFF111C33);
  static const Color panelLight = Color(0xFF16223C);
  static const Color accent = Color(0xFF60A5FA);
  static const Color mutedText = Color(0xFF94A3B8);
  static const Color successText = Color(0xFF86EFAC);
  static const Color dangerText = Color(0xFFFECACA);
  static const Color dangerSurface = Color(0xFF3A1F2A);
  static const Color border = Color(0x1AFFFFFF);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.panel,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panelLight,
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.accent),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}
