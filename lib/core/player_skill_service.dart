import '../data/idle_balance.dart';
import '../models/idle_models.dart';

enum PlayerSkillId {
  inteligencia,
  condicionamento,
  carisma,
  paciencia,
  estrategia,
  criatividadeMusical,
  talentoCulinario,
  percepcao,
  comunicacao,
  tecnologia;

  String get key => switch (this) {
    PlayerSkillId.inteligencia => 'inteligencia',
    PlayerSkillId.condicionamento => 'condicionamento',
    PlayerSkillId.carisma => 'carisma',
    PlayerSkillId.paciencia => 'paciencia',
    PlayerSkillId.estrategia => 'estrategia',
    PlayerSkillId.criatividadeMusical => 'criatividade_musical',
    PlayerSkillId.talentoCulinario => 'talento_culinario',
    PlayerSkillId.percepcao => 'percepcao',
    PlayerSkillId.comunicacao => 'comunicacao',
    PlayerSkillId.tecnologia => 'tecnologia',
  };
}

class PlayerSkillDefinition {
  const PlayerSkillDefinition({
    required this.id,
    required this.displayName,
    required this.sourceHobbyId,
    required this.description,
    required this.displayOrder,
    this.futureUsageMetadata = const {},
  });

  final PlayerSkillId id;
  final String displayName;
  final String sourceHobbyId;
  final String description;
  final int displayOrder;
  final Map<String, String> futureUsageMetadata;

  String get key => id.key;
}

class PlayerSkillSnapshot {
  const PlayerSkillSnapshot({
    required this.definition,
    required this.level,
    required this.isMastered,
    required this.sourceProgress,
  });

  final PlayerSkillDefinition definition;
  final int level;
  final bool isMastered;
  final ActivityProgress sourceProgress;
}

class PlayerSkillLevelChange {
  const PlayerSkillLevelChange({
    required this.skillId,
    required this.sourceHobbyId,
    required this.previousLevel,
    required this.newLevel,
    required this.mastered,
  });

  final PlayerSkillId skillId;
  final String sourceHobbyId;
  final int previousLevel;
  final int newLevel;
  final bool mastered;
}

abstract final class PlayerSkillService {
  static const definitions = [
    PlayerSkillDefinition(
      id: PlayerSkillId.inteligencia,
      displayName: 'Inteligência',
      sourceHobbyId: 'leitura',
      description:
          'Representa conhecimento, compreensão e capacidade de aprendizado.',
      displayOrder: 1,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.condicionamento,
      displayName: 'Condicionamento',
      sourceHobbyId: 'academia',
      description: 'Representa resistência física, energia e preparo corporal.',
      displayOrder: 2,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.carisma,
      displayName: 'Carisma',
      sourceHobbyId: 'teatro',
      description: 'Representa expressão, presença e desenvoltura social.',
      displayOrder: 3,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.paciencia,
      displayName: 'Paciência',
      sourceHobbyId: 'meditacao',
      description: 'Representa autocontrole, foco e tranquilidade.',
      displayOrder: 4,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.estrategia,
      displayName: 'Estratégia',
      sourceHobbyId: 'videogames',
      description: 'Representa planejamento, tomada de decisão e adaptação.',
      displayOrder: 5,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.criatividadeMusical,
      displayName: 'Criatividade Musical',
      sourceHobbyId: 'musica',
      description: 'Representa domínio e expressão através da música.',
      displayOrder: 6,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.talentoCulinario,
      displayName: 'Talento Culinário',
      sourceHobbyId: 'culinaria',
      description: 'Representa experiência e criatividade na cozinha.',
      displayOrder: 7,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.percepcao,
      displayName: 'Percepção',
      sourceHobbyId: 'fotografia',
      description:
          'Representa atenção aos detalhes e capacidade de observação.',
      displayOrder: 8,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.comunicacao,
      displayName: 'Comunicação',
      sourceHobbyId: 'oratoria',
      description:
          'Representa clareza, confiança e habilidade para transmitir ideias.',
      displayOrder: 9,
    ),
    PlayerSkillDefinition(
      id: PlayerSkillId.tecnologia,
      displayName: 'Tecnologia',
      sourceHobbyId: 'programacao',
      description:
          'Representa conhecimento técnico, lógica e domínio de sistemas.',
      displayOrder: 10,
    ),
  ];

