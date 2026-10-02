import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../layout/ryomi_breakpoints_v3.dart';
import 'debug_region_label_v3.dart';
import 'game_tab_v3.dart';

class BottomDockV3 extends StatelessWidget {
  const BottomDockV3({
    super.key,
    required this.selectedIndex,
    required this.spec,
    required this.onSelected,
    this.showDev = false,
  });

  final int selectedIndex;
  final RyomiLayoutSpec spec;
  final ValueChanged<int> onSelected;
  final bool showDev;

  static const _baseItems = [
    (
      'paixoes',
      'Paixões',
      Icons.favorite_border_rounded,
      ConnectionsColorsV3.relationship,
    ),
    (
      'empregos',
      'Empregos',
      Icons.work_outline_rounded,
      ConnectionsColorsV3.jobs,
    ),
    ('hobbies', 'Hobbies', Icons.palette_outlined, ConnectionsColorsV3.hobbies),
    (
      'estatisticas',
      'Estatísticas',
      Icons.query_stats_rounded,
      ConnectionsColorsV3.interaction,
    ),
    (
      'conquistas',
      'Conquistas',
      Icons.star_border_rounded,
      ConnectionsColorsV3.achievements,
    ),
    ('loja', 'Loja', Icons.storefront_outlined, ConnectionsColorsV3.shop),
    ('extras', 'Extras', Icons.more_horiz_rounded, ConnectionsColorsV3.extras),
  ];

  static const _devItem = (
    'dev',
    'DEV',
    Icons.bug_report_rounded,
    ConnectionsColorsV3.error,
  );

  @override
  Widget build(BuildContext context) {
    final items = showDev ? [..._baseItems, _devItem] : _baseItems;
    return SizedBox(
      key: const ValueKey('bottom_dock_v3'),
      height: spec.dockHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ConnectionsColorsV3.backgroundSecondary,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spec.dockHorizontalPadding,
            spec.dockVerticalPadding,
            spec.dockHorizontalPadding,
            spec.dockVerticalPadding,
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('dock_${items[index].$1}'),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GameTabV3(
                            icon: items[index].$3,
                            label: items[index].$2,
                            color: items[index].$4,
                            selected: selectedIndex == index,
                            compact: spec.isMobile || spec.isCompactDesktop,
                            onTap: () => onSelected(index),
                          ),
                        ),
                        if (selectedIndex == index)
                          Positioned(
                            key: ValueKey('dock_${items[index].$1}_selected'),
                            left: 0,
                            right: 0,
                            bottom: 7,
                            child: Center(
                              child: Container(
                                width: 26,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: ConnectionsColorsV3.onColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (index < items.length - 1) SizedBox(width: spec.dockGap),
              ],
              if (!spec.isMobile) ...[
                const SizedBox(width: 8),
                const DebugRegionLabelV3('Dock V3'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
