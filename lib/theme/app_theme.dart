import 'package:flutter/material.dart';

import '../state/game_state.dart';

class AppTheme {
  AppTheme._();

  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFFDFDFB);
  static const Color blood = Color(0xFFB3001B);
  static const Color xpGreen = Color(0xFF8FCB5A);

  static const String fontFamily = 'MuriloFont';

  static String? get _activeFont =>
      GameState.instance.finalPhase ? null : fontFamily;

  static TextStyle marker(double size, {Color color = ink}) =>
      TextStyle(fontFamily: _activeFont, fontSize: size, color: color);

  static TextStyle hand(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.normal,
  }) => TextStyle(
    fontFamily: _activeFont,
    fontSize: size,
    color: color,
    fontWeight: weight,
  );

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      fontFamily: _activeFont,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blood,
        primary: ink,
        surface: paper,
      ),
    );
  }
}
