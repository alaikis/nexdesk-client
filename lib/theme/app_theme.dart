import 'package:flutter/material.dart';

/// Wise 设计系统全局 Token
/// 
/// 所有颜色、间距、圆角、阴影、字体均通过此类定义，
/// 组件应通过 [WiseTheme.of] 或 [Theme.of(context).extension<WiseColors>()] 获取。
/// 
/// 使用方式：
/// ```dart
/// final wise = WiseTheme.of(context);
/// wise.primary        // 主色
/// wise.success        // 成功色
/// wise.spacing.lg     // 间距 16
/// wise.radius.lg      // 圆角 9
/// ```

// ═══════════════════════════════════════════════════
// 颜色 Token
// ═══════════════════════════════════════════════════

class WiseColorTokens {
  // 品牌色
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;

  // 功能色
  final Color success;
  final Color warning;
  final Color error;

  // 背景色
  final Color background;
  final Color backgroundSubtle;
  final Color surface;
  final Color card;

  // 文字色
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // 边框色
  final Color border;
  final Color borderStrong;

  // 在线状态色
  final Color online;

  const WiseColorTokens._({
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.background,
    required this.backgroundSubtle,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderStrong,
    required this.online,
  });

  /// Light Mode (TDesign)
  static const light = WiseColorTokens._(
    primary: Color(0xFF0052D9),
    primaryHover: Color(0xFF366EF4),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF00A870),
    warning: Color(0xFFE37318),
    error: Color(0xFFD54941),
    background: Color(0xFFF3F3F3),
    backgroundSubtle: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xE6000000), // rgba(0,0,0,.9)
    textSecondary: Color(0x99000000), // rgba(0,0,0,.6)
    textTertiary: Color(0x66000000), // rgba(0,0,0,.4)
    border: Color(0xFFE8E8E8),
    borderStrong: Color(0xFFDDDDDD),
    online: Color(0xFF00A870),
  );

  /// Dark Mode (TDesign)
  static const dark = WiseColorTokens._(
    primary: Color(0xFF69A1FF),
    primaryHover: Color(0xFF478DFF),
    onPrimary: Color(0xFF181818),
    success: Color(0xFF37BF8E),
    warning: Color(0xFFED8139),
    error: Color(0xFFFB6E77),
    background: Color(0xFF181818),
    backgroundSubtle: Color(0xFF242424),
    surface: Color(0xFF242424),
    card: Color(0xFF2C2C2C),
    textPrimary: Color(0xE6FFFFFF), // rgba(255,255,255,.9)
    textSecondary: Color(0x99FFFFFF), // rgba(255,255,255,.6)
    textTertiary: Color(0x66FFFFFF), // rgba(255,255,255,.4)
    border: Color(0xFF3A3A3A),
    borderStrong: Color(0xFF444444),
    online: Color(0xFF37BF8E),
  );

  WiseColorTokens copyWith({Color? primary, Color? primaryHover}) {
    return WiseColorTokens._(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      onPrimary: onPrimary,
      success: success,
      warning: warning,
      error: error,
      background: background,
      backgroundSubtle: backgroundSubtle,
      surface: surface,
      card: card,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      border: border,
      borderStrong: borderStrong,
      online: online,
    );
  }
}

// ═══════════════════════════════════════════════════
// 间距 Token
// ═══════════════════════════════════════════════════

class WiseSpacingTokens {
  final double xs, sm, md, lg, xl, xxl, xxxl;

