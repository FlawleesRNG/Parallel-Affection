import 'package:flutter/material.dart';

import '../../core/number_formatter.dart';
import '../../models/idle_models.dart';
import '../design/connections_design.dart';

class ConnectionsHudV2 extends StatelessWidget {
  const ConnectionsHudV2({
    super.key,
    required this.state,
    required this.onSettings,
  });

  final IdleState state;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('connections_hud_v2'),
    height: 66,
    padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
    decoration: BoxDecoration(
      color: ConnectionsColors.paper,
      border: Border(
        bottom: BorderSide(
          color: ConnectionsColors.outline.withValues(alpha: .35),
          width: 2,
        ),
      ),
      boxShadow: ConnectionsShadows.soft,
    ),
    child: Row(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ConnectionsColors.beige,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ConnectionsColors.outline, width: 2),
          ),
          child: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: ConnectionsColors.relation),
              SizedBox(width: 8),
              Text(
                'CONEXÕES',
                style: TextStyle(
                  color: ConnectionsColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HudResourceV2(
                  key: const ValueKey('resource_money'),
                  icon: Icons.account_balance_wallet_rounded,
                  value: NumberFormatter.money(state.money),
                  color: ConnectionsColors.money,
                  width: 154,
                ),
                _HudResourceV2(
                  key: const ValueKey('resource_diamonds'),
                  icon: Icons.diamond_rounded,
                  value: '${state.diamonds}',
                  color: ConnectionsColors.diamonds,
                ),
                _HudResourceV2(
                  key: const ValueKey('resource_time_blocks'),
                  icon: Icons.schedule_rounded,
                  value: '${state.availableBlocks}/${state.totalBlocks}',
                  color: ConnectionsColors.time,
                ),
                _HudResourceV2(
                  key: const ValueKey('resource_speed'),
                  icon: Icons.bolt_rounded,
                  value: 'x${state.speedMultiplier.toStringAsFixed(1)}',
                  color: ConnectionsColors.speed,
                ),
                _HudResourceV2(
                  key: const ValueKey('resource_prestige'),
                  icon: Icons.auto_awesome_rounded,
                  value: '+${((state.prestigeBonus - 1) * 100).round()}%',
                  color: ConnectionsColors.prestige,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Configurações',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    ),
  );
}

class _HudResourceV2 extends StatelessWidget {
  const _HudResourceV2({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.width = 112,
  });

  final IconData icon;
  final String value;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 47,
    margin: const EdgeInsets.only(right: 7),
    padding: const EdgeInsets.fromLTRB(6, 5, 10, 6),
    decoration: BoxDecoration(
      color: Color.lerp(color, Colors.white, .28),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ConnectionsColors.outline, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x406B535D), offset: Offset(0, 5)),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          left: 10,
          right: 10,
          top: 3,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .36),
              borderRadius: BorderRadius.circular(ConnectionsRadius.pill),
            ),
          ),
        ),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: ConnectionsColors.outline, width: 2),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontFeatures: [FontFeature.tabularFigures()],
                  shadows: [
                    Shadow(
                      color: Color(0x77000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
