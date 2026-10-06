import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/character_catalog.dart';
import '../../core/idle_rules.dart';
import '../../core/relationship_stages.dart';
import '../../data/idle_balance.dart';
import '../../data/character_routes.dart';
import '../../data/date_locations.dart';
import '../../models/idle_models.dart';
import '../controllers/ryomi_windows_controller_v3.dart';
import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_typography_v3.dart';
import 'game_badge_v3.dart';
import 'game_button_v3.dart';
import 'game_window_frame_v3.dart';

class RelationshipWindowV3 extends StatelessWidget {
  const RelationshipWindowV3({
    super.key,
    required this.state,
    required this.windowsController,
    required this.characterId,
    this.compact = false,
  });

  final IdleState state;
  final RyomiWindowsControllerV3 windowsController;
  final String characterId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    final character = PlayableCharacterCatalog.byId(canonicalId);
    final progress =
        state.characters[canonicalId] ??
        const CharacterProgress(unlocked: true);
    final routePercent = IdleRules.routeProgressPercent(
      progress,
      characterId: canonicalId,
    );
    final stage = RelationshipStageCatalog.byIndex(progress.stage);
    final needed = IdleRules.affectionNeededFor(canonicalId, progress.stage);
    final requirements = _relationshipRequirements(state, canonicalId);
    final completeRequirements = requirements
        .where((item) => item.complete)
        .length;
    final allRequirementsComplete = completeRequirements == requirements.length;
    final maxStage = progress.stage >= IdleRules.totalRelationshipStages - 1;

