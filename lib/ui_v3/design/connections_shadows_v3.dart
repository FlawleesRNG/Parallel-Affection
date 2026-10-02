import 'package:flutter/material.dart';

import 'connections_colors_v3.dart';

abstract final class ConnectionsShadowsV3 {
  static const outlineThin = 1.5;
  static const outline = 2.5;
  static const outlineStrong = 3.5;

  static List<BoxShadow> solid(Color color, {double y = 5}) => [
    BoxShadow(
      color: ConnectionsColorsV3.darkFor(color).withValues(alpha: .95),
      offset: Offset(0, y),
      blurRadius: 0,
    ),
  ];

  static List<BoxShadow> ambient({double opacity = .14}) => [
    BoxShadow(
      color: ConnectionsColorsV3.outline.withValues(alpha: opacity),
      offset: const Offset(0, 6),
      blurRadius: 16,
    ),
  ];

  static List<BoxShadow> windowDepth(Color color) => [
    ...ambient(opacity: .12),
    BoxShadow(
      color: ConnectionsColorsV3.darkFor(color).withValues(alpha: .22),
      offset: const Offset(0, 5),
      blurRadius: 0,
    ),
  ];
}
