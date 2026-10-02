import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';
import '../phone/phone_overlay_v3.dart';
import 'game_button_v3.dart';

class PhoneButtonV3 extends StatelessWidget {
  const PhoneButtonV3({super.key, required this.compact, this.unreadCount = 0});

  final bool compact;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 44.0;
    final badge = _badgeText(unreadCount);
    return SizedBox(
      key: const ValueKey('phone_button_v3'),
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GameButtonV3(
              tooltip: 'Celular',
              semanticLabel: 'Celular',
              onPressed: () => showPhoneOverlayV3(context),
              color: ConnectionsColorsV3.info,
              compact: compact,
              child: Icon(Icons.smartphone_rounded, size: compact ? 18 : 21),
            ),
          ),
          Positioned(
            key: const ValueKey('phone_badge_slot_v3'),
            right: -3,
            top: -4,
            child: badge == null
                ? const SizedBox.shrink()
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: ConnectionsColorsV3.relationship,
                      border: Border.all(
                        color: ConnectionsColorsV3.outline,
                        width: ConnectionsShadowsV3.outlineThin,
                      ),
                      borderRadius: BorderRadius.circular(
                        ConnectionsRadiusV3.circle,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      child: Text(
                        badge,
                        style: ConnectionsTypographyV3.badge(size: 9),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String? _badgeText(int value) {
    if (value <= 0) return null;
    if (value > 99) return '99+';
    return value.toString();
  }
}
