import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/idle_rules.dart';
import '../../core/number_formatter.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../../features/characters/date_selection_dialog.dart';
import '../../features/characters/gift_selection_dialog.dart';
import '../../models/idle_models.dart';
import '../../services/game_audio_hooks.dart';
import '../../shared/game_ui.dart';
import '../components/pop_journal_button.dart';
import '../components/pop_journal_card.dart';
import '../design/connections_design.dart';

enum _RyomiV2Event { tap, talk, interact, gift, encounter, stage }

class RyomiScreenV2 extends StatefulWidget {
  const RyomiScreenV2({super.key, required this.controller});

  final GameController controller;

  @override
  State<RyomiScreenV2> createState() => _RyomiScreenV2State();
}

class _RyomiScreenV2State extends State<RyomiScreenV2> {
  late String line;
  String? floatingText;
  int feedbackSequence = 0;
  int tapFeedbackTotal = 0;
  bool requirementsOpen = false;
  bool dialogueOpen = true;
  Timer? cooldownTimer;
  Timer? tapResetTimer;

  @override
  void initState() {
    super.initState();
    final progress = widget.controller.state.characters['ryomi']!;
    line = IdleRules.currentLine('ryomi', progress.stage);
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    tapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.state.characters['ryomi']!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 800;
        if (mobile) {
          return SingleChildScrollView(
            key: const ValueKey('ryomi_v2_mobile_layout'),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                CharacterSelectorV2(progress: progress, compact: true),
                const SizedBox(height: 8),
                SizedBox(
                  height: math.max(350, constraints.maxHeight * .50),
                  child: RyomiSceneV2(
                    controller: widget.controller,
                    floatingFeedback: _floatingFeedback(),
                    onTap: _tapRyomi,
                  ),
                ),
                const SizedBox(height: 8),
                _InteractionGridV2(
                  controller: widget.controller,
                  onResult: _handleResult,
                ),
                const SizedBox(height: 8),
                DialoguePanelV2(
                  text: line,
                  minimized: !dialogueOpen,
                  onToggle: () => setState(() => dialogueOpen = !dialogueOpen),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 500,
                  child: _RelationshipPanelV2(
                    controller: widget.controller,
                    open: true,
                    onToggle: () {},
                    onResult: _handleResult,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            key: const ValueKey('ryomi_relationship_desktop_layout'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: const ValueKey('character_selector_region'),
                width: 170,
                child: CharacterSelectorV2(progress: progress),
              ),
              const SizedBox(width: 8),
              SizedBox(
                key: const ValueKey('relationship_progress_region'),
                width: 305,
                child: _RelationshipPanelV2(
                  controller: widget.controller,
                  open: requirementsOpen,
                  onToggle: () =>
                      setState(() => requirementsOpen = !requirementsOpen),
                  onResult: _handleResult,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                key: const ValueKey('character_presentation_region'),
                child: RyomiSceneV2(
                  controller: widget.controller,
                  floatingFeedback: _floatingFeedback(),
                  onTap: _tapRyomi,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                key: const ValueKey('character_controls_area'),
                width: 305,
                child: Column(
                  children: [
                    Expanded(
                      key: const ValueKey('interaction_controls_region'),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _InteractionGridV2(
                          controller: widget.controller,
                          onResult: _handleResult,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      key: const ValueKey('character_dialogue_region'),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: DialoguePanelV2(
                          text: line,
                          minimized: !dialogueOpen,
                          onToggle: () =>
                              setState(() => dialogueOpen = !dialogueOpen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _floatingFeedback() {
    if (floatingText == null) return null;
    return FloatingRewardText(
      key: ValueKey(feedbackSequence),
      text: floatingText!,
      color: ConnectionsColors.relation,
      onFinished: () {
        if (mounted) setState(() => floatingText = null);
      },
    );
  }

  Future<void> _tapRyomi() async {
    final result = await widget.controller.tapCharacter('ryomi');
    _handleResult(result, _RyomiV2Event.tap);
  }

  void _handleResult(ActionResult result, _RyomiV2Event event) {
    final reward = RegExp(r'\+\d+[^.]*').firstMatch(result.message)?.group(0);
    final cooldown = result.message.startsWith('Aguarde');
    final success = switch (event) {
      _RyomiV2Event.tap => reward != null,
      _RyomiV2Event.talk || _RyomiV2Event.interact => reward != null,
      _RyomiV2Event.gift => result.message.contains('entregue(s): +'),
      _RyomiV2Event.encounter => result.message.contains('iniciado.'),
      _RyomiV2Event.stage => result.message.startsWith('Novo'),
    };
    setState(() {
      line = switch (event) {
        _RyomiV2Event.tap => line,
        _RyomiV2Event.talk =>
          cooldown
              ? 'Calma... deixa a próxima música começar.'
              : success
              ? 'Você presta atenção até nas pausas. Eu gosto disso.'
              : 'Não foi dessa vez. Vamos tentar em outro momento.',
        _RyomiV2Event.interact =>
          cooldown
              ? 'Ei, sem atropelar o ritmo.'
              : success
              ? 'Esse gesto foi inesperado... mas não ruim.'
              : 'Talvez seja melhor esperar um pouco.',
        _RyomiV2Event.gift =>
          success
              ? 'Você lembrou de mim? Vou guardar com carinho.'
              : 'Parece que ainda falta alguma coisa para esse presente.',
        _RyomiV2Event.encounter =>
          success
              ? 'Então está combinado. Encontro você depois do programa.'
              : 'Melhor conferir os requisitos primeiro.',
        _RyomiV2Event.stage =>
          success
              ? 'Parece que nossa frequência mudou de novo.'
              : 'Ainda temos um caminho antes da próxima fase.',
      };
      if (reward != null) {
        if (event == _RyomiV2Event.tap) {
          final gain =
              int.tryParse(RegExp(r'\d+').firstMatch(reward)?.group(0) ?? '') ??
              1;
          tapFeedbackTotal += gain;
          floatingText = '♥ +$tapFeedbackTotal';
          tapResetTimer?.cancel();
          tapResetTimer = Timer(const Duration(milliseconds: 520), () {
            if (mounted) setState(() => tapFeedbackTotal = 0);
          });
        } else {
          tapFeedbackTotal = 0;
          floatingText = reward;
        }
        feedbackSequence++;
      }
    });
    if (event == _RyomiV2Event.stage && result.storyEpisodeId != null) {
      showGameResult(context, result);
    }
  }
}

class CharacterSelectorV2 extends StatelessWidget {
  const CharacterSelectorV2({
    super.key,
    required this.progress,
    this.compact = false,
  });

  final CharacterProgress progress;
  final bool compact;

  @override
  Widget build(BuildContext context) => PopJournalCard(
    padding: const EdgeInsets.all(10),
    borderColor: ConnectionsColors.relation,
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _SelectorPatternPainter())),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            key: const ValueKey('character_selector_ryomi'),
            height: compact ? 82 : 86,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ConnectionsColors.paper,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ConnectionsColors.relation, width: 3),
              boxShadow: ConnectionsShadows.soft,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 52,
                    height: 68,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      child: Image.asset(GameAssets.ryomiStage01),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 82,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ryomi',
                            style: ConnectionsTypography.label,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            IdleRules.stageName(progress.stage),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ConnectionsTypography.caption.copyWith(
                              color: ConnectionsColors.relationDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Selecionada',
                            style: ConnectionsTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RelationshipPanelV2 extends StatelessWidget {
  const _RelationshipPanelV2({
    required this.controller,
    required this.open,
    required this.onToggle,
    required this.onResult,
  });

  final GameController controller;
  final bool open;
  final VoidCallback onToggle;
  final void Function(ActionResult, _RyomiV2Event) onResult;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final progress = state.characters['ryomi']!;
    final needed = IdleBalance.affectionNeeded(progress.stage);
    final currentStage = progress.stage.clamp(
      0,
      IdleRules.totalRelationshipStages - 1,
    );
    final stageProgress = IdleRules.stageProgressFraction(progress);
    final requirements = _requirements(state, progress, needed);
    final pending = requirements.where((item) => !item.complete).toList();
    final canAdvance = IdleRules.canAdvance(state, 'ryomi');
    final visible = requirements.take(open ? 5 : 3);

    return PopJournalCard(
      key: const ValueKey('relationship_progress_panel'),
      padding: EdgeInsets.zero,
      borderColor: ConnectionsColors.relation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 78,
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: const BoxDecoration(
              color: ConnectionsColors.relation,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Ryomi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Etapa ${currentStage + 1} de ${IdleRules.totalRelationshipStages}',
                        key: const ValueKey('relationship_stage_count'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ConnectionsRadius.pill),
                  ),
                  child: Text(
                    '${IdleRules.routeProgressPercent(progress)}%',
                    key: const ValueKey('relationship_route_percent'),
                    style: const TextStyle(
                      color: ConnectionsColors.relationDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    IdleRules.stageName(currentStage).toUpperCase(),
                    key: const ValueKey('relationship_stage_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ConnectionsTypography.label.copyWith(
                      color: ConnectionsColors.relationDark,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CheckpointTrackV2(
                    currentStage: currentStage,
                    progress: stageProgress,
                  ),
                  const SizedBox(height: 12),
                  _AffectionBarV2(
                    progress: stageProgress,
                    value: '${progress.affection.clamp(0, needed)} / $needed',
                  ),
                  const SizedBox(height: 12),
                  _JournalLabel(
                    icon: Icons.flag_rounded,
                    text:
                        'Próxima: ${currentStage >= 9 ? 'ROTA CONCLUÍDA' : IdleRules.stageName(currentStage + 1).toUpperCase()}',
                    keyValue: 'relationship_next_stage',
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    key: const ValueKey('requirements_toggle'),
                    onTap: onToggle,
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Objetivos',
                            style: ConnectionsTypography.label,
                          ),
                        ),
                        Icon(
                          open
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: ConnectionsColors.relationDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final item in visible) _RequirementChipV2(item: item),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: PopJournalButton(
              key: const ValueKey('advance_relationship'),
              label: canAdvance ? 'Avançar vínculo' : 'Falta',
              subtitle: canAdvance
                  ? 'pronto'
                  : (pending.isEmpty ? 'objetivos' : pending.first.label),
              icon: canAdvance ? Icons.favorite_rounded : Icons.lock_rounded,
              color: canAdvance
                  ? ConnectionsColors.relation
                  : ConnectionsColors.disabled,
              darkColor: canAdvance
                  ? ConnectionsColors.relationDark
                  : ConnectionsColors.muted,
              height: 54,
              iconSize: 25,
              enabled: canAdvance,
              onPressed: canAdvance
                  ? () async {
                      final result = await controller.advanceStage('ryomi');
                      if (result.storyEpisodeId != null) {
                        GameAudioHooks.emit(GameAudioCue.stageAdvance);
                      }
                      onResult(result, _RyomiV2Event.stage);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class RyomiSceneV2 extends StatelessWidget {
  const RyomiSceneV2({
    super.key,
    required this.controller,
    required this.onTap,
    this.floatingFeedback,
  });

  final GameController controller;
  final VoidCallback onTap;
  final Widget? floatingFeedback;

  @override
  Widget build(BuildContext context) => PopJournalCard(
    key: const ValueKey('ryomi_game_scene'),
    padding: EdgeInsets.zero,
    borderColor: ConnectionsColors.sand,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final portraitHeight = height * .84;
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: CustomPaint(painter: _RyomiStudioPainter())),
            Positioned(
              bottom: 10,
              child: Container(
                width: 170,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 16,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              key: const ValueKey('ryomi_character_tap_area'),
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: SizedBox(
                width: portraitHeight * .42,
                height: portraitHeight,
                child: Image.asset(
                  GameAssets.ryomiStage01,
                  key: const ValueKey('ryomi_official_art'),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  gaplessPlayback: true,
                ),
              ),
            ),
            if (floatingFeedback != null)
              Positioned(
                top: 78,
                right: 36,
                child: IgnorePointer(child: floatingFeedback!),
              ),
            Positioned(
              left: 18,
              bottom: 14,
              child: Text(
                '● NO AR  •  98.7 FM',
                style: ConnectionsTypography.caption.copyWith(
                  color: ConnectionsColors.relation,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _InteractionGridV2 extends StatefulWidget {
  const _InteractionGridV2({required this.controller, required this.onResult});

  final GameController controller;
  final void Function(ActionResult, _RyomiV2Event) onResult;

  @override
  State<_InteractionGridV2> createState() => _InteractionGridV2State();
}

class _InteractionGridV2State extends State<_InteractionGridV2> {
  Future<void> _talk() async => widget.onResult(
    await widget.controller.talk('ryomi'),
    _RyomiV2Event.talk,
  );

  Future<void> _interact() async => widget.onResult(
    await widget.controller.interact('ryomi'),
    _RyomiV2Event.interact,
  );

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.state.characters['ryomi']!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final talkLeft = _remaining(
      progress.lastTalkAt,
      IdleBalance.talkCooldown,
      now,
    );
    final interactLeft = _remaining(
      progress.lastInteractAt,
      IdleBalance.interactCooldown,
      now,
    );
    final count = IdleBalance.gifts.length;
    final dates = IdleBalance.encounters.length;
    final actions = [
      _ActionV2(
        'talk',
        'Conversar',
        '+${IdleBalance.talkAffectionReward} afeição',
        Icons.chat_bubble_rounded,
        ConnectionsColors.relation,
        ConnectionsColors.relationDark,
        _talk,
        Duration(seconds: talkLeft),
        IdleBalance.talkCooldown,
      ),
      _ActionV2(
        'interact',
        'Interagir',
        '+${IdleBalance.interactAffectionReward} afeição',
        Icons.back_hand_rounded,
        ConnectionsColors.interact,
        const Color(0xFF3B7B77),
        _interact,
        Duration(seconds: interactLeft),
        IdleBalance.interactCooldown,
      ),
      _ActionV2(
        'gift',
        'Presentear',
        '$count itens',
        Icons.card_giftcard_rounded,
        ConnectionsColors.plum,
        ConnectionsColors.achievementsDark,
        () => showGiftSelectionDialog(
          context,
          widget.controller,
          onDelivered: (result) => widget.onResult(result, _RyomiV2Event.gift),
        ),
        null,
        null,
      ),
      _ActionV2(
        'date',
        'Encontro',
        '$dates locais',
        Icons.confirmation_number_rounded,
        ConnectionsColors.honey,
        ConnectionsColors.shopDark,
        () => showDateSelectionDialog(
          context,
          widget.controller,
          onStarted: (result) =>
              widget.onResult(result, _RyomiV2Event.encounter),
        ),
        null,
        null,
      ),
    ];
    return Column(
      key: const ValueKey('interaction_grid_v2'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _action(actions[0]),
            const SizedBox(width: 8),
            _action(actions[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _action(actions[2]),
            const SizedBox(width: 8),
            _action(actions[3]),
          ],
        ),
      ],
    );
  }

  Expanded _action(_ActionV2 action) => Expanded(
    child: PopJournalButton(
      key: ValueKey('action_${action.id}'),
      label: action.label,
      subtitle: action.subtitle,
      icon: action.icon,
      color: action.color,
      darkColor: action.darkColor,
      height: 90,
      iconSize: 32,
      cooldownRemaining: action.cooldownRemaining,
      cooldownTotal: action.cooldownTotal,
      cooldownKey: ValueKey('action_${action.id}_cooldown'),
      onPressed: action.onPressed,
    ),
  );

  int _remaining(int lastAt, Duration cooldown, int now) {
    final value = lastAt + cooldown.inMilliseconds - now;
    return value <= 0 ? 0 : (value / 1000).ceil();
  }
}

class DialoguePanelV2 extends StatelessWidget {
  const DialoguePanelV2({
    super.key,
    required this.text,
    required this.minimized,
    required this.onToggle,
  });

  final String text;
  final bool minimized;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (minimized) {
      return Align(
        alignment: Alignment.centerLeft,
        child: PopJournalButton(
          key: const ValueKey('character_dialogue_restore'),
          label: 'Mostrar',
          subtitle: 'diálogo',
          icon: Icons.chat_bubble_rounded,
          color: ConnectionsColors.copper,
          darkColor: ConnectionsColors.speed,
          height: 56,
          iconSize: 24,
          onPressed: onToggle,
        ),
      );
    }
    return SizedBox(
      key: const ValueKey('character_dialogue_panel'),
      height: 145,
      child: PopJournalCard(
        padding: EdgeInsets.zero,
        borderColor: ConnectionsColors.copper,
        child: Column(
          key: const ValueKey('character_dialogue_panel_content'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 42,
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: const BoxDecoration(
                color: ConnectionsColors.copper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'RYOMI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('character_dialogue_minimize'),
                    tooltip: 'Ocultar diálogo',
                    onPressed: onToggle,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                child: Text(
                  '“$text”',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ConnectionsColors.ink,
                    fontSize: 15,
                    height: 1.28,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionV2 {
  const _ActionV2(
    this.id,
    this.label,
    this.subtitle,
    this.icon,
    this.color,
    this.darkColor,
    this.onPressed,
    this.cooldownRemaining,
    this.cooldownTotal,
  );

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color darkColor;
  final VoidCallback onPressed;
  final Duration? cooldownRemaining;
  final Duration? cooldownTotal;
}

class _Requirement {
  const _Requirement(this.icon, this.label, this.complete);
  final IconData icon;
  final String label;
  final bool complete;
}

List<_Requirement> _requirements(
  IdleState state,
  CharacterProgress progress,
  int needed,
) {
  final hobbyTarget = 1 + progress.stage ~/ 2;
  final favoriteHobby = IdleRules.favoriteHobby('ryomi');
  final hobbyLevel = state.hobbies[favoriteHobby]!.level;
  final moneyTarget = progress.stage * 80;
  final giftTarget = progress.stage ~/ 2;
  final encounterTarget = progress.stage ~/ 3;
  return [
    _Requirement(
      Icons.favorite_rounded,
      progress.affection >= needed
          ? 'Afeição pronta'
          : 'Afeição ${progress.affection.clamp(0, needed)} / $needed',
      progress.affection >= needed,
    ),
    _Requirement(
      Icons.music_note_rounded,
      hobbyLevel >= hobbyTarget
          ? 'Música nível $hobbyTarget'
          : 'Música nível $hobbyLevel / $hobbyTarget',
      hobbyLevel >= hobbyTarget,
    ),
    if (moneyTarget > 0)
      _Requirement(
        Icons.account_balance_wallet_rounded,
        state.totalMoneyEarned >= moneyTarget
            ? 'Renda suficiente'
            : 'Renda ${NumberFormatter.money(state.totalMoneyEarned)} / ${NumberFormatter.money(moneyTarget)}',
        state.totalMoneyEarned >= moneyTarget,
      ),
    if (giftTarget > 0)
      _Requirement(
        Icons.card_giftcard_rounded,
        progress.gifts >= giftTarget
            ? (giftTarget == 1 ? 'Presente entregue' : '$giftTarget presentes')
            : 'Presentes ${math.min(progress.gifts, giftTarget)} / $giftTarget',
        progress.gifts >= giftTarget,
      ),
    if (encounterTarget > 0)
      _Requirement(
        Icons.nightlife_rounded,
        progress.encounters >= encounterTarget
            ? (encounterTarget == 1
                  ? 'Encontro realizado'
                  : '$encounterTarget encontros')
            : 'Encontros ${math.min(progress.encounters, encounterTarget)} / $encounterTarget',
        progress.encounters >= encounterTarget,
      ),
  ];
}

class _CheckpointTrackV2 extends StatelessWidget {
  const _CheckpointTrackV2({
    required this.currentStage,
    required this.progress,
  });
  final int currentStage;
  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('relationship_checkpoint_bar'),
    height: 34,
    child: Row(
      children: [
        for (var i = 0; i < IdleRules.totalRelationshipStages; i++) ...[
          _CheckpointDotV2(
            index: i,
            current: i == currentStage,
            complete: i < currentStage || (i == currentStage && progress >= 1),
          ),
          if (i < IdleRules.totalRelationshipStages - 1)
            Expanded(
              child: Container(
                height: 7,
                color: i < currentStage
                    ? ConnectionsColors.relation
                    : ConnectionsColors.sand,
              ),
            ),
        ],
      ],
    ),
  );
}

class _CheckpointDotV2 extends StatelessWidget {
  const _CheckpointDotV2({
    required this.index,
    required this.current,
    required this.complete,
  });
  final int index;
  final bool current;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final size = current
        ? 29.0
        : complete
        ? 20.0
        : 17.0;
    return AnimatedContainer(
      key: ValueKey('relationship_checkpoint_$index'),
      duration: ConnectionsMotion.progress,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: complete || current ? ConnectionsColors.relation : Colors.white,
        border: Border.all(color: ConnectionsColors.relationDark, width: 2),
      ),
      child: complete
          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
          : current
          ? const Icon(Icons.favorite_rounded, size: 15, color: Colors.white)
          : Text(
              '${index + 1}',
              style: const TextStyle(
                color: ConnectionsColors.relationDark,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _AffectionBarV2 extends StatelessWidget {
  const _AffectionBarV2({required this.progress, required this.value});
  final double progress;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Icon(Icons.favorite_rounded, color: ConnectionsColors.relation),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('Afeição', style: ConnectionsTypography.label),
          ),
          Text(
            value,
            key: const ValueKey('relationship_affection_value'),
            style: ConnectionsTypography.label,
          ),
        ],
      ),
      const SizedBox(height: 5),
      Container(
        key: const ValueKey('relationship_affection_bar'),
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: ConnectionsColors.outline,
          borderRadius: BorderRadius.circular(ConnectionsRadius.pill),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ConnectionsRadius.pill),
                ),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: ConnectionsMotion.progress,
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0).toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ConnectionsColors.relation,
                  borderRadius: BorderRadius.circular(ConnectionsRadius.pill),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _JournalLabel extends StatelessWidget {
  const _JournalLabel({
    required this.icon,
    required this.text,
    required this.keyValue,
  });
  final IconData icon;
  final String text;
  final String keyValue;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey(keyValue),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(ConnectionsRadius.md),
      border: Border.all(color: ConnectionsColors.sand, width: 2),
    ),
    child: Row(
      children: [
        Icon(icon, color: ConnectionsColors.relation),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ConnectionsTypography.label,
          ),
        ),
      ],
    ),
  );
}

class _RequirementChipV2 extends StatelessWidget {
  const _RequirementChipV2({required this.item});
  final _Requirement item;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: item.complete
          ? ConnectionsColors.success.withValues(alpha: .16)
          : Colors.white,
      borderRadius: BorderRadius.circular(ConnectionsRadius.md),
      border: Border.all(
        color: item.complete
            ? ConnectionsColors.success
            : ConnectionsColors.sand,
        width: 2,
      ),
    ),
    child: Row(
      children: [
        Icon(
          item.complete ? Icons.check_circle_rounded : item.icon,
          color: item.complete
              ? ConnectionsColors.success
              : ConnectionsColors.relation,
          size: 22,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ConnectionsTypography.caption.copyWith(
              color: item.complete
                  ? ConnectionsColors.success
                  : ConnectionsColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SelectorPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ConnectionsColors.beige.withValues(alpha: .65);
    for (var y = 130.0; y < size.height; y += 62) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(16, y, size.width - 32, 24),
          const Radius.circular(12),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RyomiStudioPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ConnectionsColors.tealNight, Color(0xFF466B70)],
          ).createShader(
            Rect.fromLTWH(
              size.width * .14,
              size.height * .08,
              size.width * .72,
              size.height * .48,
            ),
          );
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .12,
        size.height * .08,
        size.width * .76,
        size.height * .50,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(panel, bg);
    final line = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = ConnectionsColors.copper.withValues(alpha: .72);
    for (var i = 0; i < 30; i++) {
      final x = size.width * .16 + i * size.width * .023;
      final h = 18 + (i % 5) * 8;
      canvas.drawLine(
        Offset(x, size.height * .38 - h / 2),
        Offset(x, size.height * .38 + h / 2),
        line,
      );
    }
    final glow = Paint()..color = Colors.white.withValues(alpha: .30);
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .54),
      size.height * .28,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
