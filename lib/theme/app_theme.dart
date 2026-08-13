import 'package:flutter/material.dart';

class NexColors {
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color online;
  final Color offline;
  final Color error;

  const NexColors.light()
      : primary = const Color(0xFF007AFF),
        onPrimary = Colors.white,
        background = const Color(0xFFF5F5F7),
        surface = const Color(0xFFF5F5F7),
        card = Colors.white,
        border = const Color(0xFFE5E5EA),
        textPrimary = const Color(0xFF1D1D1F),
        textSecondary = const Color(0xFF6E6E73),
        textTertiary = const Color(0xFF8E8E93),
        online = const Color(0xFF34C759),
        offline = const Color(0xFF8E8E93),
        error = const Color(0xFFFF3B30);

  const NexColors.dark()
      : primary = const Color(0xFF0A84FF),
        onPrimary = Colors.white,
        background = const Color(0xFF000000),
        surface = const Color(0xFF000000),
        card = const Color(0xFF1C1C1E),
        border = const Color(0xFF38383A),
        textPrimary = const Color(0xFFF5F5F7),
        textSecondary = const Color(0xFFEBEBF5),
        textTertiary = const Color(0xFF8E8E93),
        online = const Color(0xFF30D158),
        offline = const Color(0xFF8E8E93),
        error = const Color(0xFFFF453A);

  ThemeData toTheme(Brightness brightness) {
    final colors = brightness == Brightness.dark ? const NexColors.dark() : const NexColors.light();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        surface: colors.surface,
        background: colors.background,
        error: colors.error,
      ),
      scaffoldBackgroundColor: colors.background,
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: brightness == Brightness.dark ? NexTextStyles.dark() : NexTextStyles.light(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

extension NexTheme on ThemeData {
  static ThemeData light() => NexColors.light().toTheme(Brightness.light);
  static ThemeData dark() => NexColors.dark().toTheme(Brightness.dark);
}

class NexTextStyles {
  NexTextStyles._();

  static TextTheme light() {
    final colors = NexColors.light();
    return TextTheme(
      headlineLarge: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.4),
      bodyMedium: TextStyle(color: colors.textSecondary, fontSize: 13),
    );
  }

  static TextTheme dark() {
    final colors = NexColors.dark();
    return TextTheme(
      headlineLarge: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.4),
      bodyMedium: TextStyle(color: colors.textSecondary, fontSize: 13),
    );
  }
}
