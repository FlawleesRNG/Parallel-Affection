import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';
import 'game_icon_medallion_v3.dart';

class ResourceModuleV3 extends StatelessWidget {
  const ResourceModuleV3({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
    this.tooltip,
    this.semanticLabel,
    this.emphasized = false,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  final Color color;
  final bool compact;
  final String? tooltip;
  final String? semanticLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final module = TweenAnimationBuilder<double>(
      key: ValueKey('resource_module_v3_$label$value'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      tween: Tween(begin: .975, end: 1),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ConnectionsColorsV3.darkFor(color),
          borderRadius: BorderRadius.circular(ConnectionsRadiusV3.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ConnectionsColorsV3.paperElevated,
              border: Border.all(
                color: ConnectionsColorsV3.outline,
                width: ConnectionsShadowsV3.outlineThin,
              ),
              borderRadius: BorderRadius.circular(ConnectionsRadiusV3.medium),
              boxShadow: [
                BoxShadow(
                  color: ConnectionsColorsV3.outline.withValues(alpha: .10),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  top: 4,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .52),
                      borderRadius: BorderRadius.circular(
                        ConnectionsRadiusV3.circle,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 5 : 7,
                    vertical: compact ? 2 : 3,
                  ),
                  child: Row(
                    children: [
                      if (!compact) ...[
                        GameIconMedallionV3(
                          icon: icon ?? Icons.circle,
                          color: color,
                          size: 26,
                          child: iconWidget,
                        ),
                        const SizedBox(width: 7),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ConnectionsTypographyV3.resourceLabel(
                                size: compact ? 9.5 : 10.5,
                              ),
                            ),
                            Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ConnectionsTypographyV3.resourceValue(
                                size: emphasized
                                    ? (compact ? 14 : 16)
                                    : (compact ? 13 : 14.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Widget child = semanticLabel == null
        ? module
        : Semantics(
            container: true,
            label: semanticLabel,
            child: ExcludeSemantics(child: module),
          );
    if (tooltip != null) child = Tooltip(message: tooltip!, child: child);
    return child;
  }
}
