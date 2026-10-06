import '../data/idle_balance.dart';
import '../data/character_routes.dart';
import '../models/idle_models.dart';
import 'character_catalog.dart';
import 'job_requirement_evaluator.dart';
import 'relationship_stages.dart';

abstract final class IdleRules {
  static int get totalRelationshipStages =>
      RelationshipStageCatalog.totalStages;

  static bool requirementsMet(IdleState state, Map<String, int> requirements) =>
      requirements.entries.every((entry) {
        final parts = entry.key.split(':');
        final targetId = parts.last;
        return switch (parts.first) {
          'job' => (state.jobs[targetId]?.level ?? 0) >= entry.value,
          'hobby' => (state.hobbies[targetId]?.level ?? 0) >= entry.value,
          'money' => state.money >= entry.value,
          'stage' =>
            (state
                        .characters[PlayableCharacterCatalog.canonicalId(
                          targetId,
                        )]
                        ?.stage ??
                    0) >=
                entry.value,
          _ => false,
        };
      });

  static bool jobUnlocked(IdleState state, String id) =>
      JobRequirementEvaluator.isUnlocked(state, IdleBalance.job(id));

  static bool hobbyUnlocked(IdleState state, String id) =>
      (state.hobbies[id]?.isUnlocked ?? false) ||
      IdleBalance.hobby(id).initialAvailability ||
      requirementsMet(state, IdleBalance.hobby(id).requires);

  static bool characterUnlocked(IdleState state, String id) =>
      state.characters[PlayableCharacterCatalog.canonicalId(id)]?.unlocked ??
      false;

  static String stageName(int stage) =>
      RelationshipStageCatalog.titleFor(stage);

  static int affectionNeededFor(String characterId, int stage) =>
      CharacterRouteCatalog.byCharacterId(
        PlayableCharacterCatalog.canonicalId(characterId),
      ).stageFor(stage).affectionRequired;

  static double stageProgressFraction(
    CharacterProgress character, {
    String characterId = PlayableCharacterIds.roxanne,
  }) {
    final needed = affectionNeededFor(characterId, character.stage);
    if (character.stage >= totalRelationshipStages - 1 &&
        character.affection >= needed) {
      return 1;
    }
    if (needed <= 0) return 0;
    return (character.affection / needed).clamp(0.0, 1.0);
  }

  static double routeProgressFraction(
    CharacterProgress character, {
    String characterId = PlayableCharacterIds.roxanne,
  }) {
    final needed = affectionNeededFor(characterId, character.stage);
    if (character.stage >= totalRelationshipStages - 1 &&
        character.affection >= needed) {
      return 1;
    }
    final completedStages = character.stage.clamp(
      0,
      totalRelationshipStages - 1,
    );
    final currentStageShare = stageProgressFraction(
      character,
      characterId: characterId,
    );
    return ((completedStages + currentStageShare) / totalRelationshipStages)
        .clamp(0.0, 1.0);
  }

  static int routeProgressPercent(
    CharacterProgress character, {
    String characterId = PlayableCharacterIds.roxanne,
  }) => (routeProgressFraction(character, characterId: characterId) * 100)
      .floor()
      .clamp(0, 100);

  static String promotion(String job, int level) =>
      IdleBalance.jobRoleTitle(job, level);

  static String? nextPromotion(String job, int level) =>
      IdleBalance.nextJobRoleTitle(job, level);

  static String favoriteHobby(String character) =>
      switch (PlayableCharacterCatalog.canonicalId(character)) {
        PlayableCharacterIds.roxanne => 'musica',
        PlayableCharacterIds.kai => 'videogames',
        _ => 'musica',
      };

  static String currentLine(String character, int stage) =>
      switch (PlayableCharacterCatalog.canonicalId(character)) {
        PlayableCharacterIds.roxanne =>
          stage < 3
              ? '“Você sempre aparece na hora do refrão, né?”'
              : '“Fica mais um pouco. A madrugada melhora com companhia.”',
        PlayableCharacterIds.kai =>
          '“Minha rota ainda está em preparação, mas eu já estou por aqui.”',
        _ => '“O estúdio está silencioso demais sem você por perto.”',
      };

  static bool canAdvance(IdleState state, String id) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(id);
    final route = CharacterRouteCatalog.byCharacterId(canonicalId);
    if (!PlayableCharacterCatalog.routeReady(canonicalId) ||
        !route.routeContentReady) {
      return false;
    }
    final character = state.characters[canonicalId];
    if (character == null) return false;
    final stage = route.stageFor(character.stage);
    if (character.stage >= totalRelationshipStages - 1 ||
        character.affection < stage.affectionRequired) {
      return false;
    }
    return stage.requirements.every(
          (requirement) => requirementMet(state, canonicalId, requirement),
        ) &&
        CharacterDateRequirements.forStage(canonicalId, character.stage).every(
          (requirement) =>
              (state.dateProgressByCharacter[canonicalId]?[requirement
                      .locationId] ??
                  0) >=
              requirement.requiredCount,
        );
  }

  static int requirementCurrentValue(
    IdleState state,
    String characterId,
    CharacterRouteRequirement requirement,
  ) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    final character = state.characters[canonicalId];
    return switch (requirement.type) {
      CharacterRouteRequirementType.hobbyLevel =>
        state.hobbies[requirement.targetId]?.level ?? 0,
      CharacterRouteRequirementType.jobLevel =>
        state.jobs[requirement.targetId]?.level ?? 0,
      CharacterRouteRequirementType.giftDelivered =>
        character?.giftDeliveries[requirement.targetId] ?? 0,
      CharacterRouteRequirementType.eventCompleted =>
        character?.scenes.contains(requirement.targetId) == true ? 1 : 0,
      CharacterRouteRequirementType.money => state.money,
    };
  }

  static bool requirementMet(
    IdleState state,
    String characterId,
    CharacterRouteRequirement requirement,
  ) {
    final target = requirement.requiredValue;
    if (target == null || target <= 0) return false;
    return requirementCurrentValue(state, characterId, requirement) >= target;
  }
}
