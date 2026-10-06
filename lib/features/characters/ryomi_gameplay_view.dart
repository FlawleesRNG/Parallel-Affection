import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/character_catalog.dart';
import '../../core/idle_rules.dart';
import '../../core/number_formatter.dart';
import '../../core/theme/game_tokens.dart';
import '../../core/theme/visual_themes.dart';
import '../../data/idle_balance.dart';
import '../../models/idle_models.dart';
import '../../services/game_audio_hooks.dart';
import '../../shared/game_ui.dart';
import 'date_selection_dialog.dart';
import 'gift_selection_dialog.dart';

enum _RyomiEvent { tap, talk, interact, gift, encounter, stage }

/// A cena principal é intencionalmente um palco contínuo; os dados de jogo
/// aparecem como HUDs pequenos sobre o estúdio, nunca como colunas de cards.
class RyomiGameplayView extends StatefulWidget {
  const RyomiGameplayView({super.key, required this.controller});

  final GameController controller;

  @override
  State<RyomiGameplayView> createState() => _RyomiGameplayViewState();
}

class _RyomiGameplayViewState extends State<RyomiGameplayView>
    with SingleTickerProviderStateMixin {
  late String line;
  String? floatingText;
  Color floatingColor = GameColors.coral;
  int feedbackSequence = 0;
  int tapFeedbackTotal = 0;
  int encounterCount = 0;
  bool requirementsOpen = false;
  bool dialogueOpen = true;
  Timer? cooldownTimer;
  Timer? tapFeedbackResetTimer;
  late final AnimationController ambience;

  @override
  void initState() {
    super.initState();
    final progress = widget.controller.state.characters['ryomi']!;
    line = IdleRules.currentLine('ryomi', progress.stage);
    encounterCount = progress.encounters;
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    ambience = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    // Repetições impedem pumpAndSettle; em testes a cena permanece estática.
    if (!_runningWidgetTest) ambience.repeat(reverse: true);
  }

  bool get _runningWidgetTest {
    var test = false;
    assert(() {
      test = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      return true;
    }());
    return test;
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    tapFeedbackResetTimer?.cancel();
    ambience.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.state.characters['ryomi']!;
    if (progress.encounters > encounterCount) {
      encounterCount = progress.encounters;
      line = 'â€œA noite passou rÃ¡pido. Vamos guardar essa frequÃªncia.â€';
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final low = constraints.maxHeight < 540;
        return AnimatedBuilder(
          animation: ambience,
          builder: (context, _) => _RyomiGameScene(
            controller: widget.controller,
            line: line,
            phase: ambience.value,
            compact: compact,
            low: low,
            requirementsOpen: requirementsOpen,
            dialogueOpen: dialogueOpen,
            floatingFeedback: _feedback(),
            onRequirementsToggle: () =>
                setState(() => requirementsOpen = !requirementsOpen),
            onDialogueToggle: () =>
                setState(() => dialogueOpen = !dialogueOpen),
            onResult: _handleResult,
          ),
        );
      },
    );
  }

  Widget? _feedback() {
    if (floatingText == null) return null;
    return FloatingRewardText(
      key: ValueKey(feedbackSequence),
      text: floatingText!,
      color: floatingColor,
      onFinished: () {
        if (mounted) setState(() => floatingText = null);
      },
    );
  }

  void _handleResult(ActionResult result, _RyomiEvent event) {
    final reward = RegExp(r'\+\d+[^.]*').firstMatch(result.message)?.group(0);
    final cooldown = result.message.startsWith('Aguarde');
    final success = switch (event) {
      _RyomiEvent.tap => reward != null,
      _RyomiEvent.talk || _RyomiEvent.interact => reward != null,
      _RyomiEvent.gift => result.message.contains('entregue(s): +'),
      _RyomiEvent.encounter => result.message.contains('iniciado.'),
      _RyomiEvent.stage => result.message.startsWith('Novo estágio:'),
    };
    setState(() {
      line = switch (event) {
        _RyomiEvent.tap => line,
        _RyomiEvent.talk =>
          cooldown
              ? 'â€œCalma... deixa a prÃ³xima mÃºsica comeÃ§ar.â€'
              : success
              ? 'â€œVocÃª presta atenÃ§Ã£o atÃ© nas pausas. Eu gosto disso.â€'
              : 'â€œNÃ£o foi dessa vez. Vamos tentar em outro momento.â€',
        _RyomiEvent.interact =>
          cooldown
              ? 'â€œEi, sem atropelar o ritmo.â€'
              : success
              ? 'â€œEsse gesto foi inesperado... mas nÃ£o ruim.â€'
              : 'â€œTalvez seja melhor esperar um pouco.â€',
        _RyomiEvent.gift =>
          success
              ? 'â€œVocÃª lembrou de mim? Vou guardar com carinho.â€'
              : 'â€œParece que ainda falta alguma coisa para esse presente.â€',
        _RyomiEvent.encounter =>
          success
              ? 'â€œEntÃ£o estÃ¡ combinado. Encontro vocÃª depois do programa.â€'
              : 'â€œMelhor conferir os requisitos primeiro.â€',
        _RyomiEvent.stage =>
          success
              ? 'â€œParece que nossa frequÃªncia mudou de novo.â€'
              : 'â€œAinda temos um caminho antes da prÃ³xima fase.â€',
      };
      if (reward != null) {
        if (event == _RyomiEvent.tap) {
          final gain =
              int.tryParse(RegExp(r'\d+').firstMatch(reward)?.group(0) ?? '') ??
              1;
          tapFeedbackTotal += gain;
          floatingText = '♥ +$tapFeedbackTotal';
          tapFeedbackResetTimer?.cancel();
          tapFeedbackResetTimer = Timer(const Duration(milliseconds: 520), () {
            if (mounted) setState(() => tapFeedbackTotal = 0);
          });
        } else {
          tapFeedbackTotal = 0;
          floatingText = reward;
        }
        floatingColor = event == _RyomiEvent.gift
            ? GameColors.magenta
            : event == _RyomiEvent.interact
            ? GameColors.cyan
            : GameColors.coral;
        feedbackSequence++;
      }
    });
    if (event == _RyomiEvent.stage && result.storyEpisodeId != null) {
      showGameResult(context, result);
    }
  }
}

