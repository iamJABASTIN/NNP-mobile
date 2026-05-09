import 'package:flutter/material.dart';

/// Neo-brutalist design tokens matching the web admin dashboard.
class AppColors {
  static const Color primaryYellow = Color(0xFFF2CA50);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAFAFA);
  static const Color textMuted = Color(0x66000000); // black/40
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
}

/// Common decoration constants for the brutal design system.
class BrutalDecorations {
  static const double borderWidth = 3.0;

  static BoxDecoration card = BoxDecoration(
    color: AppColors.white,
    border: Border.all(color: AppColors.black, width: borderWidth),
    boxShadow: const [
      BoxShadow(
        color: AppColors.black,
        offset: Offset(4, 4),
        blurRadius: 0,
      ),
    ],
  );

  static BoxDecoration cardNoShadow = BoxDecoration(
    color: AppColors.white,
    border: Border.all(color: AppColors.black, width: borderWidth),
  );

  static BoxDecoration cardYellowShadow = BoxDecoration(
    color: AppColors.black,
    border: Border.all(color: AppColors.black, width: borderWidth),
    boxShadow: const [
      BoxShadow(
        color: AppColors.primaryYellow,
        offset: Offset(4, 4),
        blurRadius: 0,
      ),
    ],
  );

  static BoxDecoration yellowCard = BoxDecoration(
    color: AppColors.primaryYellow,
    border: Border.all(color: AppColors.black, width: borderWidth),
    boxShadow: const [
      BoxShadow(
        color: AppColors.black,
        offset: Offset(4, 4),
        blurRadius: 0,
      ),
    ],
  );
}

/// Brutalist text styles — bold, uppercase, tight tracking.
class BrutalText {
  static const TextStyle heading = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 24,
    letterSpacing: -1.0,
    color: AppColors.black,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle subheading = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 14,
    letterSpacing: 2.0,
    color: AppColors.black,
  );

  static const TextStyle label = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 10,
    letterSpacing: 3.0,
    color: AppColors.textMuted,
  );

  static const TextStyle body = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 13,
    color: AppColors.black,
  );

  static const TextStyle price = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 14,
    fontStyle: FontStyle.italic,
    color: AppColors.black,
  );

  static const TextStyle bigPrice = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 32,
    fontStyle: FontStyle.italic,
    letterSpacing: -1.5,
    color: AppColors.white,
  );

  static const TextStyle caption = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 10,
    fontStyle: FontStyle.italic,
    color: AppColors.textMuted,
  );
}

/// App-wide Material theme built on top of our brutalist tokens.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryYellow,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 16,
        letterSpacing: 3.0,
        color: AppColors.white,
      ),
    ),
    fontFamily: 'Roboto',
  );
}
