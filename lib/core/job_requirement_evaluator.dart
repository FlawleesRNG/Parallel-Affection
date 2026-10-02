import '../data/idle_balance.dart';
import '../models/idle_models.dart';
import 'character_catalog.dart';
import 'number_formatter.dart';
import 'player_skill_service.dart';
import 'relationship_stages.dart';

class JobRequirementEvaluation {
  const JobRequirementEvaluation({
    required this.type,
    required this.targetId,
    required this.currentValue,
    required this.requiredValue,
    required this.isMet,
    required this.displayLabel,
    required this.progressLabel,
    this.consumesResource = false,
    this.unavailableSource = false,
    this.invalidReference = false,
    this.safeMessage,
  });

  final JobRequirementType type;
  final String targetId;
  final int currentValue;
  final int requiredValue;
  final bool isMet;
  final String displayLabel;
  final String progressLabel;
  final bool consumesResource;
  final bool unavailableSource;
  final bool invalidReference;
  final String? safeMessage;
}

class JobUnlockEvaluation {
  const JobUnlockEvaluation({
    required this.job,
    required this.requirements,
    required this.isPermanentlyUnlocked,
  });

  final JobDefinition job;
  final List<JobRequirementEvaluation> requirements;
  final bool isPermanentlyUnlocked;

  bool get requirementsMet => requirements.every((item) => item.isMet);
  bool get hasInvalidReference =>
      requirements.any((item) => item.invalidReference);
  bool get isUnlocked => isPermanentlyUnlocked || requirementsMet;
}

abstract final class JobRequirementEvaluator {
  static JobUnlockEvaluation evaluate(IdleState state, JobDefinition job) {
    final progress = state.jobs[job.id] ?? const ActivityProgress();
    final requirements = job.requirements
        .map((requirement) => evaluateRequirement(state, requirement))
        .toList(growable: false);
    return JobUnlockEvaluation(
      job: job,
      requirements: requirements,
      isPermanentlyUnlocked:
          progress.isUnlocked || job.id == 'neighborhood_deliveries',
    );
  }

  static bool isUnlocked(IdleState state, JobDefinition job) =>
      evaluate(state, job).isUnlocked;

  static JobRequirementEvaluation evaluateRequirement(
    IdleState state,
    JobRequirement requirement,
  ) {
    final targetId = _canonicalTargetId(requirement);
    return switch (requirement.type) {
      JobRequirementType.jobLevel => _jobLevel(state, requirement, targetId),
      JobRequirementType.hobbyLevel => _hobbyLevel(
        state,
        requirement,
        targetId,
      ),
      JobRequirementType.skillLevel => _skillLevel(
        state,
        requirement,
        targetId,
      ),
      JobRequirementType.relationshipStage => _relationshipStage(
        state,
        requirement,
        targetId,
      ),
      JobRequirementType.money => _money(state, requirement, targetId),
      JobRequirementType.eventCompleted => _futureRequirement(
        requirement,
        targetId,
        'Evento futuro',
      ),
      JobRequirementType.locationDiscovered => _futureRequirement(
        requirement,
        targetId,
        'Local futuro',
      ),
    };
  }

  static String _canonicalTargetId(JobRequirement requirement) {
    if (requirement.type == JobRequirementType.relationshipStage) {
      return PlayableCharacterCatalog.canonicalId(requirement.targetId);
    }
    if (requirement.type == JobRequirementType.hobbyLevel) {
      return _hobbyAliases[requirement.targetId] ?? requirement.targetId;
    }
    return requirement.targetId;
  }

  static JobRequirementEvaluation _jobLevel(
    IdleState state,
    JobRequirement requirement,
    String targetId,
  ) {
    final exists = IdleBalance.jobs.any((job) => job.id == targetId);
    final current = state.jobs[targetId]?.level ?? 0;
    final met = exists && current >= requirement.value;
    final name = exists ? IdleBalance.job(targetId).displayName : targetId;
    return JobRequirementEvaluation(
      type: requirement.type,
      targetId: targetId,
      currentValue: current,
      requiredValue: requirement.value,
      isMet: met,
      displayLabel: name,
      progressLabel: met
          ? 'Nível ${requirement.value}'
          : 'Nível $current / ${requirement.value}',
      consumesResource: requirement.consumes,
      invalidReference: !exists,
      safeMessage: exists ? null : 'Emprego inexistente no catálogo.',
    );
  }

