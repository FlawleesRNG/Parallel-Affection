import 'package:flutter/material.dart';

import '../components/pop_journal_button.dart';
import '../design/connections_design.dart';

class ConnectionsBottomMenuItemV2 {
  const ConnectionsBottomMenuItemV2(
    this.id,
    this.label,
    this.icon,
    this.color,
    this.darkColor,
  );

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color darkColor;
}

class ConnectionsBottomMenuV2 extends StatelessWidget {
  const ConnectionsBottomMenuV2({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const items = [
    ConnectionsBottomMenuItemV2(
      'paixoes',
      'Paixões',
      Icons.favorite_rounded,
      ConnectionsColors.relation,
      ConnectionsColors.relationDark,
    ),
    ConnectionsBottomMenuItemV2(
      'empregos',
      'Empregos',
      Icons.work_rounded,
      ConnectionsColors.jobs,
      ConnectionsColors.jobsDark,
    ),
    ConnectionsBottomMenuItemV2(
      'hobbies',
      'Hobbies',
      Icons.auto_awesome_rounded,
      ConnectionsColors.hobbies,
      ConnectionsColors.hobbiesDark,
    ),
    ConnectionsBottomMenuItemV2(
      'estatisticas',
      'Estatísticas',
      Icons.query_stats_rounded,
      ConnectionsColors.interact,
      ConnectionsColors.hobbiesDark,
    ),
    ConnectionsBottomMenuItemV2(
      'conquistas',
      'Conquistas',
      Icons.emoji_events_rounded,
      ConnectionsColors.achievements,
      ConnectionsColors.achievementsDark,
    ),
    ConnectionsBottomMenuItemV2(
      'loja',
      'Loja',
      Icons.shopping_bag_rounded,
      ConnectionsColors.shop,
      ConnectionsColors.shopDark,
    ),
    ConnectionsBottomMenuItemV2(
      'extras',
      'Extras',
      Icons.dashboard_customize_rounded,
      ConnectionsColors.extras,
      ConnectionsColors.extrasDark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      key: const ValueKey('connections_bottom_menu_v2'),
      height: 92,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 10, 9, compact ? 6 : 10, 7),
      color: ConnectionsColors.background,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PopJournalButton(
                      key: ValueKey('dock_${items[i].id}'),
                      label: items[i].label,
                      icon: items[i].icon,
                      color: items[i].color,
                      darkColor: items[i].darkColor,
                      height: 76,
                      iconSize: compact ? 28 : 34,
                      selected: selectedIndex == i,
                      onPressed: () => onSelected(i),
                    ),
                  ),
                  if (selectedIndex == i)
                    Positioned(
                      key: ValueKey('dock_${items[i].id}_selected'),
                      left: 6,
                      top: 4,
                      child: const SizedBox(width: 1, height: 1),
                    ),
                ],
              ),
            ),
            if (i < items.length - 1) SizedBox(width: compact ? 4 : 8),
          ],
        ],
      ),
    );
  }
}
