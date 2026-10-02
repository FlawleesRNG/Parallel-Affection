import 'package:flutter/material.dart';

import '../theme/game_tokens.dart';

abstract final class GameTypography {
  static const title = TextStyle(
    color: GameColors.ink,
    fontWeight: FontWeight.w900,
  );
  static const body = TextStyle(
    color: GameColors.ink,
    fontWeight: FontWeight.w500,
  );
  static const detail = TextStyle(color: GameColors.softInk);
  static const button = TextStyle(fontWeight: FontWeight.w900);
}
