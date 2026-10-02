import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';

class GameIconMedallionV3 extends StatelessWidget {
  const GameIconMedallionV3({
    super.key,
    required this.icon,
    required this.color,
    this.size = 34,
    this.iconSize,
    this.child,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(
        color: ConnectionsColorsV3.outline,
        width: ConnectionsShadowsV3.outlineThin,
      ),
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
      boxShadow: ConnectionsShadowsV3.solid(color, y: 3),
    ),
    alignment: Alignment.center,
    child:
        child ??
        Icon(
          icon,
          size: iconSize ?? size * .56,
          color: ConnectionsColorsV3.onColor,
        ),
  );
}