class _RyomiGameScene extends StatelessWidget {
  const _RyomiGameScene({
    required this.controller,
    required this.line,
    required this.phase,
    required this.compact,
    required this.low,
    required this.requirementsOpen,
    required this.dialogueOpen,
    required this.onRequirementsToggle,
    required this.onDialogueToggle,
    required this.onResult,
    this.floatingFeedback,
  });

  final GameController controller;
  final String line;
  final double phase;
  final bool compact;
  final bool low;
  final bool requirementsOpen;
  final bool dialogueOpen;
  final Widget? floatingFeedback;
  final VoidCallback onRequirementsToggle;
  final VoidCallback onDialogueToggle;
  final void Function(ActionResult, _RyomiEvent) onResult;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final progress = state.characters['ryomi']!;
    const characterTheme = RyomiVisualTheme.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 800;
        if (mobile) {
          return SingleChildScrollView(
            key: const ValueKey('ryomi_relationship_mobile_layout'),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              children: [
                _CharacterSelectorRail(
                  progress: progress,
                  compact: true,
                  theme: characterTheme,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: math.max(330, constraints.maxHeight * .48),
                  child: _RyomiCharacterStage(
                    progress: progress,
                    target: IdleBalance.affectionNeeded(progress.stage),
                    phase: phase,
                    compact: true,
                    floatingFeedback: floatingFeedback,
                    onCharacterTap: () async => onResult(
                      await controller.tapCharacter('ryomi'),
                      _RyomiEvent.tap,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _SceneActionControls(
                  controller: controller,
                  onResult: onResult,
                ),
                const SizedBox(height: 10),
                CharacterDialoguePanel(
                  name: 'Ryomi',
                  text: line,
                  theme: characterTheme,
                  minimized: !dialogueOpen,
                  onToggleMinimized: onDialogueToggle,
                ),
                const SizedBox(height: 10),
                _RelationshipProgressPanel(
                  controller: controller,
                  open: true,
                  theme: characterTheme,
                  onToggle: onRequirementsToggle,
                  onAdvance: (result) => onResult(result, _RyomiEvent.stage),
                ),
              ],
            ),
          );
        }
        final wide = constraints.maxWidth >= 1400;
        final selectorWidth = wide ? 210.0 : 190.0;
        final progressWidth = wide ? 340.0 : 310.0;
        final controlsWidth = wide ? 340.0 : 310.0;
        final gap = wide ? 10.0 : 8.0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            key: const ValueKey('ryomi_relationship_desktop_layout'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: selectorWidth,
                child: SizedBox.expand(
                  key: const ValueKey('character_selector_region'),
                  child: _CharacterSelectorRail(
                    progress: progress,
                    compact: false,
                    theme: characterTheme,
                  ),
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: progressWidth,
                child: SizedBox.expand(
                  key: const ValueKey('relationship_progress_region'),
                  child: _RelationshipProgressPanel(
                    controller: controller,
                    open: requirementsOpen,
                    theme: characterTheme,
                    onToggle: onRequirementsToggle,
                    onAdvance: (result) => onResult(result, _RyomiEvent.stage),
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: SizedBox.expand(
                  key: const ValueKey('character_presentation_region'),
                  child: _RyomiCharacterStage(
                    progress: progress,
                    target: IdleBalance.affectionNeeded(progress.stage),
                    phase: phase,
                    compact: compact,
                    floatingFeedback: floatingFeedback,
                    onCharacterTap: () async => onResult(
                      await controller.tapCharacter('ryomi'),
                      _RyomiEvent.tap,
                    ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: controlsWidth,
                child: SizedBox.expand(
                  key: const ValueKey('character_controls_area'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 46,
                        child: SizedBox.expand(
                          key: const ValueKey('interaction_controls_region'),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SafeArea(
                              top: false,
                              left: false,
                              right: false,
                              minimum: EdgeInsets.only(bottom: low ? 0 : 2),
                              child: _SceneActionControls(
                                controller: controller,
                                onResult: onResult,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: gap),
                      Expanded(
                        flex: 50,
                        child: SizedBox.expand(
                          key: const ValueKey('character_dialogue_region'),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: CharacterDialoguePanel(
                              name: 'Ryomi',
                              text: line,
                              theme: characterTheme,
                              minimized: !dialogueOpen,
                              onToggleMinimized: onDialogueToggle,
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
      },
    );
  }
}

class _RyomiCharacterStage extends StatelessWidget {
  const _RyomiCharacterStage({
    required this.progress,
    required this.target,
    required this.phase,
    required this.compact,
    this.floatingFeedback,
    this.onCharacterTap,
  });

  final CharacterProgress progress;
  final int target;
  final double phase;
  final bool compact;
  final Widget? floatingFeedback;
  final VoidCallback? onCharacterTap;

  @override
  Widget build(BuildContext context) {
    const characterTheme = RyomiVisualTheme.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final maxPortraitHeight = compact
            ? math.min(size.height * .92, 500.0)
            : math.min(size.height * .98, 720.0);
        final maxPortraitWidth = size.width * (compact ? .92 : .94);
        final portraitHeight = math.min(
          maxPortraitHeight,
          maxPortraitWidth / .66,
        );
        final portraitWidth = portraitHeight * .66;
        final portraitX = (size.width - portraitWidth) * .5;
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            key: const ValueKey('ryomi_game_scene'),
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: characterTheme.sceneGradient,
                ),
              ),
              CustomPaint(
                painter: _RadioStudioPainter(
                  phase: phase,
                  theme: characterTheme,
                ),
                child: const SizedBox.expand(),
              ),
              Positioned(
                left: portraitX,
                bottom: 0,
                width: portraitWidth,
                height: portraitHeight,
                child: GestureDetector(
                  key: const ValueKey('ryomi_character_tap_area'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onCharacterTap,
                  child: _RyomiCharacterVisual(phase: phase),
                ),
              ),
              Positioned(
                left: compact ? 8 : portraitX + portraitWidth * .14,
                bottom: compact ? 28 : 92,
                child: IgnorePointer(child: floatingFeedback),
              ),
              const Positioned(
                left: 18,
                bottom: 14,
                child: IgnorePointer(child: _StudioSignature()),
              ),
              if (progress.affection >= target)
                Positioned(
                  right: compact ? 12 : 22,
                  top: compact ? 12 : 18,
                  child: const _FrequencyReadyGlow(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CharacterSelectorRail extends StatelessWidget {
  const _CharacterSelectorRail({
    required this.progress,
    required this.compact,
    required this.theme,
  });

  final CharacterProgress progress;
  final bool compact;
  final CharacterVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final card = _HorizontalCharacterSelectorCard(
      progress: progress,
      theme: theme,
    );
    if (compact) {
      return SizedBox(
        key: const ValueKey('character_selector_region'),
        width: double.infinity,
        child: card,
      );
    }
    return GamePanel(
      key: const ValueKey('character_selector_panel'),
      padding: const EdgeInsets.all(9),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameColors.blush.withValues(alpha: .94),
          GameColors.oat.withValues(alpha: .92),
          Color.lerp(theme.relationshipAccent, Colors.white, .82)!,
        ],
      ),
      borderColor: theme.relationshipAccent.withValues(alpha: .55),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SelectorRailPattern(accent: theme.relationshipAccent),
              ),
            ),
          ),
          SingleChildScrollView(
            key: const ValueKey('character_selector_list'),
            child: Column(children: [card]),
          ),
        ],
      ),
    );
  }
}

class _SelectorRailPattern extends CustomPainter {
  const _SelectorRailPattern({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = accent.withValues(alpha: .08);
    for (var y = 118.0; y < size.height; y += 62) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(8, y, size.width - 16, 24),
          const Radius.circular(18),
        ),
        paint,
      );
    }
    final heart = Paint()..color = accent.withValues(alpha: .10);
    for (var y = 150.0; y < size.height; y += 104) {
      canvas.drawCircle(Offset(size.width * .5, y), 5, heart);
    }
  }

  @override
  bool shouldRepaint(covariant _SelectorRailPattern oldDelegate) =>
      oldDelegate.accent != accent;
}

class _HorizontalCharacterSelectorCard extends StatelessWidget {
  const _HorizontalCharacterSelectorCard({
    required this.progress,
    required this.theme,
  });

  final CharacterProgress progress;
  final CharacterVisualTheme theme;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('character_selector_ryomi'),
    height: 84,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .92),
            GameColors.blush.withValues(alpha: .84),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.relationshipAccent, width: 2.6),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(
              theme.relationshipAccent,
              GameColors.ink,
              .35,
            )!.withValues(alpha: .18),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.relationshipAccent.withValues(alpha: .22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    key: const ValueKey('character_selector_portrait'),
                    width: 68,
                    height: double.infinity,
                    color: GameColors.oat,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        GameAssets.ryomiStage01,
                        width: 88,
                        height: 252,
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    key: const ValueKey('character_selector_new_badge'),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: GameColors.relation,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ryomi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: GameColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    IdleRules.stageName(progress.stage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.relationshipAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: theme.relationshipAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.relationshipAccent.withValues(
                                alpha: .46,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Flexible(
                        child: Text(
                          'Selecionada',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: GameColors.softInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ignore: unused_element
class _ArcadeRelationshipProgressPanel extends StatelessWidget {
  const _ArcadeRelationshipProgressPanel({
    required this.controller,
    required this.open,
    required this.theme,
    required this.onToggle,
    required this.onAdvance,
  });

  final GameController controller;
  final bool open;
  final CharacterVisualTheme theme;
  final VoidCallback onToggle;
  final ValueChanged<ActionResult> onAdvance;

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
    final routePercent = IdleRules.routeProgressPercent(progress);
    final maxStage = currentStage >= IdleRules.totalRelationshipStages - 1;
    final nextStageName = maxStage
        ? 'Rota concluída'
        : IdleRules.stageName(currentStage + 1);
    final requirements = _relationshipRequirements(state, progress, needed);
    final visibleRequirements = requirements.take(open ? 5 : 3).toList();
    final pending = requirements.where((item) => !item.complete).toList();
    final canAdvance = IdleRules.canAdvance(state, 'ryomi');
    final blockedLabel = pending.isEmpty
        ? 'Avanço disponível'
        : 'Falta: ${pending.first.label}';
    final accent = theme.relationshipAccent;
    final deep = Color.lerp(accent, GameColors.ink, .35)!;

    return SizedBox(
      key: const ValueKey('relationship_progress_panel'),
      height: 520,
      child: Stack(
        children: [
          Positioned.fill(
            top: 7,
            left: 5,
            right: 3,
            bottom: 0,
            child: ClipPath(
              clipper: const ArcadePanelClipper(),
              child: ColoredBox(color: deep.withValues(alpha: .46)),
            ),
          ),
          Positioned.fill(
            bottom: 8,
            child: PhysicalShape(
              clipper: const ArcadePanelClipper(),
              color: GameColors.paper,
              elevation: 10,
              shadowColor: deep.withValues(alpha: .45),
              child: ClipPath(
                clipper: const ArcadePanelClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        GameColors.blush.withValues(alpha: .94),
                        Color.lerp(accent, Colors.white, .78)!,
                      ],
                    ),
                    border: Border.all(color: deep, width: 3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ArcadeRelationshipHeader(
                        stage: currentStage,
                        percent: routePercent,
                        stageName: IdleRules.stageName(currentStage),
                        accent: accent,
                        deep: deep,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ArcadeCheckpointTrack(
                                currentStage: currentStage,
                                totalStages: IdleRules.totalRelationshipStages,
                                progress: stageProgress,
                                accent: accent,
                              ),
                              const SizedBox(height: 12),
                              _ArcadeAffectionBar(
                                value:
                                    '${progress.affection.clamp(0, needed)} / $needed',
                                progress: stageProgress,
                                accent: accent,
                                deep: deep,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  11,
                                  8,
                                  11,
                                  9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .80),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: deep.withValues(alpha: .28),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag_rounded,
                                      color: accent,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        'Próxima: ${nextStageName.toUpperCase()}',
                                        key: const ValueKey(
                                          'relationship_next_stage',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: GameColors.ink,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                key: const ValueKey('requirements_toggle'),
                                onTap: onToggle,
                                child: Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.lerp(accent, Colors.white, .42)!,
                                        accent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: deep, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: deep.withValues(alpha: .20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'OBJETIVOS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            letterSpacing: .5,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black38,
                                                blurRadius: 3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        open
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSize(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 180),
                                child: Column(
                                  children: [
                                    for (final item in visibleRequirements)
                                      _ArcadeRequirementObjective(
                                        item: item,
                                        accent: accent,
                                        deep: deep,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 0, 13, 13),
                        child: _ArcadeAdvanceButton(
                          canAdvance: canAdvance,
                          label: canAdvance ? 'Avançar relação' : blockedLabel,
                          accent: accent,
                          deep: deep,
                          onPressed: canAdvance
                              ? () async {
                                  final result = await controller.advanceStage(
                                    'ryomi',
                                  );
                                  if (result.storyEpisodeId != null) {
                                    GameAudioHooks.emit(
                                      GameAudioCue.stageAdvance,
                                    );
                                  }
                                  onAdvance(result);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeRelationshipHeader extends StatelessWidget {
  const _ArcadeRelationshipHeader({
    required this.stage,
    required this.percent,
    required this.stageName,
    required this.accent,
    required this.deep,
  });

  final int stage;
  final int percent;
  final String stageName;
  final Color accent;
  final Color deep;

  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    padding: const EdgeInsets.fromLTRB(16, 12, 13, 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(accent, Colors.white, .25)!, accent, deep],
      ),
      border: Border(bottom: BorderSide(color: deep, width: 3)),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: deep, width: 3),
            boxShadow: [
              BoxShadow(
                color: deep.withValues(alpha: .30),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.favorite_rounded, color: accent, size: 34),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 260,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'RYOMI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: .8,
                            shadows: [
                              Shadow(
                                color: Color(0x88000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(GameRadii.pill),
                          border: Border.all(color: deep, width: 2),
                        ),
                        child: Text(
                          '$percent%',
                          key: const ValueKey('relationship_route_percent'),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Etapa ${stage + 1} de ${IdleRules.totalRelationshipStages}',
                    key: const ValueKey('relationship_stage_count'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    stageName.toUpperCase(),
                    key: const ValueKey('relationship_stage_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArcadeCheckpointTrack extends StatelessWidget {
  const _ArcadeCheckpointTrack({
    required this.currentStage,
    required this.totalStages,
    required this.progress,
    required this.accent,
  });

  final int currentStage;
  final int totalStages;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('relationship_checkpoint_bar'),
    height: 38,
    child: Row(
      children: [
        for (var index = 0; index < totalStages; index++) ...[
          _ArcadeCheckpoint(
            index: index,
            active: index == currentStage,
            complete:
                index < currentStage ||
                (index == currentStage && progress >= 1),
            accent: accent,
          ),
          if (index < totalStages - 1)
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: index < currentStage
                      ? accent
                      : GameColors.outlineSoft.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(GameRadii.pill),
                  border: Border.all(
                    color: GameColors.ink.withValues(alpha: .12),
                  ),
                ),
              ),
            ),
        ],
      ],
    ),
  );
}

class _ArcadeCheckpoint extends StatelessWidget {
  const _ArcadeCheckpoint({
    required this.index,
    required this.active,
    required this.complete,
    required this.accent,
  });

  final int index;
  final bool active;
  final bool complete;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final size = active ? 31.0 : (complete ? 21.0 : 18.0);
    return AnimatedContainer(
      key: ValueKey('relationship_checkpoint_$index'),
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: complete || active ? accent : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: complete || active
              ? Color.lerp(accent, GameColors.ink, .26)!
              : accent.withValues(alpha: .45),
          width: active ? 4 : 3,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: .45),
                  blurRadius: 13,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: complete
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : active
          ? const Icon(Icons.favorite_rounded, size: 17, color: Colors.white)
          : Text(
              '${index + 1}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 8,
              ),
            ),
    );
  }
}

class _ArcadeAffectionBar extends StatelessWidget {
  const _ArcadeAffectionBar({
    required this.value,
    required this.progress,
    required this.accent,
    required this.deep,
  });

  final String value;
  final double progress;
  final Color accent;
  final Color deep;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.favorite_rounded, color: accent, size: 24),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'AFETO',
              style: TextStyle(
                color: GameColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: .5,
              ),
            ),
          ),
          Text(
            value,
            key: const ValueKey('relationship_affection_value'),
            style: const TextStyle(
              color: GameColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Container(
        key: const ValueKey('relationship_affection_bar'),
        height: ArcadeRebuildMetrics.affectionBarHeight,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: deep,
          borderRadius: BorderRadius.circular(GameRadii.pill),
          border: Border.all(color: deep, width: 3),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(GameRadii.pill),
                ),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0).toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(accent, Colors.white, .25)!,
                      accent,
                      Color.lerp(accent, GameColors.ink, .15)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(GameRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .55),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ArcadeRequirementObjective extends StatelessWidget {
  const _ArcadeRequirementObjective({
    required this.item,
    required this.accent,
    required this.deep,
  });

  final _Requirement item;
  final Color accent;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    final color = item.complete ? GameColors.success : accent;
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
      decoration: BoxDecoration(
        color: item.complete
            ? GameColors.success.withValues(alpha: .13)
            : Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .55), width: 2),
        boxShadow: [
          BoxShadow(
            color: deep.withValues(alpha: .10),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            item.complete ? Icons.check_circle_rounded : item.icon,
            color: color,
            size: 23,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.complete ? GameColors.success : GameColors.ink,
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeAdvanceButton extends StatelessWidget {
  const _ArcadeAdvanceButton({
    required this.canAdvance,
    required this.label,
    required this.accent,
    required this.deep,
    required this.onPressed,
  });

  final bool canAdvance;
  final String label;
  final Color accent;
  final Color deep;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('advance_relationship'),
    onTap: onPressed,
    child: SizedBox(
      height: 54,
      child: Stack(
        children: [
          Positioned(
            left: 3,
            right: 3,
            bottom: 0,
            height: 46,
            child: ClipPath(
              clipper: const ArcadePieceClipper(skew: 8),
              child: ColoredBox(color: deep.withValues(alpha: .55)),
            ),
          ),
          Positioned.fill(
            bottom: 7,
            child: PhysicalShape(
              clipper: const ArcadePieceClipper(skew: 8),
              color: canAdvance ? accent : GameColors.roseBeige,
              elevation: canAdvance ? 8 : 5,
              child: ClipPath(
                clipper: const ArcadePieceClipper(skew: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: canAdvance
                          ? [
                              Color.lerp(accent, Colors.white, .32)!,
                              accent,
                              deep,
                            ]
                          : [
                              GameColors.roseBeige,
                              GameColors.sand,
                              GameColors.outlineSoft,
                            ],
                    ),
                    border: Border.all(
                      color: canAdvance ? Colors.white : GameColors.outlineSoft,
                      width: 4,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canAdvance
                            ? Icons.favorite_rounded
                            : Icons.lock_rounded,
                        color: canAdvance ? Colors.white : GameColors.softInk,
                        size: 23,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: canAdvance
                                ? Colors.white
                                : GameColors.softInk,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            shadows: canAdvance
                                ? const [
                                    Shadow(
                                      color: Color(0x88000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
class _RelationshipProgressPanel extends StatelessWidget {
  const _RelationshipProgressPanel({
    required this.controller,
    required this.open,
    required this.theme,
    required this.onToggle,
    required this.onAdvance,
  });

  final GameController controller;
  final bool open;
  final CharacterVisualTheme theme;
  final VoidCallback onToggle;
  final ValueChanged<ActionResult> onAdvance;

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
    final routePercent = IdleRules.routeProgressPercent(progress);
    final maxStage = currentStage >= IdleRules.totalRelationshipStages - 1;
    final nextStageName = maxStage
        ? 'Rota concluída'
        : IdleRules.stageName(currentStage + 1);
    final requirements = _relationshipRequirements(state, progress, needed);
    final visibleRequirements = requirements.take(5).toList();
    final pending = requirements.where((item) => !item.complete).toList();
    final canAdvance = IdleRules.canAdvance(state, 'ryomi');
    final blockedLabel = pending.isEmpty
        ? 'Avanço disponível'
        : 'Falta: ${pending.first.label}';
    return GamePanel(
      key: const ValueKey('relationship_progress_panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GameColors.oat.withValues(alpha: .96),
          GameColors.blush.withValues(alpha: .94),
          Color.lerp(theme.relationshipAccent, Colors.white, .86)!,
        ],
      ),
      borderColor: theme.relationshipAccent.withValues(alpha: .62),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ryomi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: GameColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.relationshipAccent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(GameRadii.pill),
                  ),
                  child: Text(
                    '$routePercent%',
                    key: const ValueKey('relationship_route_percent'),
                    style: TextStyle(
                      color: theme.relationshipAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Etapa ${currentStage + 1} de ${IdleRules.totalRelationshipStages}',
              key: const ValueKey('relationship_stage_count'),
              style: const TextStyle(
                color: GameColors.softInk,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              IdleRules.stageName(currentStage).toUpperCase(),
              key: const ValueKey('relationship_stage_title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.relationshipAccent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 10),
            RelationshipCheckpointBar(
              currentStage: currentStage,
              totalStages: IdleRules.totalRelationshipStages,
              stageProgress: stageProgress,
              stageNames: [
                for (var i = 0; i < IdleRules.totalRelationshipStages; i++)
                  IdleRules.stageName(i),
              ],
              accent: theme.relationshipAccent,
            ),
            const SizedBox(height: 12),
            _MiniProgressLabel(
              title: 'Afeição',
              value: '${progress.affection.clamp(0, needed)} / $needed',
              progress: stageProgress,
              accent: theme.relationshipAccent,
            ),
            const SizedBox(height: 10),
            Text(
              'Próxima etapa:',
              style: const TextStyle(
                color: GameColors.softInk,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              nextStageName.toUpperCase(),
              key: const ValueKey('relationship_next_stage'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GameColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              key: const ValueKey('requirements_toggle'),
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Requisitos',
                        style: TextStyle(
                          color: GameColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.relationshipAccent,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: open
                  ? Column(
                      children: [
                        for (final item in visibleRequirements)
                          _RequirementLine(
                            item,
                            accent: theme.relationshipAccent,
                          ),
                      ],
                    )
                  : Column(
                      children: [
                        for (final item in visibleRequirements.take(3))
                          _RequirementLine(
                            item,
                            accent: theme.relationshipAccent,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('advance_relationship'),
                onPressed: canAdvance
                    ? () async {
                        final result = await controller.advanceStage('ryomi');
                        if (result.storyEpisodeId != null) {
                          GameAudioHooks.emit(GameAudioCue.stageAdvance);
                        }
                        onAdvance(result);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.relationshipAccent,
                  disabledBackgroundColor: GameColors.roseBeige,
                  disabledForegroundColor: GameColors.softInk,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameRadii.pill),
                  ),
                ),
                icon: Icon(
                  canAdvance ? Icons.favorite_rounded : Icons.lock_rounded,
                  size: 18,
                ),
                label: Text(
                  canAdvance ? 'Avançar relação' : blockedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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

class _MiniProgressLabel extends StatelessWidget {
  const _MiniProgressLabel({
    required this.title,
    required this.value,
    required this.progress,
    required this.accent,
  });

  final String title;
  final String value;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: GameColors.softInk,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            key: const ValueKey('relationship_affection_value'),
            style: const TextStyle(
              color: GameColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Container(
        key: const ValueKey('relationship_affection_bar'),
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Color.lerp(accent, GameColors.ink, .35),
          borderRadius: BorderRadius.circular(GameRadii.pill),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .24),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(GameRadii.pill),
                ),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0).toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(accent, Colors.white, .28)!,
                      accent,
                      Color.lerp(accent, GameColors.ink, .16)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(GameRadii.pill),
                ),
              ),
            ),
            const Positioned(
              left: 7,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

List<_Requirement> _relationshipRequirements(
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
  final items = <_Requirement>[
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
  ];
  if (moneyTarget > 0) {
    items.add(
      _Requirement(
        Icons.account_balance_wallet_rounded,
        state.totalMoneyEarned >= moneyTarget
            ? 'Renda suficiente'
            : 'Renda ${NumberFormatter.money(state.totalMoneyEarned)} / ${NumberFormatter.money(moneyTarget)}',
        state.totalMoneyEarned >= moneyTarget,
      ),
    );
  }
  if (giftTarget > 0) {
    items.add(
      _Requirement(
        Icons.card_giftcard_rounded,
        progress.gifts >= giftTarget
            ? (giftTarget == 1 ? 'Presente entregue' : '$giftTarget presentes')
            : 'Presentes ${math.min(progress.gifts, giftTarget)} / $giftTarget',
        progress.gifts >= giftTarget,
      ),
    );
  }
  if (encounterTarget > 0) {
    items.add(
      _Requirement(
        Icons.nightlife_rounded,
        progress.encounters >= encounterTarget
            ? (encounterTarget == 1
                  ? 'Encontro realizado'
                  : '$encounterTarget encontros')
            : 'Encontros ${math.min(progress.encounters, encounterTarget)} / $encounterTarget',
        progress.encounters >= encounterTarget,
      ),
    );
  }
  return items;
}

// ignore: unused_element
class _ActiveCharacterSeal extends StatelessWidget {
  const _ActiveCharacterSeal({required this.progress, required this.theme});

  final CharacterProgress progress;
  final CharacterVisualTheme theme;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Personagem ativa: Ryomi',
    child: Container(
      width: 138,
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: GameColors.paper.withValues(alpha: .90),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(color: theme.sceneAccent.withValues(alpha: .65)),
        boxShadow: [
          BoxShadow(
            color: GameColors.brownShadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.roseBeige,
              border: Border.all(color: theme.sceneAccent, width: 1.5),
            ),
            child: Icon(
              Icons.headphones_rounded,
              color: theme.sceneAccent,
              size: 25,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RYOMI',
                  style: TextStyle(
                    color: GameColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  IdleRules.stageName(progress.stage).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.sceneAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.favorite_rounded, color: theme.sceneAccent, size: 12),
        ],
      ),
    ),
  );
}

// ignore: unused_element
class _RelationshipTuner extends StatelessWidget {
  const _RelationshipTuner({
    required this.controller,
    required this.theme,
    required this.open,
    required this.onToggle,
    required this.onAdvance,
  });
  final GameController controller;
  final CharacterVisualTheme theme;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<ActionResult> onAdvance;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final progress = state.characters['ryomi']!;
    final needed = IdleBalance.affectionNeeded(progress.stage);
    final maxStage = progress.stage >= 9;
    final requirements = _requirements(state, progress, needed);
    final completed = requirements.where((item) => item.complete).length;
    final canAdvance = IdleRules.canAdvance(state, 'ryomi');
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.paper.withValues(alpha: .94),
            GameColors.blush.withValues(alpha: .92),
            GameColors.roseBeige.withValues(alpha: .94),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(26),
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(11),
        ),
        border: Border.all(color: theme.sceneAccent.withValues(alpha: .75)),
        boxShadow: [
          BoxShadow(
            color: theme.relationshipAccent.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
          const BoxShadow(
            color: GameColors.brownShadow,
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VÃNCULO',
            style: TextStyle(
              color: theme.sceneAccentAlt,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${progress.affection} / $needed',
            style: const TextStyle(
              color: GameColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 5),
          _TuningBar(
            value: progress.affection,
            maximum: needed,
            accent: theme.relationshipAccent,
            alt: theme.relationshipAlt,
          ),
          const SizedBox(height: 8),
          Text(
            'ESTÃGIO ${progress.stage + 1} â€” ${IdleRules.stageName(progress.stage).toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.relationshipAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            maxStage ? 'ROTA CONCLUÃDA' : 'PRÃ“XIMO VÃNCULO',
            style: const TextStyle(
              color: GameColors.softInk,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: .8,
            ),
          ),
          Text(
            maxStage
                ? 'Todas as fases alcançadas'
                : IdleRules.stageName(progress.stage + 1).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GameColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          InkWell(
            key: const ValueKey('requirements_toggle'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .68),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.relationshipAccent.withValues(alpha: .22),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.favorite_border_rounded,
                    color: theme.relationshipAlt,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'PASSOS PARA EVOLUIR  $completed de ${requirements.length}',
                      style: const TextStyle(
                        color: GameColors.ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: open
                ? Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Column(
                      children: requirements
                          .map(
                            (item) => _RequirementLine(
                              item,
                              accent: theme.relationshipAccent,
                            ),
                          )
                          .toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (canAdvance) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('advance_relationship'),
                onPressed: () async {
                  final result = await controller.advanceStage('ryomi');
                  if (result.storyEpisodeId != null)
                    GameAudioHooks.emit(GameAudioCue.stageAdvance);
                  onAdvance(result);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.relationshipAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameRadii.pill),
                  ),
                ),
                icon: const Icon(Icons.favorite_rounded, size: 16),
                label: const Text(
                  'AVANÇAR RELAÇÃO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_Requirement> _requirements(
    IdleState state,
    CharacterProgress progress,
    int needed,
  ) {
    final hobbyTarget = 1 + progress.stage ~/ 2;
    final moneyTarget = progress.stage * 80;
    final giftTarget = progress.stage ~/ 2;
    final encounterTarget = progress.stage ~/ 3;
    return [
      _Requirement(
        Icons.favorite_rounded,
        'Afeição ${progress.affection} / $needed',
        progress.affection >= needed,
      ),
      _Requirement(
        Icons.music_note_rounded,
        'Música nível ${state.hobbies[IdleRules.favoriteHobby('ryomi')]!.level} / $hobbyTarget',
        state.hobbies[IdleRules.favoriteHobby('ryomi')]!.level >= hobbyTarget,
      ),
      if (moneyTarget > 0)
        _Requirement(
          Icons.account_balance_wallet_rounded,
          'Renda ${NumberFormatter.money(state.totalMoneyEarned)} / ${NumberFormatter.money(moneyTarget)}',
          state.totalMoneyEarned >= moneyTarget,
        ),
      if (giftTarget > 0)
        _Requirement(
          Icons.card_giftcard_rounded,
          'Presentes ${progress.gifts} / $giftTarget',
          progress.gifts >= giftTarget,
        ),
      if (encounterTarget > 0)
        _Requirement(
          Icons.nightlife_rounded,
          'Encontros ${progress.encounters} / $encounterTarget',
          progress.encounters >= encounterTarget,
        ),
    ];
  }
}

class _Requirement {
  const _Requirement(this.icon, this.label, this.complete);
  final IconData icon;
  final String label;
  final bool complete;
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine(this.item, {required this.accent});

  final _Requirement item;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(
          item.complete
              ? Icons.check_circle_rounded
              : Icons.favorite_border_rounded,
          size: 15,
          color: item.complete
              ? GameColors.success
              : accent.withValues(alpha: .78),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: item.complete ? GameColors.success : GameColors.ink,
              fontSize: 11,
              fontWeight: item.complete ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TuningBar extends StatelessWidget {
  const _TuningBar({
    required this.value,
    required this.maximum,
    required this.accent,
    required this.alt,
  });

  final int value;
  final int maximum;
  final Color accent;
  final Color alt;

  @override
  Widget build(BuildContext context) => Container(
    height: 10,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: accent.withValues(alpha: .18)),
    ),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: (value / maximum).clamp(0, 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, alt]),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .8), blurRadius: 8),
          ],
        ),
      ),
    ),
  );
}

class CharacterSpeechBubble extends StatelessWidget {
  const CharacterSpeechBubble({
    super.key,
    required this.text,
    required this.theme,
  });

  final String text;
  final CharacterVisualTheme theme;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250),
    child: Stack(
      key: ValueKey(text),
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 28,
          bottom: -6,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 13, height: 13, color: GameColors.blush),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
          decoration: BoxDecoration(
            gradient: theme.speechGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
              color: theme.speechBorder.withValues(alpha: .78),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RYOMI',
                style: TextStyle(
                  color: theme.speechBorder,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameColors.ink,
                  fontSize: 13,
                  height: 1.22,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SceneActionControls extends StatefulWidget {
  const _SceneActionControls({
    required this.controller,
    required this.onResult,
  });
  final GameController controller;
  final void Function(ActionResult, _RyomiEvent) onResult;
  @override
  State<_SceneActionControls> createState() => _SceneActionControlsState();
}

class _SceneActionControlsState extends State<_SceneActionControls> {
  Future<void> _talk() async =>
      widget.onResult(await widget.controller.talk('ryomi'), _RyomiEvent.talk);
  Future<void> _interact() async => widget.onResult(
    await widget.controller.interact('ryomi'),
    _RyomiEvent.interact,
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
    return CharacterInteractionGrid(
      actions: [
        CharacterActionSpec(
          id: 'talk',
          label: 'Conversar',
          detail: '+${IdleBalance.talkAffectionReward} afeição',
          icon: Icons.chat_bubble_rounded,
          color: GameColors.coral,
          cooldownRemaining: Duration(seconds: talkLeft),
          cooldownTotal: IdleBalance.talkCooldown,
          badge: talkLeft == 0 ? 'pronto' : null,
          onPressed: _talk,
        ),
        CharacterActionSpec(
          id: 'interact',
          label: 'Interagir',
          detail: '+${IdleBalance.interactAffectionReward} afeição',
          icon: Icons.back_hand_rounded,
          color: GameColors.cyan,
          cooldownRemaining: Duration(seconds: interactLeft),
          cooldownTotal: IdleBalance.interactCooldown,
          badge: interactLeft == 0 ? 'pronto' : null,
          onPressed: _interact,
        ),
        CharacterActionSpec(
          id: 'gift',
          label: 'Presentear',
          detail: '$count itens',
          icon: Icons.card_giftcard_rounded,
          color: GameColors.violet,
          badge: '$count',
          onPressed: () => showGiftSelectionDialog(
            context,
            widget.controller,
            characterId: PlayableCharacterIds.roxanne,
            onDelivered: (result) => widget.onResult(result, _RyomiEvent.gift),
          ),
        ),
        CharacterActionSpec(
          id: 'date',
          label: 'Encontro',
          detail: '$dates locais',
          icon: Icons.confirmation_number_rounded,
          color: GameColors.gold,
          badge: dates.toString(),
          onPressed: () => showDateSelectionDialog(
            context,
            widget.controller,
            characterId: PlayableCharacterIds.roxanne,
            onStarted: (result) =>
                widget.onResult(result, _RyomiEvent.encounter),
          ),
        ),
      ],
    );
  }

  int _remaining(int lastAt, Duration cooldown, int now) {
    final value = lastAt + cooldown.inMilliseconds - now;
    return value <= 0 ? 0 : (value / 1000).ceil();
  }
}

class _RyomiCharacterVisual extends StatelessWidget {
  const _RyomiCharacterVisual({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.bottomCenter,
    children: [
      Transform.scale(
        scale: 1 + phase * .012,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x55FFB75D), Color(0x224C61CA), Color(0x00000000)],
              radius: .62,
            ),
          ),
        ),
      ),
      Image.asset(
        GameAssets.ryomiStage01,
        key: const ValueKey('ryomi_official_art'),
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
      Positioned(
        bottom: 1,
        child: Container(
          width: 160,
          height: 13,
          decoration: BoxDecoration(
            color: const Color(0x99000000),
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [
              BoxShadow(color: Colors.black, blurRadius: 16, spreadRadius: 7),
            ],
          ),
        ),
      ),
    ],
  );
}

class _RadioStudioPainter extends CustomPainter {
  const _RadioStudioPainter({required this.phase, required this.theme});

  final double phase;
  final CharacterVisualTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final window = Rect.fromLTWH(
      size.width * .08,
      size.height * .08,
      size.width * .84,
      size.height * .53,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(22)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xD82A6870), Color(0xD81F4653), Color(0xD832425A)],
        ).createShader(window),
    );
    final frame = Paint()
      ..color = const Color(0x995ED6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(22)),
      frame,
    );
    for (var x = window.left + 18; x < window.right; x += 30) {
      final h = 24 + ((x ~/ 30) % 6) * 17.0;
      final building = Rect.fromLTWH(x, window.bottom - h, 21, h);
      canvas.drawRect(building, Paint()..color = const Color(0x884B6A78));
      final light = Paint()
        ..color = Color.lerp(
          const Color(0x66FFBD62),
          const Color(0xCC65E7E0),
          ((x ~/ 30) % 2).toDouble(),
        )!;
      for (var y = building.top + 7; y < building.bottom - 2; y += 12) {
        canvas.drawRect(Rect.fromLTWH(x + 5, y, 3, 4), light);
      }
    }
    final neon = Paint()
      ..color = Color.lerp(
        theme.relationshipAccent.withValues(alpha: .75),
        theme.sceneAccent,
        phase,
      )!
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final mid = size.height * .49;
    for (var x = size.width * .12; x < size.width * .88; x += 13) {
      final h = 8 + ((x ~/ 13) % 7) * 5 + phase * 9;
      canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), neon);
    }
    final desk = Path()
      ..moveTo(size.width * .06, size.height * .78)
      ..lineTo(size.width * .94, size.height * .72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      desk,
      Paint()
        ..shader =
            const LinearGradient(
              colors: [Color(0xDDEAE2D5), Color(0xEEF3E8DF)],
            ).createShader(
              Rect.fromLTWH(0, size.height * .7, size.width, size.height * .3),
            ),
    );
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .76, size.height * .77),
        width: size.width * .18,
        height: 34,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(board, Paint()..color = const Color(0xCCFFF9F1));
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(
        Offset(board.left + 18 + i * 18, board.center.dy),
        4,
        Paint()
          ..color = i % 2 == 0
              ? const Color(0xFFFFB75D)
              : const Color(0xFF5ED6D4),
      );
    }
    final backLight = Rect.fromCenter(
      center: Offset(size.width * .56, size.height * .55),
      width: size.width * .36,
      height: size.height * .64,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backLight, const Radius.circular(90)),
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.glow.withValues(alpha: .55),
            theme.sceneAccentAlt.withValues(alpha: .12),
            Colors.transparent,
          ],
        ).createShader(backLight),
    );
    final strip = Paint()
      ..color = theme.sceneAccent.withValues(alpha: .34)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .14, size.height * .18),
      Offset(size.width * .86, size.height * .14),
      strip,
    );
  }

  @override
  bool shouldRepaint(covariant _RadioStudioPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.theme != theme;
}

class _StudioSignature extends StatelessWidget {
  const _StudioSignature();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Icon(Icons.circle, size: 8, color: GameColors.coral),
      SizedBox(width: 6),
      Text(
        'NO AR • 98.7 FM',
        style: TextStyle(
          color: GameColors.cream,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    ],
  );
}

class _FrequencyReadyGlow extends StatelessWidget {
  const _FrequencyReadyGlow();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: GameColors.paper.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GameColors.coral),
      boxShadow: [
        BoxShadow(
          color: GameColors.coral.withValues(alpha: .5),
          blurRadius: 16,
        ),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite_rounded, color: GameColors.coral, size: 16),
        SizedBox(width: 5),
        Text(
          'VÃNCULO PRONTO',
          style: TextStyle(
            color: GameColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}