  const WiseSpacingTokens._({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  static const instance = WiseSpacingTokens._(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    xxl: 24,
    xxxl: 32,
  );
}

// ═══════════════════════════════════════════════════
// 圆角 Token
// ═══════════════════════════════════════════════════

class WiseRadiusTokens {
  final double sm, def, medium, lg, xl, full;

  const WiseRadiusTokens._({
    required this.sm,
    required this.def,
    required this.medium,
    required this.lg,
    required this.xl,
    required this.full,
  });

  /// TDesign 旧名兼容：md 对应 medium
  double get md => medium;

  static const instance = WiseRadiusTokens._(
    sm: 2,
    def: 3,
    medium: 6,
    lg: 9,
    xl: 12,
    full: 999,
  );
}

// ═══════════════════════════════════════════════════
// 阴影 Token
// ═══════════════════════════════════════════════════

class WiseShadowTokens {
  final List<BoxShadow> sm, md, lg;

  const WiseShadowTokens._({
    this.sm = const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x14000000), blurRadius: 5, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x1F000000), blurRadius: 4, spreadRadius: -1, offset: Offset(0, 2)),
    ],
    this.md = const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 14, spreadRadius: 2, offset: Offset(0, 3)),
      BoxShadow(color: Color(0x0F000000), blurRadius: 10, spreadRadius: 1, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x1A000000), blurRadius: 5, spreadRadius: -3, offset: Offset(0, 5)),
    ],
    this.lg = const [
      BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 5)),
    ],
  });

  /// TDesign Light shadows (shadow-1/2/3)
  static const light = WiseShadowTokens._();

  /// TDesign Dark shadows（提升不透明度）
  static const dark = WiseShadowTokens._(
    sm: [
      BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x40000000), blurRadius: 5, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x4D000000), blurRadius: 4, spreadRadius: -1, offset: Offset(0, 2)),
    ],
    md: [
      BoxShadow(color: Color(0x33000000), blurRadius: 14, spreadRadius: 2, offset: Offset(0, 3)),
      BoxShadow(color: Color(0x40000000), blurRadius: 10, spreadRadius: 1, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x4D000000), blurRadius: 5, spreadRadius: -3, offset: Offset(0, 5)),
    ],
    lg: [
      BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 5)),
    ],
  );
}

// ═══════════════════════════════════════════════════
// 字体 Token
// ═══════════════════════════════════════════════════

class WiseTypographyTokens {
  static const fontFamily = 'PingFang SC, Microsoft YaHei, -apple-system, Segoe UI, Roboto, sans-serif';

  // 字号
  static const double displayLarge = 34;
  static const double displayMedium = 28;
  static const double displaySmall = 22;
  static const double headlineLarge = 20;
  static const double headlineMedium = 17;
  static const double headlineSmall = 15;
  static const double bodyLarge = 15;
  static const double bodyMedium = 13;
  static const double bodySmall = 12;
  static const double labelLarge = 15;
  static const double labelMedium = 13;
  static const double labelSmall = 11;

  static const String monoFamily = 'monospace';

  static TextTheme lightTextTheme(WiseColorTokens c) {
    return TextTheme(
      displayLarge: TextStyle(color: c.textPrimary, fontSize: displayLarge, fontWeight: FontWeight.w600, height: (displayLarge + 8) / displayLarge),
      displayMedium: TextStyle(color: c.textPrimary, fontSize: displayMedium, fontWeight: FontWeight.w600, height: (displayMedium + 8) / displayMedium),
      displaySmall: TextStyle(color: c.textPrimary, fontSize: displaySmall, fontWeight: FontWeight.w600, height: (displaySmall + 8) / displaySmall),
      headlineLarge: TextStyle(color: c.textPrimary, fontSize: headlineLarge, fontWeight: FontWeight.w600, height: (headlineLarge + 8) / headlineLarge),
      headlineMedium: TextStyle(color: c.textPrimary, fontSize: headlineMedium, fontWeight: FontWeight.w600, height: (headlineMedium + 8) / headlineMedium),
      headlineSmall: TextStyle(color: c.textPrimary, fontSize: headlineSmall, fontWeight: FontWeight.w600, height: (headlineSmall + 8) / headlineSmall),
      bodyLarge: TextStyle(color: c.textPrimary, fontSize: bodyLarge, height: (bodyLarge + 8) / bodyLarge),
      bodyMedium: TextStyle(color: c.textSecondary, fontSize: bodyMedium, height: (bodyMedium + 8) / bodyMedium),
      bodySmall: TextStyle(color: c.textTertiary, fontSize: bodySmall, height: (bodySmall + 8) / bodySmall),
      labelLarge: TextStyle(color: c.textPrimary, fontSize: labelLarge, fontWeight: FontWeight.w600, height: (labelLarge + 8) / labelLarge),
      labelMedium: TextStyle(color: c.textSecondary, fontSize: labelMedium, fontWeight: FontWeight.w600, height: (labelMedium + 8) / labelMedium),
      labelSmall: TextStyle(color: c.textTertiary, fontSize: labelSmall, fontWeight: FontWeight.w600, height: (labelSmall + 8) / labelSmall),
    );
  }

