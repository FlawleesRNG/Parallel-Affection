import 'package:flutter/material.dart';

import 'connections_colors.dart';

abstract final class ConnectionsThemeV2 {
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ConnectionsColors.background,
      ConnectionsColors.paper,
      ConnectionsColors.beige,
    ],
  );
}
