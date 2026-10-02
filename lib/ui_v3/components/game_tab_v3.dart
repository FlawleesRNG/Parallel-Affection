import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_motion_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';
import 'game_badge_v3.dart';

class GameTabV3 extends StatefulWidget {
  const GameTabV3({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.badge,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool compact;

  @override
  State<GameTabV3> createState() => _GameTabV3State();
}

class _GameTabV3State extends State<GameTabV3> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? widget.color
        : Color.lerp(ConnectionsColorsV3.paperElevated, widget.color, .08)!;
    final textColor = widget.selected
        ? ConnectionsColorsV3.onColor
        : ConnectionsColorsV3.ink;
    final y = _pressed
        ? 3.0
        : _hovered
        ? -2.0
        : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedSlide(
          duration: ConnectionsMotionV3.fast,
          curve: ConnectionsMotionV3.press,
          offset: Offset(0, y / 44),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ConnectionsColorsV3.darkFor(color),
              borderRadius: BorderRadius.circular(ConnectionsRadiusV3.large),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: _pressed ? 1 : 5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: ConnectionsColorsV3.outline,
                    width: ConnectionsShadowsV3.outlineThin,
                  ),
                  borderRadius: BorderRadius.circular(
                    ConnectionsRadiusV3.large,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            size: widget.compact ? 21 : 24,
                            color: textColor,
                          ),
                          SizedBox(height: widget.compact ? 3 : 5),
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ConnectionsTypographyV3.button(
                              size: widget.compact ? 12 : 13,
                            ).copyWith(color: textColor),
                          ),
                        ],
                      ),
                    ),
                    if (widget.badge != null)
                      Positioned(
                        top: 6,
                        right: 8,
                        child: GameBadgeV3(
                          label: widget.badge!,
                          compact: true,
                          kind: GameBadgeKindV3.quantity,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
