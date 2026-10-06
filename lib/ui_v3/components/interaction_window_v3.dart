import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/character_catalog.dart';
import '../../data/idle_balance.dart';
import '../../features/characters/date_selection_dialog.dart';
import '../../features/characters/gift_selection_dialog.dart';
import '../../models/idle_models.dart';
import '../controllers/ryomi_windows_controller_v3.dart';
import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_typography_v3.dart';
import 'game_button_v3.dart';
import 'game_window_frame_v3.dart';

class InteractionWindowV3 extends StatefulWidget {
  const InteractionWindowV3({
    super.key,
    required this.controller,
    required this.windowsController,
    required this.selectedCharacterId,
    this.compact = false,
  });

  final GameController controller;
  final RyomiWindowsControllerV3 windowsController;
  final String selectedCharacterId;
  final bool compact;

  @override
  State<InteractionWindowV3> createState() => _InteractionWindowV3State();
}

class _InteractionWindowV3State extends State<InteractionWindowV3> {
  Timer? _cooldownTimer;

  GameController get controller => widget.controller;
  RyomiWindowsControllerV3 get windowsController => widget.windowsController;
  bool get compact => widget.compact;

  @override
  void initState() {
    super.initState();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _restoreInteractionWindow() {
    windowsController.restoreInteraction();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!windowsController.interactionOpen) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _restoreInteractionWindow,
        child: Tooltip(
          message: 'Abrir ações',
          child: Semantics(
            button: true,
            label: 'Abrir ações',
            child: GameButtonV3(
              key: const ValueKey('interaction_window_minimized_v3'),
              onPressed: _restoreInteractionWindow,
              color: ConnectionsColorsV3.interaction,
              compact: compact,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'AÇÕES ›',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    key: const ValueKey('interaction_badge_slot_v3'),
                    width: compact ? 4 : 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final padding = compact ? 8.0 : 10.0;
    final buttonGap = compact ? 7.0 : 8.0;

    return GameWindowFrameV3(
      key: const ValueKey('interaction_window_v3'),
      title: 'Ações',
      icon: Icons.touch_app_rounded,
      color: ConnectionsColorsV3.interaction,
      compact: compact,
      headerActions: [
        IconButton(
          key: const ValueKey('interaction_minimize_v3'),
          tooltip: 'Minimizar ações',
          onPressed: windowsController.minimizeInteraction,
          constraints: BoxConstraints.tightFor(
            width: compact ? 24 : 30,
            height: compact ? 24 : 30,
          ),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
      ],
      contentPadding: EdgeInsets.all(padding),
      child: _ActionsGridV3(
        controller: controller,
        windowsController: windowsController,
        selectedCharacterId: widget.selectedCharacterId,
        compact: compact,
        gap: buttonGap,
        onNeedsRefresh: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }
}

class _ActionsGridV3 extends StatelessWidget {
  const _ActionsGridV3({
    required this.controller,
    required this.windowsController,
    required this.selectedCharacterId,
    required this.compact,
    required this.gap,
    required this.onNeedsRefresh,
  });

  final GameController controller;
  final RyomiWindowsControllerV3 windowsController;
  final String selectedCharacterId;
  final bool compact;
  final double gap;
  final VoidCallback onNeedsRefresh;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final characterId = PlayableCharacterCatalog.canonicalId(
      selectedCharacterId,
    );
    final character = PlayableCharacterCatalog.byId(characterId);
    final progress =
        state.characters[characterId] ??
        const CharacterProgress(unlocked: true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final talkRemaining = _remaining(
      progress.lastTalkAt,
      IdleBalance.talkCooldown,
      now,
    );
    final interactRemaining = _remaining(
      progress.lastInteractAt,
      IdleBalance.interactCooldown,
      now,
    );
    const talkGain = IdleBalance.talkAffectionReward;
    const interactGain = IdleBalance.interactAffectionReward;
    final giftState = _giftActionState(state);
    final encounterState = _encounterActionState(state, characterId);

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _ActionButtonV3(
                keyValue: 'action_talk_v3',
                icon: Icons.chat_bubble_rounded,
                label: 'Conversar',
                reward: '+$talkGain afeição',
                status: talkRemaining > Duration.zero
                    ? _formatActionCountdown(talkRemaining)
                    : 'Disponível',
                cooldownRemaining: talkRemaining,
                cooldownTotal: IdleBalance.talkCooldown,
                compact: compact,
                tooltip:
                    'Conversa com ${character.visibleName} e avança o vínculo.',
                onPressed: talkRemaining > Duration.zero
                    ? null
                    : () async {
                        final beforeAction =
                            controller.state.characters[characterId]!;
                        final previousStage = beforeAction.stage;
                        await controller.talk(characterId);
                        final afterAction =
                            controller.state.characters[characterId]!;
                        final conversationSucceeded =
                            afterAction.lastTalkAt != beforeAction.lastTalkAt;
                        if (conversationSucceeded) {
                          windowsController.showTalkDialogue(
                            characterId: characterId,
                            relationshipStage: previousStage,
                          );
                        }
                        if (characterId == PlayableCharacterIds.roxanne &&
                            afterAction.stage > previousStage) {
                          windowsController.enqueueRelationshipAdvance(
                            afterAction.stage,
                          );
                        }
                        onNeedsRefresh();
                      },
              ),
              SizedBox(width: gap),
              _ActionButtonV3(
                keyValue: 'action_interact_v3',
                icon: Icons.waving_hand_rounded,
                label: 'Interagir',
                reward: '+$interactGain afeição',
                status: interactRemaining > Duration.zero
                    ? _formatActionCountdown(interactRemaining)
                    : 'Disponível',
                cooldownRemaining: interactRemaining,
                cooldownTotal: IdleBalance.interactCooldown,
                compact: compact,
                tooltip: 'Interação curta com cooldown separado.',
                onPressed: interactRemaining > Duration.zero
                    ? null
                    : () async {
                        final previousStage =
                            controller.state.characters[characterId]!.stage;
                        await controller.interact(characterId);
                        final currentStage =
                            controller.state.characters[characterId]!.stage;
                        if (characterId == PlayableCharacterIds.roxanne) {
                          windowsController.showInteractDialogue(currentStage);
                        }
                        if (characterId == PlayableCharacterIds.roxanne &&
                            currentStage > previousStage) {
                          windowsController.enqueueRelationshipAdvance(
                            currentStage,
                          );
                        }
                        onNeedsRefresh();
                      },
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: Row(
            children: [
              _ActionButtonV3(
                keyValue: 'action_gift_v3',
                icon: Icons.card_giftcard_rounded,
                label: 'Presentear',
                status: giftState.status,
                lockedReason: giftState.lockedReason,
                compact: compact,
                tooltip:
                    giftState.tooltip ?? 'Escolher um presente para entregar.',
                onPressed: () => showGiftSelectionDialog(
                  context,
                  controller,
                  characterId: characterId,
                  onDelivered: (result) {
                    windowsController.enqueueUnlockDialogue(
                      'gift_delivered',
                      result.message,
                    );
                    onNeedsRefresh();
                  },
                ),
              ),
              SizedBox(width: gap),
              _ActionButtonV3(
                keyValue: 'action_date_v3',
                icon: Icons.local_cafe_rounded,
                label: 'Encontro',
                status: encounterState.status,
                lockedReason: encounterState.lockedReason,
                compact: compact,
                tooltip:
                    encounterState.tooltip ?? 'Escolher encontro liberado.',
                onPressed: encounterState.lockedReason == null
                    ? () => showDateSelectionDialog(
                        context,
                        controller,
                        characterId: characterId,
                        onStarted: (result) {
                          windowsController.enqueueUnlockDialogue(
                            'date_started',
                            result.message,
                          );
                          onNeedsRefresh();
                        },
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Duration _remaining(int lastAt, Duration cooldown, int now) {
    final value = lastAt + cooldown.inMilliseconds - now;
    if (value <= 0) return Duration.zero;
    return Duration(milliseconds: value);
  }
}

class _ActionButtonV3 extends StatelessWidget {
  const _ActionButtonV3({
    required this.keyValue,
    required this.icon,
    required this.label,
    required this.status,
    required this.compact,
    required this.onPressed,
    this.reward,
    this.lockedReason,
    this.cooldownRemaining = Duration.zero,
    this.cooldownTotal = Duration.zero,
    this.tooltip,
  });

  final String keyValue;
  final IconData icon;
  final String label;
  final String? reward;
  final String status;
  final String? lockedReason;
  final Duration cooldownRemaining;
  final Duration cooldownTotal;
  final bool compact;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GameButtonV3(
      key: ValueKey(keyValue),
      onPressed: onPressed,
      compact: compact,
      color: ConnectionsColorsV3.interaction,
      locked: lockedReason != null,
      cooldown: cooldownRemaining > Duration.zero,
      tooltip: tooltip,
      semanticLabel: [label, ?reward, status].join('. '),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 7,
              vertical: compact ? 4 : 6,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: compact ? 94 : 116,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: compact ? 15 : 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            key: ValueKey('${keyValue}_label'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ConnectionsTypographyV3.button(
                              size: compact ? 11.5 : 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (reward != null &&
                        cooldownRemaining <= Duration.zero) ...[
                      SizedBox(height: compact ? 3 : 4),
                      Text(
                        reward!,
                        key: ValueKey('${keyValue}_reward'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ConnectionsTypographyV3.badge(
                          size: compact ? 9.5 : 10.5,
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 2 : 3),
                    Text(
                      lockedReason ?? status,
                      key: ValueKey('${keyValue}_status'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ConnectionsTypographyV3.secondary(
                        size: compact ? 9 : 10,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (cooldownRemaining > Duration.zero &&
                        cooldownTotal > Duration.zero) ...[
                      SizedBox(height: compact ? 3 : 4),
                      _CooldownBarV3(
                        keyValue: '${keyValue}_cooldown_v3',
                        legacyKeyValue: _legacyCooldownKey(keyValue),
                        remaining: cooldownRemaining,
                        total: cooldownTotal,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String? _legacyCooldownKey(String keyValue) => switch (keyValue) {
  'action_talk_v3' => 'action_talk_cooldown',
  'action_interact_v3' => 'action_interact_cooldown',
  _ => null,
};

class _CooldownBarV3 extends StatelessWidget {
  const _CooldownBarV3({
    required this.keyValue,
    required this.remaining,
    required this.total,
    this.legacyKeyValue,
  });

  final String keyValue;
  final String? legacyKeyValue;
  final Duration remaining;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final factor = total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final bar = ClipRRect(
      key: ValueKey(keyValue),
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
      child: SizedBox(
        height: 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .34),
            borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: factor,
              child: const ColoredBox(color: ConnectionsColorsV3.onColor),
            ),
          ),
        ),
      ),
    );
    if (legacyKeyValue == null) return bar;
    return KeyedSubtree(key: ValueKey(legacyKeyValue), child: bar);
  }
}

class _ActionAvailabilityV3 {
  const _ActionAvailabilityV3({
    required this.status,
    this.lockedReason,
    this.tooltip,
  });

  final String status;
  final String? lockedReason;
  final String? tooltip;
}

_ActionAvailabilityV3 _giftActionState(IdleState state) {
  return const _ActionAvailabilityV3(
    status: 'Catálogo',
    tooltip: 'Escolher um presente para entregar.',
  );
}

_ActionAvailabilityV3 _encounterActionState(
  IdleState state,
  String characterId,
) {
  if (state.activeEncounter != null) {
    return const _ActionAvailabilityV3(
      status: 'Em andamento',
      lockedReason: 'Em andamento',
    );
  }
  return const _ActionAvailabilityV3(
    status: 'Locais',
    tooltip: 'Escolha um local. Encontros usam dinheiro, não Tempo.',
  );
}

String _formatActionCountdown(Duration duration) {
  if (duration <= Duration.zero) return '00:00';
  final totalSeconds = (duration.inMilliseconds + 999) ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  if (hours > 0) return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  return '${two(minutes)}:${two(seconds)}';
}
