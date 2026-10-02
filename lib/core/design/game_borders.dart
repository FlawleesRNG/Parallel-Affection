import 'package:flutter/material.dart';

import '../theme/game_tokens.dart';

abstract final class GameBorders {
  static const soft = BorderSide(color: GameColors.outlineSoft, width: 2);
  static const strong = BorderSide(color: GameColors.outline, width: 2);

  static BorderSide system(Color color) => BorderSide(color: color, width: 2);
}
