import 'package:flutter/material.dart';

import 'game_tokens.dart';

class GameVisualTheme {
  const GameVisualTheme({
    required this.backgroundGradient,
    required this.hudGradient,
    required this.dockGradient,
    required this.brandIcon,
    required this.brandAccent,
    required this.panelGradient,
    required this.modalAccent,
  });

  final Gradient backgroundGradient;
  final Gradient hudGradient;
  final Gradient dockGradient;
  final IconData brandIcon;
  final Color brandAccent;
  final Gradient panelGradient;
  final Color modalAccent;

  static const current = GameVisualTheme(
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        GameColors.ivory,
        GameColors.oat,
        GameColors.rosyBeige,
        GameColors.sand,
      ],
    ),
    hudGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [GameColors.oat, GameColors.rosyBeige, GameColors.ivory],
    ),
    dockGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [GameColors.oat, GameColors.ivory, GameColors.rosyBeige],
    ),
    brandIcon: Icons.favorite_rounded,
    brandAccent: GameColors.rose,
    panelGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [GameColors.oat, GameColors.ivory, GameColors.rosyBeige],
    ),
    modalAccent: GameColors.rose,
  );
}

class CharacterVisualTheme {
  const CharacterVisualTheme({
    required this.id,
    required this.sceneGradient,
    required this.sceneAccent,
    required this.sceneAccentAlt,
    required this.relationshipAccent,
    required this.relationshipAlt,
    required this.speechGradient,
    required this.speechBorder,
    required this.glow,
  });

  final String id;
  final Gradient sceneGradient;
  final Color sceneAccent;
  final Color sceneAccentAlt;
  final Color relationshipAccent;
  final Color relationshipAlt;
  final Gradient speechGradient;
  final Color speechBorder;
  final Color glow;
}

abstract final class RyomiVisualTheme {
  static const data = CharacterVisualTheme(
    id: 'roxanne',
    sceneGradient: RadialGradient(
      center: Alignment(.34, -.7),
      radius: 1.28,
      colors: [
        GameColors.oat,
        GameColors.ivory,
        GameColors.rosyBeige,
        GameColors.sand,
      ],
      stops: [0, .38, .74, 1],
    ),
    sceneAccent: Color(0xFFC77C3D),
    sceneAccentAlt: Color(0xFF3C9DA5),
    relationshipAccent: GameColors.coral,
    relationshipAlt: GameColors.gold,
    speechGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF9F1), Color(0xFFFFE0EA)],
    ),
    speechBorder: GameColors.copper,
    glow: Color(0x66FFB75D),
  );
}
