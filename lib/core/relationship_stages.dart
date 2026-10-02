class RelationshipStageConfig {
  const RelationshipStageConfig({
    required this.index,
    required this.title,
    required this.affectionRequired,
    this.extraRequirementIds = const [],
    this.unlocks = const [],
    this.evolutionLine = '',
    this.futureRewardId,
    this.specialImageId,
    this.encounterOrSceneId,
  });

  final int index;
  final String title;
  final int affectionRequired;
  final List<String> extraRequirementIds;
  final List<String> unlocks;
  final String evolutionLine;
  final String? futureRewardId;
  final String? specialImageId;
  final String? encounterOrSceneId;
}

abstract final class RelationshipStageCatalog {
  static const stages = [
    RelationshipStageConfig(
      index: 0,
      title: 'Desconhecida',
      affectionRequired: 100,
      extraRequirementIds: ['hobby:musica'],
      evolutionLine: 'Uma primeira conexão começa a ganhar sinal.',
    ),
    RelationshipStageConfig(
      index: 1,
      title: 'Mal-entendido',
      affectionRequired: 150,
      extraRequirementIds: ['hobby:musica'],
      unlocks: ['Encontros iniciais'],
      evolutionLine: 'O ruído entre vocês vira curiosidade.',
      encounterOrSceneId: 'cafeteria',
    ),
    RelationshipStageConfig(
      index: 2,
      title: 'Conhecida',
      affectionRequired: 200,
      extraRequirementIds: ['hobby:musica', 'money'],
      unlocks: ['Nova conversa especial'],
      evolutionLine: 'Roxanne começa a reconhecer seu ritmo.',
      encounterOrSceneId: 'parque',
    ),
    RelationshipStageConfig(
      index: 3,
      title: 'Colega',
      affectionRequired: 250,
      extraRequirementIds: ['hobby:musica', 'money', 'gift', 'encounter'],
      unlocks: ['Episódio placeholder'],
      evolutionLine: 'A sintonia deixa de ser coincidência.',
      encounterOrSceneId: 'cinema',
    ),
    RelationshipStageConfig(
      index: 4,
      title: 'Amiga',
      affectionRequired: 300,
      extraRequirementIds: ['hobby:musica', 'money', 'gift', 'encounter'],
      evolutionLine: 'A madrugada parece menos silenciosa.',
      encounterOrSceneId: 'restaurante',
    ),
    RelationshipStageConfig(
      index: 5,
      title: 'Próxima',
      affectionRequired: 350,
      extraRequirementIds: ['hobby:musica', 'money', 'gift', 'encounter'],
      unlocks: ['Lembrança de rota'],
      evolutionLine: 'A confiança ganha uma frequência própria.',
    ),
    RelationshipStageConfig(
      index: 6,
      title: 'Interessada',
      affectionRequired: 400,
      extraRequirementIds: ['hobby:musica', 'money', 'gift', 'encounter'],
      evolutionLine: 'As entrelinhas começam a falar mais alto.',
      encounterOrSceneId: 'viagem',
    ),
    RelationshipStageConfig(
      index: 7,
      title: 'Apaixonada',
      affectionRequired: 450,
      extraRequirementIds: ['hobby:musica', 'money', 'gift', 'encounter'],
      unlocks: ['Cena especial futura'],
      evolutionLine: 'Roxanne já não tenta esconder o brilho no olhar.',
    ),
    RelationshipStageConfig(
      index: 8,
      title: 'Namorando',
      affectionRequired: 500,
      extraRequirementIds: ['hobby:musica', 'money', 'gift', 'encounter'],
      unlocks: ['Final em preparação'],
      evolutionLine: 'A relação vira escolha, presença e rotina.',
    ),
    RelationshipStageConfig(
      index: 9,
      title: 'Amor verdadeiro',
      affectionRequired: 550,
      unlocks: ['Rota concluída'],
      evolutionLine: 'A conexão alcança sua forma mais clara.',
      futureRewardId: 'roxanne_true_love',
      specialImageId: 'roxanne_final_future',
    ),
  ];

  static int get totalStages => stages.length;

  static RelationshipStageConfig byIndex(int index) =>
      stages[index.clamp(0, stages.length - 1)];

  static String titleFor(int index) => byIndex(index).title;

  static RelationshipStageConfig? nextAfter(int index) {
    final nextIndex = index + 1;
    if (nextIndex >= stages.length) return null;
    return stages[nextIndex];
  }
}
