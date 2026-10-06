import 'package:flutter/material.dart';

import '../../data/idle_balance.dart';

class ActivityUpgradeButton extends StatelessWidget {
  const ActivityUpgradeButton({
    super.key,
    required this.activityName,
    required this.activityKindLabel,
    required this.upgraded,
    required this.canAfford,
    required this.onConfirm,
  });

  final String activityName;
  final String activityKindLabel;
  final bool upgraded;
  final bool canAfford;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: upgraded ? 'Aprimorado x2' : 'Aprimorar por 5 Cerejas',
    child: IconButton(
      key: ValueKey('activity_upgrade_$activityName'),
      onPressed: upgraded
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('APRIMORAR ${activityName.toUpperCase()}?'),
                  content: Text(
                    'Gaste ${IdleBalance.activityUpgradeCherryCost} Cerejas para aprimorar permanentemente este $activityKindLabel. O progresso será x2.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('CANCELAR'),
                    ),
                    FilledButton(
                      onPressed: canAfford
                          ? () => Navigator.pop(dialogContext, true)
                          : null,
                      child: const Text('APRIMORAR'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await onConfirm();
            },
      icon: Icon(
        upgraded ? Icons.check_circle_rounded : Icons.local_florist_rounded,
        color: upgraded ? const Color(0xFFE86B72) : const Color(0xFF75656E),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      visualDensity: VisualDensity.compact,
    ),
  );
}