  static JobRequirementEvaluation _hobbyLevel(
    IdleState state,
    JobRequirement requirement,
    String targetId,
  ) {
    final exists = IdleBalance.hobbies.any((hobby) => hobby.id == targetId);
    final current = state.hobbies[targetId]?.level ?? 0;
    final met = exists && current >= requirement.value;
    final name = exists ? IdleBalance.hobby(targetId).name : targetId;
    return JobRequirementEvaluation(
      type: requirement.type,
      targetId: targetId,
      currentValue: current,
      requiredValue: requirement.value,
      isMet: met,
      displayLabel: name,
      progressLabel: met
          ? 'Nível ${requirement.value}'
          : 'Nível $current / ${requirement.value}',
      consumesResource: requirement.consumes,
      unavailableSource: !exists,
      invalidReference: !exists,
      safeMessage: exists ? null : 'Hobby indisponível.',
    );
  }

  static JobRequirementEvaluation _skillLevel(
    IdleState state,
    JobRequirement requirement,
    String targetId,
  ) {
    try {
      final skill = PlayerSkillService.byKey(targetId);
      final current = PlayerSkillService.getSkillLevel(state, skill.id);
      final met = current >= requirement.value;
      return JobRequirementEvaluation(
        type: requirement.type,
        targetId: targetId,
        currentValue: current,
        requiredValue: requirement.value,
        isMet: met,
        displayLabel: skill.displayName,
        progressLabel: met
            ? 'Nível ${requirement.value}'
            : 'Nível $current / ${requirement.value}',
        consumesResource: requirement.consumes,
      );
    } catch (_) {
      return JobRequirementEvaluation(
        type: requirement.type,
        targetId: targetId,
        currentValue: 0,
        requiredValue: requirement.value,
        isMet: false,
        displayLabel: targetId,
        progressLabel: 'Indisponível nesta versão',
        consumesResource: requirement.consumes,
        unavailableSource: true,
        invalidReference: true,
        safeMessage: 'Habilidade indisponível.',
      );
    }
  }

  static JobRequirementEvaluation _relationshipStage(
    IdleState state,
    JobRequirement requirement,
    String targetId,
  ) {
    final exists = PlayableCharacterCatalog.all.any(
      (character) => character.id == targetId,
    );
    final current = state.characters[targetId]?.stage ?? 0;
    final met = exists && current >= requirement.value;
    final name = exists
        ? PlayableCharacterCatalog.byId(targetId).visibleName
        : targetId;
    final currentTitle = RelationshipStageCatalog.titleFor(current);
    final requiredTitle = RelationshipStageCatalog.titleFor(requirement.value);
    return JobRequirementEvaluation(
      type: requirement.type,
      targetId: targetId,
      currentValue: current,
      requiredValue: requirement.value,
      isMet: met,
      displayLabel: name,
      progressLabel: met ? requiredTitle : '$currentTitle / $requiredTitle',
      consumesResource: requirement.consumes,
      invalidReference: !exists,
      safeMessage: exists ? null : 'Personagem indisponível.',
    );
  }

  static JobRequirementEvaluation _money(
    IdleState state,
    JobRequirement requirement,
    String targetId,
  ) {
    final current = state.money;
    final met = current >= requirement.value;
    return JobRequirementEvaluation(
      type: requirement.type,
      targetId: targetId,
      currentValue: current,
      requiredValue: requirement.value,
      isMet: met,
      displayLabel: met ? 'Saldo mínimo' : 'Saldo',
      progressLabel: met
          ? NumberFormatter.money(requirement.value)
          : '${NumberFormatter.money(current)} / ${NumberFormatter.money(requirement.value)}',
      consumesResource: requirement.consumes,
    );
  }

  static JobRequirementEvaluation _futureRequirement(
    JobRequirement requirement,
    String targetId,
    String label,
  ) => JobRequirementEvaluation(
    type: requirement.type,
    targetId: targetId,
    currentValue: 0,
    requiredValue: requirement.value,
    isMet: false,
    displayLabel: label,
    progressLabel: 'Indisponível nesta versão',
    consumesResource: requirement.consumes,
    unavailableSource: true,
  );
}

const _hobbyAliases = {
  'condicionamento': 'academia',
  'criatividade': 'fotografia',
  'comunicacao': 'oratoria',
  'tecnologia': 'programacao',
  'carisma': 'teatro',
};
