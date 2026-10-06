import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class OceanThemeExtension extends ThemeExtension<OceanThemeExtension> {
  final Color blueTop;
  final Color blueBottom;
  final Color cyan;
  final Color cyanDark;
  final Color surface;
  final Color onCyan;
  final Color text;
  final Color textSecondary;
  final Color redTop;
  final Color redBottom;

  const OceanThemeExtension({
    required this.blueTop,
    required this.blueBottom,
    required this.cyan,
    required this.cyanDark,
    required this.surface,
    required this.onCyan,
    required this.text,
    required this.textSecondary,
    required this.redTop,
    required this.redBottom,
  });

  static const OceanThemeExtension defaultTokens = OceanThemeExtension(
    blueTop: Color(0xFF03112B),
    blueBottom: Color(0xFF0B3A82),
    cyan: Color(0xFF00E5FF),
    cyanDark: Color(0xFF00B8D4),
    surface: Color(0xFF0B2250),
    onCyan: Color(0xFF001018),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD6EEFF),
    redTop: Color(0xFF9E0F24),
    redBottom: Color(0xFF2E040C),
  );

  static OceanThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<OceanThemeExtension>() ?? defaultTokens;
  }

  @override
  OceanThemeExtension copyWith({
    Color? blueTop,
    Color? blueBottom,
    Color? cyan,
    Color? cyanDark,
    Color? surface,
    Color? onCyan,
    Color? text,
    Color? textSecondary,
    Color? redTop,
    Color? redBottom,
  }) {
    return OceanThemeExtension(
      blueTop: blueTop ?? this.blueTop,
      blueBottom: blueBottom ?? this.blueBottom,
      cyan: cyan ?? this.cyan,
      cyanDark: cyanDark ?? this.cyanDark,
      surface: surface ?? this.surface,
      onCyan: onCyan ?? this.onCyan,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      redTop: redTop ?? this.redTop,
      redBottom: redBottom ?? this.redBottom,
    );
  }

  @override
  OceanThemeExtension lerp(ThemeExtension<OceanThemeExtension>? other, double t) {
    if (other is! OceanThemeExtension) return this;
    return OceanThemeExtension(
      blueTop: Color.lerp(blueTop, other.blueTop, t)!,
      blueBottom: Color.lerp(blueBottom, other.blueBottom, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      cyanDark: Color.lerp(cyanDark, other.cyanDark, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onCyan: Color.lerp(onCyan, other.onCyan, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      redTop: Color.lerp(redTop, other.redTop, t)!,
      redBottom: Color.lerp(redBottom, other.redBottom, t)!,
    );
  }
}

class AppTheme {
  static const tokens = OceanThemeExtension.defaultTokens;

  static ThemeData get darkTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: tokens.cyan,
      brightness: Brightness.dark,
      surface: tokens.surface,
      onSurface: tokens.text,
      primary: tokens.cyan,
      onPrimary: tokens.onCyan,
      secondary: tokens.cyanDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: baseColorScheme,
      extensions: const [tokens],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: tokens.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: tokens.text,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: tokens.text,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: tokens.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: tokens.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: tokens.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: tokens.text,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.cyan,
          foregroundColor: tokens.onCyan,
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.cyan, width: 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.cyan,
          foregroundColor: tokens.onCyan,
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.cyan, width: 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.text,
          minimumSize: const Size(56, 56),
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        labelStyle: TextStyle(
          color: tokens.text,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.textSecondary.withValues(alpha: 0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.cyan, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          side: BorderSide(color: Colors.white24, width: 2),
        ),
      ),
    );
  }
}
