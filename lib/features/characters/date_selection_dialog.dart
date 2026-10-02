import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/number_formatter.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../../core/character_catalog.dart';
import '../../services/game_audio_hooks.dart';
import '../../shared/game_ui.dart';

Future<void> showDateSelectionDialog(
  BuildContext context,
  GameController controller, {
  ValueChanged<ActionResult>? onStarted,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: .92,
        child: DateSelectionDialog(
          controller: controller,
          onStarted: onStarted,
          embedded: true,
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    barrierColor: GameColors.ink.withValues(alpha: .32),
    builder: (_) =>
        DateSelectionDialog(controller: controller, onStarted: onStarted),
  );
}

class DateSelectionDialog extends StatefulWidget {
  const DateSelectionDialog({
    super.key,
    required this.controller,
    this.onStarted,
    this.embedded = false,
  });

  final GameController controller;
  final ValueChanged<ActionResult>? onStarted;
  final bool embedded;

  @override
  State<DateSelectionDialog> createState() => _DateSelectionDialogState();
}

class _DateSelectionDialogState extends State<DateSelectionDialog> {
  String? busyId;

  static const accents = [
    GameColors.coral,
    GameColors.cyan,
    GameColors.violet,
    GameColors.orange,
    GameColors.magenta,
  ];

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.controller.state.characters[PlayableCharacterIds.roxanne]!;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920, maxHeight: 700),
      child: ColoredBox(
        color: GameColors.paper,
        child: Padding(
          padding: const EdgeInsets.all(GameSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [GameColors.violet, GameColors.peach],
                      ),
                      borderRadius: BorderRadius.circular(GameRadii.large),
                      boxShadow: const [
                        BoxShadow(
                          color: GameColors.brownShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_activity_rounded,
                      color: GameColors.cream,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escolher encontro',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text(
                          'Siga a linha noturna e descubra novos lugares.',
                          style: TextStyle(
                            color: GameColors.softInk,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              _MetroLine(stage: progress.stage, accents: accents),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    itemCount: IdleBalance.encounters.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 700 ? 2 : 1,
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 11,
                      childAspectRatio: constraints.maxWidth >= 700
                          ? 2.65
                          : 2.45,
                    ),
                    itemBuilder: (context, index) {
                      final encounter = IdleBalance.encounters[index];
                      final state = widget.controller.state;
                      final stageOk = progress.stage >= encounter.stage;
                      final moneyOk = state.money >= encounter.price;
                      final blocksOk =
                          state.availableBlocks >= encounter.blocks;
                      final noActive = state.activeEncounter == null;
                      final available =
                          stageOk && moneyOk && blocksOk && noActive;
                      final reason = !stageOk
                          ? 'Estágio ${encounter.stage + 1} necessário'
                          : !moneyOk
                          ? 'Falta dinheiro'
                          : !blocksOk
                          ? 'Faltam blocos'
                          : !noActive
                          ? 'Encontro em andamento'
                          : 'Disponível agora';
                      return _DateCard(
                        index: index,
                        accent: accents[index],
                        encounter: encounter,
                        available: available,
                        reason: reason,
                        completedCount: progress.encounters,
                        busy: busyId == encounter.id,
                        onStart: () => _start(encounter.id),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.embedded) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: content,
      );
    }
    return Dialog(insetPadding: const EdgeInsets.all(12), child: content);
  }

  Future<void> _start(String id) async {
    setState(() => busyId = id);
    final result = await widget.controller.startEncounter(
      PlayableCharacterIds.roxanne,
      id,
    );
    if (!mounted) return;
    setState(() => busyId = null);
    GameAudioHooks.emit(GameAudioCue.encounter);
    widget.onStarted?.call(result);
    if (widget.onStarted == null) showGameResult(context, result);
  }
}

class _MetroLine extends StatelessWidget {
  const _MetroLine({required this.stage, required this.accents});

  final int stage;
  final List<Color> accents;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 24,
          right: 24,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: accents),
              borderRadius: BorderRadius.circular(GameRadii.pill),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            5,
            (index) => Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: stage >= IdleBalance.encounters[index].stage
                    ? accents[index]
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accents[index], width: 2),
                boxShadow: stage >= IdleBalance.encounters[index].stage
                    ? [
                        BoxShadow(
                          color: accents[index].withValues(alpha: .5),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: stage >= IdleBalance.encounters[index].stage
                      ? Colors.white
                      : GameColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.index,
    required this.accent,
    required this.encounter,
    required this.available,
    required this.reason,
    required this.completedCount,
    required this.busy,
    required this.onStart,
  });

  final int index;
  final Color accent;
  final EncounterDefinition encounter;
  final bool available;
  final String reason;
  final int completedCount;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: .94),
          Color.lerp(accent, Colors.white, available ? .64 : .88)!,
          GameColors.roseBeige,
        ],
      ),
      borderRadius: BorderRadius.circular(GameRadii.large),
      border: Border.all(
        color: available ? accent : GameColors.cuteStroke,
        width: available ? 2 : 1.2,
      ),
      boxShadow: available
          ? [
              BoxShadow(
                color: accent.withValues(alpha: .18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ]
          : const [
              BoxShadow(
                color: GameColors.brownShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
    ),
    child: Row(
      children: [
        Container(
          width: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: .82),
                Color.lerp(accent, Colors.white, .38)!,
              ],
            ),
            borderRadius: BorderRadius.circular(GameRadii.large),
          ),
          child: Icon(
            available ? _placeIcon(index) : Icons.lock_rounded,
            color: available ? GameColors.cream : GameColors.locked,
            size: 30,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                encounter.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  _MiniInfo(
                    Icons.payments_rounded,
                    NumberFormatter.money(encounter.price),
                  ),
                  _MiniInfo(Icons.schedule_rounded, '${encounter.seconds}s'),
                  _MiniInfo(Icons.grid_view_rounded, '${encounter.blocks}'),
                  _MiniInfo(Icons.favorite_rounded, '+${encounter.affection}'),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$reason • Encontros da rota: $completedCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: available ? accent : GameColors.locked,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: available && !busy ? onStart : null,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: accent.withValues(alpha: .25),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GameRadii.pill),
            ),
          ),
          child: Text(busy ? '...' : 'Ir'),
        ),
      ],
    ),
  );

  IconData _placeIcon(int index) => switch (index) {
    0 => Icons.coffee_rounded,
    1 => Icons.location_city_rounded,
    2 => Icons.mic_rounded,
    3 => Icons.music_note_rounded,
    _ => Icons.nightlife_rounded,
  };
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: GameColors.softInk),
      const SizedBox(width: 2),
      Text(
        label,
        style: const TextStyle(color: GameColors.softInk, fontSize: 10),
      ),
    ],
  );
}