  static TextTheme darkTextTheme(WiseColorTokens c) {
    return lightTextTheme(c);
  }

  static TextStyle mono(Color color, {double size = 13}) {
    return TextStyle(color: color, fontFamily: monoFamily, fontSize: size);
  }
}

// ═══════════════════════════════════════════════════
// 动效 Token
// ═══════════════════════════════════════════════════

class WiseMotionTokens {
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 150);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;
}

// ═══════════════════════════════════════════════════
// WiseTheme — 统一入口
// ═══════════════════════════════════════════════════

class WiseTheme extends ThemeExtension<WiseTheme> {
  final WiseColorTokens colors;
  final WiseSpacingTokens spacing;
  final WiseRadiusTokens radius;
  final WiseShadowTokens shadows;

  const WiseTheme._({
    required this.colors,
    this.spacing = WiseSpacingTokens.instance,
    this.radius = WiseRadiusTokens.instance,
    required this.shadows,
  });

  /// Light Theme
  static const light = WiseTheme._(
    colors: WiseColorTokens.light,
    shadows: WiseShadowTokens.light,
  );

  /// Dark Theme
  static const dark = WiseTheme._(
    colors: WiseColorTokens.dark,
    shadows: WiseShadowTokens.dark,
  );

  /// 从 BuildContext 获取 WiseTheme
  static WiseTheme of(BuildContext context) {
    return Theme.of(context).extension<WiseTheme>() ?? 
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  // 颜色快捷访问
  Color get primary => colors.primary;
  Color get primaryHover => colors.primaryHover;
  Color get onPrimary => colors.onPrimary;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get error => colors.error;
  Color get background => colors.background;
  Color get backgroundSubtle => colors.backgroundSubtle;
  Color get surface => colors.surface;
  Color get card => colors.card;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textTertiary => colors.textTertiary;
  Color get border => colors.border;
  Color get borderStrong => colors.borderStrong;
  Color get online => colors.online;

  // 主色带透明度
  Color get primarySoft => colors.primary.withValues(alpha: 0.08);
  Color get primaryTint => colors.primary.withValues(alpha: 0.12);
  Color get successSoft => colors.success.withValues(alpha: 0.08);
  Color get warningSoft => colors.warning.withValues(alpha: 0.08);
  Color get errorSoft => colors.error.withValues(alpha: 0.08);

  @override
  WiseTheme copyWith({
    WiseColorTokens? colors,
    WiseSpacingTokens? spacing,
    WiseRadiusTokens? radius,
    WiseShadowTokens? shadows,
  }) {
    return WiseTheme._(
      colors: colors ?? this.colors,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  WiseTheme lerp(WiseTheme? other, double t) {
    if (other == null) return this;
    return WiseTheme._(
      colors: WiseColorTokens._(
        primary: Color.lerp(colors.primary, other.colors.primary, t)!,
        primaryHover: Color.lerp(colors.primaryHover, other.colors.primaryHover, t)!,
        onPrimary: Color.lerp(colors.onPrimary, other.colors.onPrimary, t)!,
        success: Color.lerp(colors.success, other.colors.success, t)!,
        warning: Color.lerp(colors.warning, other.colors.warning, t)!,
        error: Color.lerp(colors.error, other.colors.error, t)!,
        background: Color.lerp(colors.background, other.colors.background, t)!,
        backgroundSubtle: Color.lerp(colors.backgroundSubtle, other.colors.backgroundSubtle, t)!,
        surface: Color.lerp(colors.surface, other.colors.surface, t)!,
        card: Color.lerp(colors.card, other.colors.card, t)!,
        textPrimary: Color.lerp(colors.textPrimary, other.colors.textPrimary, t)!,
        textSecondary: Color.lerp(colors.textSecondary, other.colors.textSecondary, t)!,
        textTertiary: Color.lerp(colors.textTertiary, other.colors.textTertiary, t)!,
        border: Color.lerp(colors.border, other.colors.border, t)!,
        borderStrong: Color.lerp(colors.borderStrong, other.colors.borderStrong, t)!,
        online: Color.lerp(colors.online, other.colors.online, t)!,
      ),
      shadows: shadows,
    );
  }
}

// ═══════════════════════════════════════════════════
// NexColors — 兼容旧 API（映射到 WiseColorTokens）
// ═══════════════════════════════════════════════════

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

  // 新增字段
  final Color success;
  final Color warning;
  final Color primaryHover;
  final Color borderStrong;
  final Color backgroundSubtle;

  const NexColors._({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.online,
    required this.error,
    required this.success,
    required this.warning,
    required this.primaryHover,
    required this.borderStrong,
    required this.backgroundSubtle,
  });

  const NexColors.light()
      : primary = const Color(0xFF0052D9),
        onPrimary = const Color(0xFFFFFFFF),
        background = const Color(0xFFF3F3F3),
        surface = const Color(0xFFFFFFFF),
        card = const Color(0xFFFFFFFF),
        border = const Color(0xFFE8E8E8),
        textPrimary = const Color(0xE6000000),
        textSecondary = const Color(0x99000000),
        textTertiary = const Color(0x66000000),
        online = const Color(0xFF00A870),
        error = const Color(0xFFD54941),
        success = const Color(0xFF00A870),
        warning = const Color(0xFFE37318),
        primaryHover = const Color(0xFF366EF4),
        borderStrong = const Color(0xFFDDDDDD),
        backgroundSubtle = const Color(0xFFF5F5F5);

  const NexColors.dark()
      : primary = const Color(0xFF69A1FF),
        onPrimary = const Color(0xFF181818),
        background = const Color(0xFF181818),
        surface = const Color(0xFF242424),
        card = const Color(0xFF2C2C2C),
        border = const Color(0xFF3A3A3A),
        textPrimary = const Color(0xE6FFFFFF),
        textSecondary = const Color(0x99FFFFFF),
        textTertiary = const Color(0x66FFFFFF),
        online = const Color(0xFF37BF8E),
        error = const Color(0xFFFB6E77),
        success = const Color(0xFF37BF8E),
        warning = const Color(0xFFED8139),
        primaryHover = const Color(0xFF478DFF),
        borderStrong = const Color(0xFF444444),
        backgroundSubtle = const Color(0xFF242424);

  factory NexColors.fromWise(WiseColorTokens t) {
    return NexColors._(
      primary: t.primary,
      onPrimary: t.onPrimary,
      background: t.background,
      surface: t.surface,
      card: t.card,
      border: t.border,
      textPrimary: t.textPrimary,
      textSecondary: t.textSecondary,
      textTertiary: t.textTertiary,
      online: t.online,
      error: t.error,
      success: t.success,
      warning: t.warning,
      primaryHover: t.primaryHover,
      borderStrong: t.borderStrong,
      backgroundSubtle: t.backgroundSubtle,
    );
  }

  ThemeData toTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? const NexColors.dark() : const NexColors.light();
    final wiseTheme = isDark ? WiseTheme.dark : WiseTheme.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.success,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.border,
        outlineVariant: colors.border,
      ),
      scaffoldBackgroundColor: colors.background,
      extensions: [wiseTheme],
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
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: isDark ? WiseTypographyTokens.darkTextTheme(WiseColorTokens.dark) : WiseTypographyTokens.lightTextTheme(WiseColorTokens.light),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surface,
          disabledForegroundColor: colors.textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.textTertiary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.textTertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.sm)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexRadius.md),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexRadius.md),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexRadius.md),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 15),
        errorStyle: TextStyle(color: colors.error, fontSize: 12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return colors.textTertiary;
          if (states.contains(WidgetState.selected)) return colors.onPrimary;
          return colors.card;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return colors.surface;
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.border;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return WidgetStateColor.transparent;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return colors.textTertiary;
          if (states.contains(WidgetState.selected)) return colors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: colors.borderStrong, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return colors.textTertiary;
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.borderStrong;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surface,
        linearMinHeight: 4,
        borderRadius: BorderRadius.all(Radius.circular(NexRadius.full)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.surface,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        valueIndicatorColor: colors.primary,
        valueIndicatorTextStyle: TextStyle(color: colors.onPrimary, fontSize: 13),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        dividerColor: colors.border,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(color: colors.textPrimary, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: colors.primary, fontSize: 13),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.full)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexRadius.lg),
        ),
        titleTextStyle: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: colors.textSecondary, fontSize: 15),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(NexRadius.lg)),
        ),
        showDragHandle: true,
        dragHandleColor: colors.borderStrong,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.card,
        contentTextStyle: TextStyle(color: colors.textPrimary, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: BorderRadius.circular(NexRadius.sm),
        ),
        textStyle: TextStyle(
          color: isDark ? colors.background : colors.card,
          fontSize: 13,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        titleTextStyle: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.card,
        indicatorColor: colors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: colors.textTertiary, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary, size: 24);
          }
          return IconThemeData(color: colors.textSecondary, size: 24);
        }),
        height: 64,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(colors.borderStrong),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(NexRadius.full),
        thickness: WidgetStateProperty.all(6),
        thumbVisibility: WidgetStateProperty.all(false),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 旧 API 兼容（保持向后兼容）