    if (!windowsController.relationshipOpen) {
      return Tooltip(
        message: 'Abrir vínculo',
        child: Semantics(
          button: true,
          label: 'Abrir vínculo',
          child: GameButtonV3(
            key: const ValueKey('relationship_window_minimized_v3'),
            onPressed: windowsController.restoreRelationship,
            color: ConnectionsColorsV3.relationship,
            compact: compact,
            child: Text(
              maxStage
                  ? '♥ ${stage.title.toUpperCase()} · 100%'
                  : allRequirementsComplete
                  ? '♥ EVOLUINDO VÍNCULO…'
                  : '♥ ${stage.title.toUpperCase()} · $routePercent%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    final contentGap = 3.0;

    return GameWindowFrameV3(
      key: const ValueKey('relationship_window_v3'),
      title: 'Vínculo',
      icon: Icons.favorite_rounded,
      color: ConnectionsColorsV3.relationship,
      compact: compact,
      badge: GameBadgeV3(
        key: const ValueKey('relationship_stage_badge_v3'),
        label:
            'Etapa ${progress.stage + 1} de ${IdleRules.totalRelationshipStages}',
        kind: GameBadgeKindV3.novelty,
        compact: true,
      ),
      headerActions: [
        SizedBox(width: compact ? 3 : 7),
        IconButton(
          key: const ValueKey('relationship_minimize_v3'),
          tooltip: 'Minimizar vínculo',
          onPressed: windowsController.minimizeRelationship,
          constraints: BoxConstraints.tightFor(
            width: compact ? 24 : 30,
            height: compact ? 24 : 30,
          ),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
      ],
      contentPadding: EdgeInsets.all(compact ? 5 : 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final objectiveListHeight = _objectivesListHeight(
            requirements.length,
            compact,
            constraints.maxHeight,
          );
          final fixedChildren = <Widget>[
            _StageIdentityV3(
              characterName: character.visibleName,
              characterId: canonicalId,
              progress: progress,
              stage: stage,
              routePercent: routePercent,
              compact: compact,
            ),
            SizedBox(height: contentGap),
            _AffectionProgressV3(
              current: progress.affection.clamp(0, needed),
              target: needed,
              compact: compact,
            ),
            SizedBox(height: contentGap),
            _RelationshipTrackV3(activeStage: progress.stage, compact: compact),
            SizedBox(height: contentGap),
            _NextStageStripV3(stage: progress.stage, compact: compact),
            SizedBox(height: contentGap),
            SizedBox(
              key: const ValueKey('relationship_objectives_button_v3'),
              height: compact ? 24 : 26,
              child: GameButtonV3(
                key: const ValueKey('relationship_objectives_toggle_v3'),
                onPressed: windowsController.toggleObjectives,
                compact: compact,
                color: ConnectionsColorsV3.relationship,
                child: Text(
                  'OBJETIVOS $completeRequirements/${requirements.length} ${windowsController.objectivesExpanded ? '⌃' : '⌄'}',
                ),
              ),
            ),
            SizedBox(height: contentGap),
            _EvolutionStatusStripV3(
              requirements: requirements,
              complete: allRequirementsComplete,
              maxStage: maxStage,
              compact: compact,
            ),
          ];

          if (!windowsController.objectivesExpanded) {
            return SingleChildScrollView(
              key: const ValueKey('relationship_collapsed_scroll_v3'),
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: fixedChildren,
              ),
            );
          }

          return SingleChildScrollView(
            key: const ValueKey('relationship_expanded_scroll_v3'),
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...fixedChildren,
                SizedBox(height: contentGap),
                SizedBox(
                  key: const ValueKey('relationship_objectives_height_v3'),
                  height: objectiveListHeight,
                  child: _ObjectivesListV3(
                    requirements: requirements,
                    compact: compact,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

double _objectivesListHeight(int count, bool compact, double availableHeight) {
  final rowHeight = compact ? 18.0 : 22.0;
  final gap = compact ? 5.0 : 7.0;
  final padding = compact ? 10.0 : 14.0;
  final natural = padding + count * rowHeight + math.max(0, count - 1) * gap;
  final maxHeight = math.max(compact ? 48.0 : 58.0, availableHeight * .34);
  return math.min(natural, maxHeight);
}

class _StageIdentityV3 extends StatelessWidget {
  const _StageIdentityV3({
    required this.progress,
    required this.characterName,
    required this.characterId,
    required this.stage,
    required this.routePercent,
    required this.compact,
  });

  final CharacterProgress progress;
  final String characterName;
  final String characterId;
  final RelationshipStageConfig stage;
  final int routePercent;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('relationship_stage_identity_v3'),
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 5 : 7,
      vertical: compact ? 3 : 2,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    characterName.toUpperCase(),
                    key: const ValueKey('relationship_character_name_v3'),
                    style: ConnectionsTypographyV3.badge(size: compact ? 9 : 10)
                        .copyWith(
                          color: ConnectionsColorsV3.inkSoft,
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    stage.title.toUpperCase(),
                    key: const ValueKey('relationship_stage_title_v3'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ConnectionsTypographyV3.windowTitle(
                      size: compact ? 14 : 17,
                    ).copyWith(color: ConnectionsColorsV3.relationshipDark),
                  ),
                ],
              ),
            ),
            Text(
              '$routePercent%',
              key: const ValueKey('relationship_route_percent_v3'),
              style: ConnectionsTypographyV3.button(
                size: compact ? 13 : 15,
              ).copyWith(color: ConnectionsColorsV3.relationship),
            ),
          ],
        ),
        SizedBox(height: compact ? 5 : 4),
        _ProgressBarV3(
          keyValue: 'relationship_route_bar_v3',
          fraction: IdleRules.routeProgressFraction(
            progress,
            characterId: characterId,
          ),
          color: ConnectionsColorsV3.relationship,
          height: compact ? 7 : 8,
        ),
      ],
    ),
  );
}

class _AffectionProgressV3 extends StatelessWidget {
  const _AffectionProgressV3({
    required this.current,
    required this.target,
    required this.compact,
  });

  final int current;
  final int target;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('relationship_affection_panel_v3'),
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 5 : 7,
      vertical: compact ? 3 : 2,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Afeição da etapa',
                style: ConnectionsTypographyV3.secondary(
                  size: compact ? 10.5 : 12,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '$current / $target',
              key: const ValueKey('relationship_affection_value_v3'),
              style: ConnectionsTypographyV3.resourceValue(
                size: compact ? 12 : 13,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 5 : 4),
        _ProgressBarV3(
          keyValue: 'relationship_affection_bar_v3',
          fraction: target <= 0 ? 0 : current / target,
          color: ConnectionsColorsV3.relationship,
          height: compact ? 14 : 14,
        ),
      ],
    ),
  );
}

class _RelationshipTrackV3 extends StatelessWidget {
  const _RelationshipTrackV3({
    required this.activeStage,
    required this.compact,
  });

  final int activeStage;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('relationship_checkpoints_v3'),
    height: compact ? 24 : 26,
    child: Row(
      children: [
        for (final stage in RelationshipStageCatalog.stages) ...[
          Tooltip(
            message: '${stage.index + 1}. ${stage.title}',
            child: Container(
              key: ValueKey('relationship_checkpoint_v3_${stage.index}'),
              width: stage.index == activeStage
                  ? (compact ? 20 : 22)
                  : stage.index < activeStage
                  ? (compact ? 15 : 16)
                  : (compact ? 13 : 15),
              height: stage.index == activeStage
                  ? (compact ? 20 : 22)
                  : stage.index < activeStage
                  ? (compact ? 15 : 16)
                  : (compact ? 13 : 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stage.index <= activeStage
                    ? ConnectionsColorsV3.relationship
                    : ConnectionsColorsV3.warmSurface,
                border: Border.all(
                  color: stage.index == activeStage
                      ? ConnectionsColorsV3.relationshipDark
                      : ConnectionsColorsV3.outlineSoft,
                  width: stage.index == activeStage ? 2.5 : 1.2,
                ),
                boxShadow: stage.index == activeStage
                    ? [
                        BoxShadow(
                          color: ConnectionsColorsV3.relationship.withValues(
                            alpha: .36,
                          ),
                          blurRadius: 9,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${stage.index + 1}',
                style: ConnectionsTypographyV3.badge(size: compact ? 7 : 8)
                    .copyWith(
                      color: stage.index <= activeStage
                          ? ConnectionsColorsV3.onColor
                          : ConnectionsColorsV3.inkSoft,
                    ),
              ),
            ),
          ),
          if (stage.index < RelationshipStageCatalog.totalStages - 1)
            Expanded(
              child: Container(
                height: compact ? 2 : 3,
                color: stage.index < activeStage
                    ? ConnectionsColorsV3.relationship
                    : ConnectionsColorsV3.outlineSoft.withValues(alpha: .7),
              ),
            ),
        ],
      ],
    ),
  );
}

class _NextStageStripV3 extends StatelessWidget {
  const _NextStageStripV3({required this.stage, required this.compact});

  final int stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final next = RelationshipStageCatalog.nextAfter(stage);
    return DecoratedBox(
      key: const ValueKey('relationship_next_stage_v3'),
      decoration: BoxDecoration(
        color: ConnectionsColorsV3.paper,
        borderRadius: BorderRadius.circular(ConnectionsRadiusV3.medium),
        border: Border.all(
          color: ConnectionsColorsV3.outlineSoft.withValues(alpha: .6),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 4 : 3,
        ),
        child: Row(
          children: [
            Icon(
              next == null
                  ? Icons.verified_rounded
                  : Icons.auto_awesome_rounded,
              color: next == null
                  ? ConnectionsColorsV3.success
                  : ConnectionsColorsV3.relationship,
              size: compact ? 13 : 15,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                next == null
                    ? 'Vínculo máximo alcançado'
                    : 'Próxima: ${next.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ConnectionsTypographyV3.secondary(
                  size: compact ? 10.5 : 11.5,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionStatusStripV3 extends StatelessWidget {
  const _EvolutionStatusStripV3({
    required this.requirements,
    required this.complete,
    required this.maxStage,
    required this.compact,
  });

  final List<_RelationshipRequirementV3> requirements;
  final bool complete;
  final bool maxStage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = maxStage
        ? ConnectionsColorsV3.success
        : complete
        ? ConnectionsColorsV3.relationship
        : ConnectionsColorsV3.info;
    final label = _progressionStatusLabel(
      requirements: requirements,
      complete: complete,
      maxStage: maxStage,
    );
    return DecoratedBox(
      key: const ValueKey('relationship_auto_status_v3'),
      decoration: BoxDecoration(
        color: Color.lerp(ConnectionsColorsV3.paperElevated, color, .12),
        borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
        border: Border.all(color: color.withValues(alpha: .6)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 3 : 3,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: ConnectionsTypographyV3.secondary(
            size: compact ? 10 : 11,
          ).copyWith(color: ConnectionsColorsV3.darkFor(color)),
        ),
      ),
    );
  }
}

String _progressionStatusLabel({
  required List<_RelationshipRequirementV3> requirements,
  required bool complete,
  required bool maxStage,
}) {
  if (maxStage) return 'Vínculo máximo alcançado';
  if (complete) return 'Evoluindo vínculo…';

  final missing = requirements.where((item) => !item.complete).toList();
  if (missing.isEmpty) return 'Evoluindo vínculo…';

  final affection = missing.where((item) => item.label == 'Afeição');
  if (affection.isNotEmpty) {
    final item = affection.first;
    return 'Falta: Afeição ${item.current} / ${item.target}';
  }
  if (missing.length > 1) return 'Faltam ${missing.length} objetivos';
  final item = missing.single;
  return 'Falta: ${item.label} ${item.target}';
}

class _RelationshipRequirementV3 {
  const _RelationshipRequirementV3({
    required this.label,
    required this.current,
    required this.target,
  });

  final String label;
  final int current;
  final int target;

  bool get complete => current >= target;
}

List<_RelationshipRequirementV3> _relationshipRequirements(
  IdleState state,
  String characterId,
) {
  final progress =
      state.characters[characterId] ?? const CharacterProgress(unlocked: true);
  final stage = progress.stage;
  final route = CharacterRouteCatalog.byCharacterId(characterId);
  final stageDefinition = route.stageFor(stage);
  final needed = stageDefinition.affectionRequired;
  final requirements = <_RelationshipRequirementV3>[
    _RelationshipRequirementV3(
      label: 'Afeição',
      current: progress.affection.clamp(0, needed),
      target: needed,
    ),
  ];
  for (final requirement in stageDefinition.requirements) {
    final target = requirement.requiredValue;
    if (target == null || target <= 0) {
      requirements.add(
        _RelationshipRequirementV3(
          label: requirement.sourceLabel ?? 'Conteúdo em preparação',
          current: 0,
          target: 1,
        ),
      );
      continue;
    }
    final label = switch (requirement.type) {
      CharacterRouteRequirementType.hobbyLevel =>
        '${IdleBalance.hobby(requirement.targetId).name} nível',
      CharacterRouteRequirementType.jobLevel =>
        '${IdleBalance.job(requirement.targetId).name} nível',
      CharacterRouteRequirementType.giftDelivered =>
        '${IdleBalance.gift(requirement.targetId).displayName} entregues',
      CharacterRouteRequirementType.eventCompleted =>
        requirement.sourceLabel ?? 'Evento',
      CharacterRouteRequirementType.money => 'Dinheiro',
    };
    requirements.add(
      _RelationshipRequirementV3(
        label: label,
        current: IdleRules.requirementCurrentValue(
          state,
          characterId,
          requirement,
        ),
        target: target,
      ),
    );
  }

  for (final requirement in CharacterDateRequirements.forStage(
    characterId,
    stage,
  )) {
    final location = DateLocationCatalog.byId(requirement.locationId);
    requirements.add(
      _RelationshipRequirementV3(
        label: 'Encontro: ${location.name}',
        current:
            state.dateProgressByCharacter[characterId]?[requirement
                .locationId] ??
            0,
        target: requirement.requiredCount,
      ),
    );
  }

  return requirements.where((item) => item.target > 0).toList();
}

class _ObjectivesListV3 extends StatelessWidget {
  const _ObjectivesListV3({required this.requirements, required this.compact});

  final List<_RelationshipRequirementV3> requirements;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('relationship_objectives_panel_v3'),
    decoration: BoxDecoration(
      color: ConnectionsColorsV3.warmSurface,
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.medium),
    ),
    child: ListView.separated(
      key: const ValueKey('relationship_objectives_list_v3'),
      shrinkWrap: true,
      padding: EdgeInsets.all(compact ? 5 : 7),
      itemBuilder: (context, index) {
        final item = requirements[index];
        return Row(
          key: ValueKey('relationship_objective_item_v3_$index'),
          children: [
            Icon(
              item.complete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: compact ? 13 : 15,
              color: item.complete
                  ? ConnectionsColorsV3.success
                  : ConnectionsColorsV3.relationship,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${item.label} ${item.current} / ${item.target}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ConnectionsTypographyV3.secondary(
                  size: compact ? 10.5 : 11.5,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
      separatorBuilder: (context, index) => SizedBox(height: compact ? 5 : 7),
      itemCount: requirements.length,
    ),
  );
}

class _ProgressBarV3 extends StatelessWidget {
  const _ProgressBarV3({
    required this.keyValue,
    required this.fraction,
    required this.color,
    required this.height,
  });

  final String keyValue;
  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(keyValue),
    tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => ClipRRect(
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ConnectionsColorsV3.warmSurface,
            border: Border.all(
              color: ConnectionsColorsV3.outlineSoft.withValues(alpha: .7),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: .28),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
