import 'package:flutter/material.dart';

import 'game_tokens.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.light(
      primary: GameColors.coral,
      secondary: GameColors.coral,
      surface: GameColors.paper,
      error: GameColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: GameColors.ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GameColors.paper,
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: GameColors.ink,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: GameColors.ink,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: GameColors.ink,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: TextStyle(
          color: GameColors.ink,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: GameColors.ink,
          fontWeight: FontWeight.w900,
        ),
        bodyLarge: TextStyle(color: GameColors.ink),
        bodyMedium: TextStyle(color: GameColors.softInk),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: GameColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameRadii.large),
          side: const BorderSide(color: GameColors.cuteStroke),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GameColors.coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameRadii.pill),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: GameColors.ink,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: GameColors.ink,
          borderRadius: BorderRadius.all(Radius.circular(GameRadii.medium)),
        ),
        textStyle: TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: GameColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: GameColors.cuteStroke),
        ),
      ),
    );
  }
}