// ═══════════════════════════════════════════════════

extension NexTheme on ThemeData {
  static ThemeData light() => const NexColors.light().toTheme(Brightness.light);
  static ThemeData dark() => const NexColors.dark().toTheme(Brightness.dark);
}

class NexTextStyles {
  NexTextStyles._();

  static TextStyle mono({required Color color}) => TextStyle(color: color, fontFamily: WiseTypographyTokens.monoFamily, fontSize: 13);

  static TextTheme light() {
    return WiseTypographyTokens.lightTextTheme(WiseColorTokens.light);
  }

  static TextTheme dark() {
    return WiseTypographyTokens.darkTextTheme(WiseColorTokens.dark);
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
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 16.0;
  static const full = 9999.0;
}

// ═══════════════════════════════════════════════════
// WiseColors — 静态常量兼容层（标记为已废弃，推荐用 WiseTheme.of）
// ═══════════════════════════════════════════════════

@Deprecated('Use WiseTheme.of(context) instead. This is kept for backward compatibility.')
class WiseColors {
  WiseColors._();

  static const Color primaryLight = Color(0xFF0052D9);
  static const Color primaryHoverLight = Color(0xFF366EF4);
  static const Color successLight = Color(0xFF00A870);
  static const Color warningLight = Color(0xFFE37318);
  static const Color destructiveLight = Color(0xFFD54941);
  static const Color backgroundLight = Color(0xFFF3F3F3);
  static const Color backgroundSubtleLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xE6000000);
  static const Color textSecondaryLight = Color(0x99000000);
  static const Color textTertiaryLight = Color(0x66000000);
  static const Color borderLight = Color(0xFFE8E8E8);
  static const Color borderStrongLight = Color(0xFFDDDDDD);

  static const Color primaryDark = Color(0xFF69A1FF);
  static const Color primaryHoverDark = Color(0xFF478DFF);
  static const Color successDark = Color(0xFF37BF8E);
  static const Color warningDark = Color(0xFFED8139);
  static const Color destructiveDark = Color(0xFFFB6E77);
  static const Color backgroundDark = Color(0xFF181818);
  static const Color backgroundSubtleDark = Color(0xFF242424);
  static const Color surfaceDark = Color(0xFF242424);
  static const Color textPrimaryDark = Color(0xE6FFFFFF);
  static const Color textSecondaryDark = Color(0x99FFFFFF);
  static const Color textTertiaryDark = Color(0x66FFFFFF);
  static const Color borderDark = Color(0xFF3A3A3A);
  static const Color borderStrongDark = Color(0xFF444444);
}

@Deprecated('Use WiseTheme.of(context).shadows instead.')
class WiseShadows {
  WiseShadows._();

  static List<BoxShadow> get sm => WiseShadowTokens.light.sm;
  static List<BoxShadow> get md => WiseShadowTokens.light.md;
  static List<BoxShadow> get lg => WiseShadowTokens.light.lg;
}