  static PlayerSkillDefinition byId(PlayerSkillId id) =>
      definitions.firstWhere((item) => item.id == id);

  static PlayerSkillDefinition byKey(String key) => definitions.firstWhere(
    (item) => item.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Skill inexistente.'),
  );

  static PlayerSkillDefinition skillForHobby(String hobbyId) =>
      definitions.firstWhere(
        (item) => item.sourceHobbyId == hobbyId,
        orElse: () =>
            throw ArgumentError.value(hobbyId, 'hobbyId', 'Hobby sem Skill.'),
      );

  static int getSkillLevel(IdleState state, PlayerSkillId id) {
    final definition = byId(id);
    final progress =
        state.hobbies[definition.sourceHobbyId] ?? const ActivityProgress();
    return progress.level.clamp(1, IdleBalance.maximumHobbyLevel);
  }

  static int getSkillLevelByKey(IdleState state, String key) =>
      getSkillLevel(state, byKey(key).id);

  static bool isSkillMastered(IdleState state, PlayerSkillId id) =>
      getSkillLevel(state, id) >= IdleBalance.maximumHobbyLevel;

  static bool isSkillMasteredByKey(IdleState state, String key) =>
      isSkillMastered(state, byKey(key).id);

  static PlayerSkillSnapshot snapshot(IdleState state, PlayerSkillId id) {
    final definition = byId(id);
    final progress =
        state.hobbies[definition.sourceHobbyId] ?? const ActivityProgress();
    final level = progress.level.clamp(1, IdleBalance.maximumHobbyLevel);
    return PlayerSkillSnapshot(
      definition: definition,
      level: level,
      isMastered: level >= IdleBalance.maximumHobbyLevel,
      sourceProgress: progress,
    );
  }

  static List<PlayerSkillSnapshot> snapshots(IdleState state) =>
      definitions.map((item) => snapshot(state, item.id)).toList();

  static List<PlayerSkillLevelChange> deriveLevelChanges({
    required Map<String, ActivityProgress> before,
    required Map<String, ActivityProgress> after,
  }) {
    final changes = <PlayerSkillLevelChange>[];
    for (final definition in definitions) {
      final previous =
          before[definition.sourceHobbyId]?.level.clamp(
            1,
            IdleBalance.maximumHobbyLevel,
          ) ??
          1;
      final current =
          after[definition.sourceHobbyId]?.level.clamp(
            1,
            IdleBalance.maximumHobbyLevel,
          ) ??
          1;
      if (previous == current) continue;
      changes.add(
        PlayerSkillLevelChange(
          skillId: definition.id,
          sourceHobbyId: definition.sourceHobbyId,
          previousLevel: previous,
          newLevel: current,
          mastered: current >= IdleBalance.maximumHobbyLevel,
        ),
      );
    }
    return changes;
  }

  static List<String> validateCatalog() {
    final errors = <String>[];
    if (definitions.length != 10) {
      errors.add('Quantidade de Skills inválida: ${definitions.length}');
    }
    final ids = <PlayerSkillId>{};
    final keys = <String>{};
    final hobbies = <String>{};
    final orders = <int>{};
    for (final definition in definitions) {
      if (!ids.add(definition.id))
        errors.add('Skill duplicada: ${definition.id}');
      if (!keys.add(definition.key)) {
        errors.add('Skill key duplicada: ${definition.key}');
      }
      if (!hobbies.add(definition.sourceHobbyId)) {
        errors.add('Hobby fonte duplicado: ${definition.sourceHobbyId}');
      }
      if (!hobbyIds.contains(definition.sourceHobbyId)) {
        errors.add('Hobby fonte inexistente: ${definition.sourceHobbyId}');
      }
      if (!orders.add(definition.displayOrder)) {
        errors.add('Ordem duplicada: ${definition.displayOrder}');
      }
      if (definition.displayName.trim().isEmpty) {
        errors.add('Nome vazio em ${definition.key}');
      }
      if (definition.description.trim().isEmpty) {
        errors.add('Descrição vazia em ${definition.key}');
      }
    }
    return errors;
  }
}
