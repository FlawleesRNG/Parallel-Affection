import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_spacing_v3.dart';
import '../design/connections_typography_v3.dart';
import 'game_icon_medallion_v3.dart';

class GameWindowFrameV3 extends StatelessWidget {
  const GameWindowFrameV3({
    super.key,
    required this.title,
    required this.color,
    required this.child,
    this.icon,
    this.headerActions = const [],
    this.badge,
    this.compact = false,
    this.contentPadding,
  });

  final String title;
  final IconData? icon;
  final Color color;
  final Widget child;
  final List<Widget> headerActions;
  final Widget? badge;
  final bool compact;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ConnectionsColorsV3.darkFor(color),
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.window),
      boxShadow: ConnectionsShadowsV3.windowDepth(color),
    ),
    child: Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ConnectionsColorsV3.paper,
          border: Border.all(
            color: ConnectionsColorsV3.outline,
            width: ConnectionsShadowsV3.outline,
          ),
          borderRadius: BorderRadius.circular(ConnectionsRadiusV3.window),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            ConnectionsRadiusV3.window - ConnectionsShadowsV3.outline,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GameWindowHeaderV3(
                title: title,
                icon: icon,
                color: color,
                compact: compact,
                actions: headerActions,
                badge: badge,
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: ConnectionsColorsV3.paperElevated,
                  ),
                  child: Padding(
                    padding:
                        contentPadding ??
                        EdgeInsets.all(compact ? ConnectionsSpacingV3.xs : 10),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GameWindowHeaderV3 extends StatelessWidget {
  const _GameWindowHeaderV3({
    required this.title,
    required this.color,
    required this.compact,
    required this.actions,
    required this.badge,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final Color color;
  final bool compact;
  final List<Widget> actions;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Color.lerp(ConnectionsColorsV3.paper, color, .12),
      border: const Border(
        bottom: BorderSide(
          color: ConnectionsColorsV3.outline,
          width: ConnectionsShadowsV3.outlineThin,
        ),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 3 : 7,
        compact ? 7 : 9,
        compact ? 3 : 7,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            GameIconMedallionV3(
              icon: icon!,
              color: color,
              size: compact ? 20 : 28,
            ),
            SizedBox(width: compact ? 5 : 8),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ConnectionsTypographyV3.windowTitle(
                size: compact ? 14 : 18,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            // Compact windows may be only ~208px wide. The stage badge must
            // yield horizontal room to the title and minimize control rather
            // than forcing the header Row past its bounds.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 68 : 120),
              child: badge!,
            ),
          ],
          for (final action in actions) action,
        ],
      ),
    ),
  );
}
