import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';

enum GameBadgeKindV3 { info, novelty, quantity, locked, complete }

class GameBadgeV3 extends StatelessWidget {
  const GameBadgeV3({
    super.key,
    required this.label,
    this.kind = GameBadgeKindV3.info,
    this.compact = false,
  });

  final String label;
  final GameBadgeKindV3 kind;
  final bool compact;

  Color get _color => switch (kind) {
    GameBadgeKindV3.info => ConnectionsColorsV3.info,
    GameBadgeKindV3.novelty => ConnectionsColorsV3.relationship,
    GameBadgeKindV3.quantity => ConnectionsColorsV3.shop,
    GameBadgeKindV3.locked => ConnectionsColorsV3.locked,
    GameBadgeKindV3.complete => ConnectionsColorsV3.success,
  };

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _color,
      border: Border.all(
        color: ConnectionsColorsV3.outline,
        width: ConnectionsShadowsV3.outlineThin,
      ),
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
      boxShadow: ConnectionsShadowsV3.solid(_color, y: compact ? 2 : 3),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ConnectionsTypographyV3.badge(size: compact ? 9 : 10.5),
      ),
    ),
  );
}
