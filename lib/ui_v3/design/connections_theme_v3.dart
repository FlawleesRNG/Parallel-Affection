import 'package:flutter/material.dart';

import 'connections_colors_v3.dart';
import 'connections_theme_extension_v3.dart';
import 'connections_typography_v3.dart';

abstract final class ConnectionsThemeV3 {
  static const name = 'Conexões — Cozy Arcade Journal';

  static ThemeData applyTo(ThemeData base) => base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      surface: ConnectionsColorsV3.paper,
      primary: ConnectionsColorsV3.relationship,
      secondary: ConnectionsColorsV3.interaction,
      onSurface: ConnectionsColorsV3.ink,
      outline: ConnectionsColorsV3.outline,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: ConnectionsTypographyV3.gameTitle(),
      titleMedium: ConnectionsTypographyV3.windowTitle(),
      labelLarge: ConnectionsTypographyV3.button(),
      bodyMedium: ConnectionsTypographyV3.body(),
      bodySmall: ConnectionsTypographyV3.secondary(),
    ),
    extensions: const [ConnectionsThemeExtensionV3.cozyArcadeJournal],
  );
}
