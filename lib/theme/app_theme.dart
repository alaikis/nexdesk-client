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
  final Color error;

  const NexColors.light()
      : primary = const Color(0xFF007AFF),
        onPrimary = Colors.white,
        background = const Color(0xFFFFFFFF),
        surface = const Color(0xFFF2F2F7),
        card = Colors.white,
        border = const Color(0xFFE5E5EA),
        textPrimary = const Color(0xFF1D1D1F),
        textSecondary = const Color(0xFF6E6E73),
        textTertiary = const Color(0xFFAEAEB2),
        online = const Color(0xFF34C759),
        error = const Color(0xFFFF3B30);

  const NexColors.dark()
      : primary = const Color(0xFF0A84FF),
        onPrimary = Colors.white,
        background = const Color(0xFF000000),
        surface = const Color(0xFF1C1C1E),
        card = const Color(0xFF1C1C1E),
        border = const Color(0xFF38383A),
        textPrimary = const Color(0xFFFFFFFF),
        textSecondary = const Color(0xFF98989D),
        textTertiary = const Color(0xFF636366),
        online = const Color(0xFF30D158),
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
        error: colors.error,
      ),
      scaffoldBackgroundColor: colors.background,
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexRadius.lg),
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
          padding: EdgeInsets.symmetric(horizontal: NexSpacing.xl, vertical: NexSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(NexRadius.md), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NexRadius.md), borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NexRadius.md), borderSide: BorderSide(color: colors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NexRadius.md), borderSide: BorderSide(color: colors.error)),
        contentPadding: EdgeInsets.symmetric(horizontal: NexSpacing.md, vertical: NexSpacing.md),
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

  static TextStyle mono({required Color color}) => TextStyle(color: color, fontFamily: 'monospace', fontSize: 13);

  static TextTheme light() {
    final colors = NexColors.light();
    return TextTheme(
      headlineLarge: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(color: colors.textSecondary, fontSize: 13),
      labelSmall: TextStyle(color: colors.textTertiary, fontSize: 12),
    );
  }

  static TextTheme dark() {
    final colors = NexColors.dark();
    return TextTheme(
      headlineLarge: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(color: colors.textSecondary, fontSize: 13),
      labelSmall: TextStyle(color: colors.textTertiary, fontSize: 12),
    );
  }
}

class NexSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class NexRadius {
  static const sm = 8.0;   // 按钮、小卡片
  static const md = 12.0;  // 输入框、中卡片
  static const lg = 16.0;  // 大卡片、弹窗
  static const xl = 16.0;
  static const full = 9999.0; // 胶囊按钮、头像
}

class WiseColors {
  WiseColors._();

  // Light Mode
  static const Color primaryLight = Color(0xFF007AFF);
  static const Color primaryHoverLight = Color(0xFF0066CC);
  static const Color successLight = Color(0xFF34C759);
  static const Color warningLight = Color(0xFFFF9500);
  static const Color destructiveLight = Color(0xFFFF3B30);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundSubtleLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFF2F2F7);
  static const Color textPrimaryLight = Color(0xFF1D1D1F);
  static const Color textSecondaryLight = Color(0xFF6E6E73);
  static const Color textTertiaryLight = Color(0xFFAEAEB2);
  static const Color borderLight = Color(0xFFE5E5EA);
  static const Color borderStrongLight = Color(0xFFC7C7CC);

  // Dark Mode
  static const Color primaryDark = Color(0xFF0A84FF);
  static const Color primaryHoverDark = Color(0xFF3399FF);
  static const Color successDark = Color(0xFF30D158);
  static const Color warningDark = Color(0xFFFF9F0A);
  static const Color destructiveDark = Color(0xFFFF453A);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color backgroundSubtleDark = Color(0xFF1C1C1E);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF98989D);
  static const Color textTertiaryDark = Color(0xFF636366);
  static const Color borderDark = Color(0xFF38383A);
  static const Color borderStrongDark = Color(0xFF48484A);
}

class WiseShadows {
  WiseShadows._();

  static List<BoxShadow> get sm => [
    const BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> get md => [
    const BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> get lg => [
    const BoxShadow(color: Color(0x1F000000), blurRadius: 40, offset: Offset(0, 12)),
  ];
}
