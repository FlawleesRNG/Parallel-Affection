import '../core/character_catalog.dart';

enum JobDifficulty { basic, intermediate, advanced, special }

enum JobRequirementType {
  jobLevel,
  relationshipStage,
  hobbyLevel,
  skillLevel,
  money,
  eventCompleted,
  locationDiscovered,
}

class JobRequirement {
  const JobRequirement(
    this.type,
    this.targetId,
    this.value, {
    this.consumes = false,
  });

  final JobRequirementType type;
  final String targetId;
  final int value;
  final bool consumes;

  String get legacyKey => switch (type) {
    JobRequirementType.jobLevel => 'job:$targetId',
    JobRequirementType.relationshipStage => 'stage:$targetId',
    JobRequirementType.hobbyLevel => 'hobby:$targetId',
    JobRequirementType.skillLevel => 'skill:$targetId',
    JobRequirementType.money => 'money:$targetId',
    JobRequirementType.eventCompleted => 'event:$targetId',
    JobRequirementType.locationDiscovered => 'location:$targetId',
  };
}

class JobDefinition {
  const JobDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    required this.difficulty,
    required this.displayOrder,
    required this.baseReward,
    required this.xpPerCycle,
    required this.maximumLevel,
    required this.cycleDurationsByLevel,
    required this.timeCostsByLevel,
    required this.rankNames,
    required this.requirements,
    required this.futureLocationId,
    this.placeLabel = 'Cidade',
    this.futureTimeWindows = const [],
    this.continuousProductionAtMaximumLevel = true,
    this.maximumLevelIncomeInterval =
        IdleBalance.maximumLevelContinuousIncomeInterval,
    this.unlockHint = 'Disponível',
  });
  final String id, displayName, description, unlockHint;
  final String futureLocationId, placeLabel;
  final JobDifficulty difficulty;
  final int displayOrder, baseReward, xpPerCycle, maximumLevel;
  final List<Duration> cycleDurationsByLevel;
  final List<int> timeCostsByLevel;
  final List<String> rankNames;
  final List<JobRequirement> requirements;
  final List<String> futureTimeWindows;
  final bool continuousProductionAtMaximumLevel;
  final Duration maximumLevelIncomeInterval;

  String get name => displayName;
  String get locationId => futureLocationId;
  int get blocks => timeCostAtLevel(1);
  int get seconds => cycleDurationAtLevel(1).inSeconds;
  int get money => rewardAtLevel(1);
  List<String> get roleTitles => rankNames;
  Map<String, int> get requires => {
    for (final requirement in requirements)
      requirement.legacyKey: requirement.value,
  };

  Duration cycleDurationAtLevel(int level) {
    final safeLevel = level.clamp(1, maximumLevel);
    if (safeLevel >= maximumLevel && continuousProductionAtMaximumLevel) {
      return maximumLevelIncomeInterval;
    }
    return cycleDurationsByLevel[safeLevel - 1];
  }

  int timeCostAtLevel(int level) =>
      timeCostsByLevel[level.clamp(1, maximumLevel) - 1];

  String rankAtLevel(int level) => rankNames[level.clamp(1, maximumLevel) - 1];

  int rewardAtLevel(int level) =>
      (baseReward * IdleBalance.levelRewardMultiplier(level)).round();

  bool get isInitiallyAvailable => requirements.isEmpty;
}

class HobbyUnlockRule {
  const HobbyUnlockRule.initial() : requires = const {};
  const HobbyUnlockRule.requires(this.requires);

  final Map<String, int> requires;
}

class HobbyDefinition {
  const HobbyDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    required this.skillName,
    required this.displayOrder,
    required this.maximumLevel,
    required this.initialAvailability,
    required this.trainingDurationsByLevel,
    required this.timeCostsByLevel,
    required this.xpPerTrainingCycle,
    required this.futureLocationId,
    this.futureMinigameId,
    this.unlockRule = const HobbyUnlockRule.initial(),
    this.unlockHint = 'Disponível',
  });

  final String id, displayName, description, skillName, unlockHint;
  final int displayOrder;
  final int maximumLevel;
  final bool initialAvailability;
  final List<Duration> trainingDurationsByLevel;
  final List<int> timeCostsByLevel;
  final int xpPerTrainingCycle;
  final String futureLocationId;
  final String? futureMinigameId;
  final HobbyUnlockRule unlockRule;

  String get name => displayName;
  String get attribute => skillName;
  int get blocks => timeCostAtLevel(1);
  int get seconds => trainingDurationAtLevel(1).inSeconds;
  Map<String, int> get requires => unlockRule.requires;

  Duration trainingDurationAtLevel(int level) =>
      trainingDurationsByLevel[level.clamp(1, maximumLevel) - 1];

  int timeCostAtLevel(int level) =>
      timeCostsByLevel[level.clamp(1, maximumLevel) - 1];
}

enum GiftCategory { start, middle, end }

class GiftDefinition {
  const GiftDefinition({
    required this.id,
    required this.displayName,
    required this.unitPrice,
    required this.affectionPerUnit,
    required this.category,
    required this.displayOrder,
    required this.description,
    this.assetPath,
  });

  final String id, displayName, description;
  final String? assetPath;
  final GiftCategory category;
  final int unitPrice, displayOrder, affectionPerUnit;

  String get name => displayName;
  int get price => unitPrice;
  int get affection => affectionPerUnit;
}

class EncounterDefinition {
  const EncounterDefinition(
    this.id,
    this.name,
    this.price,
    this.blocks,
    this.seconds,
    this.affection,
    this.stage,
  );
  final String id, name;
  final int price, blocks, seconds, affection, stage;
}

class RelationshipStageDefinition {
  const RelationshipStageDefinition(this.stage, {this.storyEpisodeId});
  final int stage;
  final String? storyEpisodeId;
}

abstract final class IdleBalance {
  static const offlineLimit = Duration(hours: 8);
  static const defaultJobOfflineLimit = offlineLimit;
  static const talkAffectionReward = 5;
  static const interactAffectionReward = 15;
  static const directCharacterClickAffection = 1;
  static const passiveAffectionUnlockStageNumber = 3;
  static const passiveAffectionUnlockStage =
      passiveAffectionUnlockStageNumber - 1;
  static const defaultPassiveAffectionReward = 1;
  static const defaultPassiveAffectionInterval = Duration(seconds: 1);
  static const passiveAffectionReward = defaultPassiveAffectionReward;
  static const passiveAffectionInterval = defaultPassiveAffectionInterval;
  static const talkCooldown = Duration(seconds: 5);
  static const interactCooldown = Duration(minutes: 1);
  static int xpNeeded(int level) => 20 + level * 15;
  static int affectionNeeded(int stage) => 100 + stage * 50;
  static const maximumJobLevel = 10;
  static const activityUpgradeCherryCost = 5;
  static const maximumLevelContinuousIncomeInterval = Duration(seconds: 1);
  static const jobBoostCherryCost = 5;
  static const jobBoostActiveDuration = Duration(minutes: 10);
  static const jobBoostSpeedMultiplier = 2.0;
  static const _baseJobXpByLevel = [12, 24, 40, 65, 95, 135, 185, 250, 330];
  static const maximumHobbyLevel = 10;
  static const hobbyBoostCherryCost = 5;
  static const hobbyBoostActiveDuration = Duration(minutes: 10);
  static const hobbyBoostSpeedMultiplier = 2.0;
  static const hobbyXpPerTrainingCycle = 2;
  static const _baseHobbyXpByLevel = [10, 20, 35, 55, 80, 115, 160, 220, 300];
  static const baseHobbyTrainingDurationsByLevel = [
    Duration(seconds: 10),
    Duration(seconds: 9),
    Duration(seconds: 8),
    Duration(seconds: 7),
    Duration(seconds: 6),
    Duration(seconds: 5),
    Duration(seconds: 4),
    Duration(seconds: 3),
    Duration(seconds: 2),
    Duration(seconds: 1),
  ];
  static const baseHobbyTimeCostsByLevel = [2, 2, 2, 2, 1, 1, 1, 1, 1, 0];

  static double difficultyXpMultiplier(JobDifficulty difficulty) =>
      switch (difficulty) {
        JobDifficulty.basic => 1,
        JobDifficulty.intermediate => 1.35,
        JobDifficulty.advanced => 1.80,
        JobDifficulty.special => 2.40,
      };

  static int defaultXpPerCycle(JobDifficulty difficulty) =>
      switch (difficulty) {
        JobDifficulty.basic => 2,
        JobDifficulty.intermediate => 3,
        JobDifficulty.advanced => 4,
        JobDifficulty.special => 5,
      };

  static double levelRewardMultiplier(int level) => 1 + ((level - 1) * .25);

  static int jobXpNeeded(JobDefinition job, int level) {
    if (level >= job.maximumLevel) return 0;
    return (_baseJobXpByLevel[level - 1] *
            difficultyXpMultiplier(job.difficulty))
        .ceil();
  }

  static int hobbyXpNeeded(HobbyDefinition hobby, int level) {
    if (level >= hobby.maximumLevel) return 0;
    return _baseHobbyXpByLevel[level - 1];
  }

  static const jobs = [
    JobDefinition(
      id: 'neighborhood_deliveries',
      displayName: 'Entregas de Bairro',
      displayOrder: 1,
      difficulty: JobDifficulty.basic,
      description:
          'Faça pequenas entregas pela cidade e comece a construir sua independência.',
      baseReward: 12,
      xpPerCycle: 2,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 12),
        Duration(seconds: 10),
        Duration(seconds: 8),
        Duration(seconds: 7),
        Duration(seconds: 6),
        Duration(seconds: 5),
        Duration(seconds: 4),
        Duration(seconds: 3),
        Duration(seconds: 1),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [2, 2, 2, 2, 1, 1, 1, 1, 1, 0],
      rankNames: [
        'Primeira Entrega',
        'Rota da Vizinhança',
        'Entregas Pontuais',
        'Rota Confiável',
        'Conhecedor das Ruas',
        'Entrega Expressa',
        'Mestre das Rotas',
        'Referência do Bairro',
        'Lenda das Entregas',
        'Cidade sem Atrasos',
      ],
      requirements: [],
      futureLocationId: 'neighborhood',
    ),
    JobDefinition(
      id: 'local_flyering',
      displayName: 'Panfletagem Local',
      displayOrder: 2,
      difficulty: JobDifficulty.basic,
      description:
          'Divulgue eventos e comércios locais enquanto conhece melhor as ruas da cidade.',
      baseReward: 15,
      xpPerCycle: 2,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 10),
        Duration(seconds: 9),
        Duration(seconds: 8),
        Duration(seconds: 7),
        Duration(seconds: 6),
        Duration(seconds: 5),
        Duration(seconds: 4),
        Duration(seconds: 2),
        Duration(seconds: 1),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
      rankNames: [
        'Primeiros Folhetos',
        'Esquina Movimentada',
        'Divulgação Local',
        'Rota de Campanha',
        'Voz do Bairro',
        'Cobertura do Centro',
        'Campanha de Sucesso',
        'Referência de Divulgação',
        'Cidade Mobilizada',
        'Mensagem por Toda Parte',
      ],
      requirements: [
        JobRequirement(
          JobRequirementType.jobLevel,
          'neighborhood_deliveries',
          2,
        ),
      ],
      futureLocationId: 'downtown',
      unlockHint: 'Entregas de Bairro nível 2',
    ),
    JobDefinition(
      id: 'cafe_assistant',
      displayName: 'Auxiliar de Cafeteria',
      displayOrder: 3,
      difficulty: JobDifficulty.intermediate,
      description:
          'Atenda clientes, organize pedidos e acompanhe o movimento da cafeteria.',
      baseReward: 50,
      xpPerCycle: 3,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 20),
        Duration(seconds: 18),
        Duration(seconds: 16),
        Duration(seconds: 14),
        Duration(seconds: 12),
        Duration(seconds: 10),
        Duration(seconds: 8),
        Duration(seconds: 6),
        Duration(seconds: 4),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [3, 3, 3, 3, 2, 2, 2, 2, 1, 0],
      rankNames: [
        'Primeiro Turno',
        'Mesas Organizadas',
        'Atendimento Ágil',
        'Especialista em Pedidos',
        'Barista em Treinamento',
        'Barista da Casa',
        'Destaque do Salão',
        'Supervisão de Turno',
        'Gestão da Cafeteria',
        'Ícone da Casa',
      ],
      requirements: [
        JobRequirement(JobRequirementType.jobLevel, 'local_flyering', 3),
        JobRequirement(JobRequirementType.money, 'money', 250),
      ],
      futureLocationId: 'cafe',
      unlockHint: 'Panfletagem Local nível 3 e R\$ 250',
    ),
    JobDefinition(
      id: 'game_store',
      displayName: 'Loja de Games',
      displayOrder: 4,
      difficulty: JobDifficulty.intermediate,
      description:
          'Trabalhe cercado por jogos, máquinas e clientes apaixonados por diversão.',
      baseReward: 90,
      xpPerCycle: 3,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 22),
        Duration(seconds: 20),
        Duration(seconds: 18),
        Duration(seconds: 16),
        Duration(seconds: 14),
        Duration(seconds: 12),
        Duration(seconds: 10),
        Duration(seconds: 7),
        Duration(seconds: 4),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [3, 3, 3, 3, 2, 2, 2, 2, 1, 0],
      rankNames: [
        'Primeiro Dia no Balcão',
        'Estoque Organizado',
        'Consultoria Gamer',
        'Especialista em Consoles',
        'Mestre dos Lançamentos',
        'Referência Gamer',
        'Supervisão da Loja',
        'Curadoria de Catálogo',
        'Gestão da Arena',
        'Lenda da Loja',
      ],
      requirements: [
        JobRequirement(JobRequirementType.hobbyLevel, 'videogames', 2),
        JobRequirement(
          JobRequirementType.relationshipStage,
          PlayableCharacterIds.roxanne,
          2,
        ),
        JobRequirement(JobRequirementType.jobLevel, 'cafe_assistant', 2),
      ],
      futureLocationId: 'game_store',
      unlockHint: 'Videogames nível 2, Roxanne Conhecida e Cafeteria nível 2',
    ),
    JobDefinition(
      id: 'gym_reception',
      displayName: 'Recepção da Academia',
      displayOrder: 5,
      difficulty: JobDifficulty.intermediate,
      description:
          'Organize horários, receba clientes e acompanhe a rotina da academia.',
      baseReward: 160,
      xpPerCycle: 3,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 25),
        Duration(seconds: 23),
        Duration(seconds: 21),
        Duration(seconds: 18),
        Duration(seconds: 16),
        Duration(seconds: 13),
        Duration(seconds: 10),
        Duration(seconds: 8),
        Duration(seconds: 5),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [3, 3, 3, 3, 3, 2, 2, 2, 1, 0],
      rankNames: [
        'Primeiro Plantão',
        'Cadastros em Dia',
        'Agenda Organizada',
        'Atendimento Fitness',
        'Recepção de Confiança',
        'Coordenação de Horários',
        'Referência da Academia',
        'Supervisão da Recepção',
        'Gestão do Espaço',
        'Coração da Academia',
      ],
      requirements: [
        JobRequirement(JobRequirementType.hobbyLevel, 'academia', 3),
        JobRequirement(JobRequirementType.jobLevel, 'cafe_assistant', 4),
      ],
      futureLocationId: 'gym',
      unlockHint: 'Academia nível 3 e Cafeteria nível 4',
    ),
    JobDefinition(
      id: 'freelance_photography',
      displayName: 'Fotografia Freelancer',
      displayOrder: 6,
      difficulty: JobDifficulty.intermediate,
      description:
          'Registre pessoas, lugares e eventos enquanto constrói seu próprio portfólio.',
      baseReward: 260,
      xpPerCycle: 3,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 28),
        Duration(seconds: 25),
        Duration(seconds: 22),
        Duration(seconds: 19),
        Duration(seconds: 16),
        Duration(seconds: 13),
        Duration(seconds: 10),
        Duration(seconds: 7),
        Duration(seconds: 5),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [3, 3, 3, 3, 2, 2, 2, 2, 1, 0],
      rankNames: [
        'Primeiro Clique',
        'Olhar Curioso',
        'Enquadramento Preciso',
        'Retratos Locais',
        'Portfólio em Crescimento',
        'Fotografia Profissional',
        'Olhar Autoral',
        'Nome em Exposição',
        'Referência da Cidade',
        'Lente Lendária',
      ],
      requirements: [
        JobRequirement(JobRequirementType.hobbyLevel, 'fotografia', 4),
        JobRequirement(
          JobRequirementType.relationshipStage,
          PlayableCharacterIds.roxanne,
          3,
        ),
      ],
      futureLocationId: 'city_events',
      unlockHint: 'Fotografia nível 4 e Roxanne Colega',
    ),
    JobDefinition(
      id: 'radio_assistant',
      displayName: 'Assistente de Rádio',
      displayOrder: 7,
      difficulty: JobDifficulty.advanced,
      description:
          'Ajude nos bastidores de uma rádio local e participe da programação da cidade.',
      baseReward: 600,
      xpPerCycle: 4,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 40),
        Duration(seconds: 36),
        Duration(seconds: 32),
        Duration(seconds: 28),
        Duration(seconds: 24),
        Duration(seconds: 20),
        Duration(seconds: 16),
        Duration(seconds: 12),
        Duration(seconds: 8),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [4, 4, 4, 4, 4, 3, 3, 3, 2, 0],
      rankNames: [
        'Primeiro Sinal',
        'Bastidores no Ar',
        'Operação de Estúdio',
        'Controle da Programação',
        'Voz dos Bastidores',
        'Produção no Ar',
        'Coordenação de Estúdio',
        'Destaque da Frequência',
        'Direção de Programação',
        'Lenda das Ondas',
      ],
      requirements: [
        JobRequirement(JobRequirementType.hobbyLevel, 'oratoria', 5),
        JobRequirement(JobRequirementType.hobbyLevel, 'musica', 4),
        JobRequirement(
          JobRequirementType.relationshipStage,
          PlayableCharacterIds.roxanne,
          4,
        ),
      ],
      futureLocationId: 'radio_studio',
      unlockHint: 'Oratória nível 5, Música nível 4 e Roxanne Amiga',
    ),
    JobDefinition(
      id: 'freelance_programmer',
      displayName: 'Programador Freelancer',
      displayOrder: 8,
      difficulty: JobDifficulty.advanced,
      description:
          'Desenvolva soluções para clientes e transforme conhecimento técnico em renda.',
      baseReward: 900,
      xpPerCycle: 4,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 45),
        Duration(seconds: 40),
        Duration(seconds: 36),
        Duration(seconds: 32),
        Duration(seconds: 28),
        Duration(seconds: 24),
        Duration(seconds: 18),
        Duration(seconds: 14),
        Duration(seconds: 9),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [4, 4, 4, 4, 4, 3, 3, 3, 2, 0],
      rankNames: [
        'Primeiro Código',
        'Caçador de Bugs',
        'Projeto Entregue',
        'Código Confiável',
        'Freelancer em Alta',
        'Arquitetura de Sistemas',
        'Especialista Full Stack',
        'Consultoria Técnica',
        'Referência Digital',
        'Mestre do Código',
      ],
      requirements: [
        JobRequirement(JobRequirementType.hobbyLevel, 'programacao', 6),
        JobRequirement(JobRequirementType.money, 'money', 10000),
      ],
      futureLocationId: 'home_office',
      unlockHint: 'Programação nível 6 e R\$ 10.000',
    ),
    JobDefinition(
      id: 'event_producer',
      displayName: 'Produtor de Eventos',
      displayOrder: 9,
      difficulty: JobDifficulty.special,
      description:
          'Planeje grandes eventos, coordene equipes e conecte diferentes partes da cidade.',
      baseReward: 1800,
      xpPerCycle: 5,
      maximumLevel: maximumJobLevel,
      cycleDurationsByLevel: [
        Duration(seconds: 60),
        Duration(seconds: 54),
        Duration(seconds: 48),
        Duration(seconds: 42),
        Duration(seconds: 36),
        Duration(seconds: 30),
        Duration(seconds: 24),
        Duration(seconds: 18),
        Duration(seconds: 12),
        Duration(seconds: 1),
      ],
      timeCostsByLevel: [5, 5, 5, 5, 4, 4, 3, 3, 2, 0],
      rankNames: [
        'Primeiro Evento',
        'Apoio de Produção',
        'Agenda Organizada',
        'Coordenação de Equipe',
        'Produção de Destaque',
        'Grandes Palcos',
        'Eventos da Cidade',
        'Direção de Produção',
        'Referência Nacional',
        'Lenda dos Eventos',
      ],
      requirements: [
        JobRequirement(JobRequirementType.hobbyLevel, 'teatro', 7),
        JobRequirement(JobRequirementType.hobbyLevel, 'oratoria', 6),
        JobRequirement(JobRequirementType.jobLevel, 'radio_assistant', 5),
        JobRequirement(JobRequirementType.money, 'money', 50000),
      ],
      futureLocationId: 'event_center',
      unlockHint:
          'Teatro nível 7, Oratória nível 6, Rádio nível 5 e R\$ 50.000',
    ),
  ];
  static const hobbies = [
    HobbyDefinition(
      id: 'leitura',
      displayName: 'Leitura',
      description:
          'Leia livros, explore novas ideias e desenvolva sua capacidade de compreender o mundo.',
      skillName: 'Inteligência',
      displayOrder: 1,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: true,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'library',
    ),
    HobbyDefinition(
      id: 'academia',
      displayName: 'Academia',
      description:
          'Treine seu corpo, aumente sua resistência e desenvolva uma rotina mais saudável.',
      skillName: 'Condicionamento',
      displayOrder: 2,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: true,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'gym',
    ),
    HobbyDefinition(
      id: 'teatro',
      displayName: 'Teatro',
      description:
          'Pratique interpretação, expressão e confiança diante de outras pessoas.',
      skillName: 'Carisma',
      displayOrder: 3,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: true,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'theater',
    ),
    HobbyDefinition(
      id: 'meditacao',
      displayName: 'Meditação',
      description:
          'Reserve um tempo para respirar, organizar os pensamentos e desenvolver autocontrole.',
      skillName: 'Paciência',
      displayOrder: 4,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: true,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'home',
    ),
    HobbyDefinition(
      id: 'videogames',
      displayName: 'Videogames',
      description:
          'Explore diferentes jogos, aprimore reflexos e desenvolva pensamento estratégico.',
      skillName: 'Estratégia',
      displayOrder: 5,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: true,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'arcade',
    ),
    HobbyDefinition(
      id: 'musica',
      displayName: 'Música',
      description:
          'Aprenda ritmos, pratique instrumentos e desenvolva sua expressão através da música.',
      skillName: 'Criatividade Musical',
      displayOrder: 6,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: false,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'music_room',
      unlockHint: 'Leitura nível 2',
      unlockRule: HobbyUnlockRule.requires({'hobby:leitura': 2}),
    ),
    HobbyDefinition(
      id: 'culinaria',
      displayName: 'Culinária',
      description:
          'Experimente receitas, conheça novos sabores e desenvolva habilidade na cozinha.',
      skillName: 'Talento Culinário',
      displayOrder: 7,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: false,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'kitchen',
      unlockHint: 'Meditação nível 2',
      unlockRule: HobbyUnlockRule.requires({'hobby:meditacao': 2}),
    ),
    HobbyDefinition(
      id: 'fotografia',
      displayName: 'Fotografia',
      description:
          'Observe o mundo com atenção e transforme momentos em imagens marcantes.',
      skillName: 'Percepção',
      displayOrder: 8,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: false,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'city',
      unlockHint: 'Leitura nível 3',
      unlockRule: HobbyUnlockRule.requires({'hobby:leitura': 3}),
    ),
    HobbyDefinition(
      id: 'oratoria',
      displayName: 'Oratória',
      description:
          'Pratique comunicação, clareza e confiança para falar com diferentes pessoas.',
      skillName: 'Comunicação',
      displayOrder: 9,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: false,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'community_center',
      unlockHint: 'Teatro nível 3',
      unlockRule: HobbyUnlockRule.requires({'hobby:teatro': 3}),
    ),
    HobbyDefinition(
      id: 'programacao',
      displayName: 'Programação',
      description:
          'Estude lógica, desenvolva projetos e aprenda a transformar ideias em sistemas.',
      skillName: 'Tecnologia',
      displayOrder: 10,
      maximumLevel: maximumHobbyLevel,
      initialAvailability: false,
      trainingDurationsByLevel: baseHobbyTrainingDurationsByLevel,
      timeCostsByLevel: baseHobbyTimeCostsByLevel,
      xpPerTrainingCycle: hobbyXpPerTrainingCycle,
      futureLocationId: 'home_office',
      unlockHint: 'Leitura nível 4',
      unlockRule: HobbyUnlockRule.requires({'hobby:leitura': 4}),
    ),
  ];
  static const gifts = [
    GiftDefinition(
      id: 'love_letter',
      displayName: 'Carta de amor',
      unitPrice: 10,
      affectionPerUnit: 1,
      category: GiftCategory.start,
      displayOrder: 1,
      description:
          'O item básico que dá pouquíssimo afeto, mas pode ser entregue em grande quantidade.',
    ),
    GiftDefinition(
      id: 'coffee',
      displayName: 'Café',
      unitPrice: 25,
      affectionPerUnit: 3,
      category: GiftCategory.start,
      displayOrder: 2,
      description: 'Um convite simples e rápido.',
    ),
    GiftDefinition(
      id: 'chocolate',
      displayName: 'Chocolate',
      unitPrice: 50,
      affectionPerUnit: 5,
      category: GiftCategory.start,
      displayOrder: 3,
      description: 'Um agrado clássico.',
    ),
    GiftDefinition(
      id: 'cd_playlist',
      displayName: 'CD/Playlist',
      unitPrice: 100,
      affectionPerUnit: 10,
      category: GiftCategory.start,
      displayOrder: 4,
      description: 'Mostra interesse nos gostos da pessoa.',
    ),
    GiftDefinition(
      id: 'flowers',
      displayName: 'Flores',
      unitPrice: 250,
      affectionPerUnit: 25,
      category: GiftCategory.start,
      displayOrder: 5,
      description: 'O primeiro presente mais romântico.',
    ),
    GiftDefinition(
      id: 'books',
      displayName: 'Livros',
      unitPrice: 500,
      affectionPerUnit: 50,
      category: GiftCategory.start,
      displayOrder: 6,
      description: 'Um presente atencioso que exige um pouco mais de dinheiro.',
    ),
    GiftDefinition(
      id: 'cake',
      displayName: 'Bolo',
      unitPrice: 1000,
      affectionPerUnit: 100,
      category: GiftCategory.start,
      displayOrder: 7,
      description:
          'Um bolo inteiro de confeitaria para comemorar um momento importante.',
    ),
    GiftDefinition(
      id: 'photo_album',
      displayName: 'Álbum de fotos',
      unitPrice: 2500,
      affectionPerUnit: 250,
      category: GiftCategory.middle,
      displayOrder: 8,
      description: 'Representa as memórias que já construíram.',
    ),
    GiftDefinition(
      id: 'plush',
      displayName: 'Pelúcia',
      unitPrice: 5000,
      affectionPerUnit: 500,
      category: GiftCategory.middle,
      displayOrder: 9,
      description:
          'Uma daquelas pelúcias gigantes e caras de parque de diversões.',
    ),
    GiftDefinition(
      id: 'wine',
      displayName: 'Vinho',
      unitPrice: 12000,
      affectionPerUnit: 1200,
      category: GiftCategory.middle,
      displayOrder: 10,
      description: 'Uma garrafa de safra especial.',
    ),
    GiftDefinition(
      id: 'perfume',
      displayName: 'Perfume',
      unitPrice: 25000,
      affectionPerUnit: 2500,
      category: GiftCategory.middle,
      displayOrder: 11,
      description: 'Um perfume de marca cuidadosamente escolhido.',
    ),
    GiftDefinition(
      id: 'headphones',
      displayName: 'Fone de ouvido',
      unitPrice: 50000,
      affectionPerUnit: 5000,
      category: GiftCategory.middle,
      displayOrder: 12,
      description: 'Equipamento de áudio de alta qualidade.',
    ),
    GiftDefinition(
      id: 'talisman',
      displayName: 'Talismã',
      unitPrice: 100000,
      affectionPerUnit: 10000,
      category: GiftCategory.middle,
      displayOrder: 13,
      description:
          'Um amuleto raro de grande valor espiritual ou difícil obtenção.',
    ),
    GiftDefinition(
      id: 'bag',
      displayName: 'Bolsa',
      unitPrice: 250000,
      affectionPerUnit: 25000,
      category: GiftCategory.middle,
      displayOrder: 14,
      description: 'Uma bolsa de grife famosa.',
    ),
    GiftDefinition(
      id: 'phone',
      displayName: 'Celular',
      unitPrice: 750000,
      affectionPerUnit: 75000,
      category: GiftCategory.end,
      displayOrder: 15,
      description: 'O modelo de última geração.',
    ),
    GiftDefinition(
      id: 'camera',
      displayName: 'Câmera',
      unitPrice: 2000000,
      affectionPerUnit: 200000,
      category: GiftCategory.end,
      displayOrder: 16,
      description: 'Equipamento fotográfico profissional completo.',
    ),
    GiftDefinition(
      id: 'painted_portrait',
      displayName: 'Retrato em pintura',
      unitPrice: 5000000,
      affectionPerUnit: 500000,
      category: GiftCategory.end,
      displayOrder: 17,
      description: 'Uma arte exclusiva encomendada a um mestre.',
    ),
    GiftDefinition(
      id: 'jewelry',
      displayName: 'Joias',
      unitPrice: 15000000,
      affectionPerUnit: 1500000,
      category: GiftCategory.end,
      displayOrder: 18,
      description: 'Joias com diamantes ou pedras raras.',
    ),
    GiftDefinition(
      id: 'trip',
      displayName: 'Viagem',
      unitPrice: 50000000,
      affectionPerUnit: 5000000,
      category: GiftCategory.end,
      displayOrder: 19,
      description: 'Uma viagem internacional de luxo com tudo pago.',
    ),
    GiftDefinition(
      id: 'wedding_ring',
      displayName: 'Anel de casamento',
      unitPrice: 200000000,
      affectionPerUnit: 20000000,
      category: GiftCategory.end,
      displayOrder: 20,
      description: 'O presente máximo para uma relação que chegou muito longe.',
    ),
  ];
  static const encounters = [
    EncounterDefinition(
      'cafeteria',
      'Café depois do programa',
      55,
      2,
      35,
      18,
      1,
    ),
    EncounterDefinition(
      'parque',
      'Passeio pela cidade à noite',
      110,
      2,
      50,
      36,
      2,
    ),
    EncounterDefinition(
      'cinema',
      'Visita ao estúdio de rádio',
      190,
      3,
      65,
      62,
      3,
    ),
    EncounterDefinition('restaurante', 'Evento musical', 320, 3, 80, 100, 4),
    EncounterDefinition(
      'viagem',
      'Noite especial da rota atual',
      750,
      4,
      120,
      220,
      6,
    ),
  ];
  static const relationshipStages = {
    PlayableCharacterIds.roxanne: [
      RelationshipStageDefinition(1),
      RelationshipStageDefinition(2),
      RelationshipStageDefinition(3, storyEpisodeId: 'roxanne_after_hours'),
      RelationshipStageDefinition(4),
      RelationshipStageDefinition(5),
      RelationshipStageDefinition(6),
      RelationshipStageDefinition(7),
      RelationshipStageDefinition(8),
      RelationshipStageDefinition(9),
    ],
  };
  static String? storyEpisodeForStage(String characterId, int stage) =>
      relationshipStages[PlayableCharacterCatalog.canonicalId(characterId)]
          ?.where((item) => item.stage == stage)
          .firstOrNull
          ?.storyEpisodeId;
  static JobDefinition job(String id) =>
      jobs.firstWhere((item) => item.id == id);
  static HobbyDefinition hobby(String id) =>
      hobbies.firstWhere((item) => item.id == id);
  static String jobRoleTitle(String id, int level) =>
      job(id).rankAtLevel(level);

  static String? nextJobRoleTitle(String id, int level) {
    final definition = job(id);
    if (level >= definition.maximumLevel) return null;
    return definition.rankAtLevel(level + 1);
  }

  static Duration jobCycleDuration(String id, int level) =>
      job(id).cycleDurationAtLevel(level);

  static int jobTimeCost(String id, int level) =>
      job(id).timeCostAtLevel(level);

  static int jobReward(String id, int level) => job(id).rewardAtLevel(level);

  static Duration hobbyTrainingDuration(String id, int level) =>
      hobby(id).trainingDurationAtLevel(level);

  static int hobbyTimeCost(String id, int level) =>
      hobby(id).timeCostAtLevel(level);

  static int hobbyTrainingXp(String id) => hobby(id).xpPerTrainingCycle;

  static List<String> validateJobCatalog() {
    final errors = <String>[];
    final ids = <String>{};
    final hobbyIdSet = hobbies.map((item) => item.id).toSet();
    for (final job in jobs) {
      if (job.id.isEmpty) errors.add('ID vazio');
      if (!ids.add(job.id)) errors.add('ID duplicado: ${job.id}');
      if (job.displayOrder <= 0) errors.add('Ordem inválida: ${job.id}');
      if (job.maximumLevel != maximumJobLevel) {
        errors.add('Nível máximo inválido: ${job.id}');
      }
      if (job.cycleDurationsByLevel.length != maximumJobLevel) {
        errors.add('Durações inválidas: ${job.id}');
      }
      if (job.timeCostsByLevel.length != maximumJobLevel) {
        errors.add('Custos inválidos: ${job.id}');
      }
      if (job.rankNames.length != maximumJobLevel ||
          job.rankNames.any((rank) => rank.trim().isEmpty)) {
        errors.add('Cargos inválidos: ${job.id}');
      }
      if (job.baseReward <= 0) errors.add('Recompensa inválida: ${job.id}');
      if (job.xpPerCycle <= 0) errors.add('XP inválido: ${job.id}');
      if (job.cycleDurationsByLevel.any((duration) => duration.isNegative)) {
        errors.add('Duração negativa: ${job.id}');
      }
      if (job.timeCostsByLevel.any((cost) => cost < 0)) {
        errors.add('Custo negativo: ${job.id}');
      }
      if (job.maximumLevelIncomeInterval <= Duration.zero) {
        errors.add('Intervalo máximo inválido: ${job.id}');
      }
      for (final requirement in job.requirements) {
        final valid = switch (requirement.type) {
          JobRequirementType.jobLevel => jobs.any(
            (item) => item.id == requirement.targetId,
          ),
          JobRequirementType.hobbyLevel => hobbyIdSet.contains(
            requirement.targetId,
          ),
          JobRequirementType.skillLevel => requirement.targetId.isNotEmpty,
          JobRequirementType.relationshipStage =>
            PlayableCharacterCatalog.maybeById(requirement.targetId) != null,
          JobRequirementType.money => requirement.value >= 0,
          JobRequirementType.eventCompleted ||
          JobRequirementType.locationDiscovered =>
            requirement.targetId.isNotEmpty,
        };
        if (!valid) {
          errors.add('Requisito inválido: ${job.id}/${requirement.targetId}');
        }
      }
    }
    return errors;
  }

  static List<String> validateHobbyCatalog() {
    final errors = <String>[];
    if (hobbies.length != 10) {
      errors.add('Quantidade de hobbies inválida: ${hobbies.length}');
    }
    final ids = <String>{};
    final orders = <int>{};
    final hobbyIdSet = hobbies.map((item) => item.id).toSet();
    for (final hobby in hobbies) {
      if (hobby.id.isEmpty) errors.add('ID de hobby vazio');
      if (!ids.add(hobby.id)) errors.add('ID de hobby duplicado: ${hobby.id}');
      if (!orders.add(hobby.displayOrder)) {
        errors.add('Ordem de hobby duplicada: ${hobby.displayOrder}');
      }
      if (hobby.displayName.trim().isEmpty) {
        errors.add('Nome de hobby vazio: ${hobby.id}');
      }
      if (hobby.description.trim().isEmpty) {
        errors.add('Descrição de hobby vazia: ${hobby.id}');
      }
      if (hobby.skillName.trim().isEmpty) {
        errors.add('Habilidade de hobby vazia: ${hobby.id}');
      }
      if (hobby.maximumLevel != maximumHobbyLevel) {
        errors.add('Nível máximo de hobby inválido: ${hobby.id}');
      }
      if (hobby.trainingDurationsByLevel.length != maximumHobbyLevel) {
        errors.add('Durações de hobby inválidas: ${hobby.id}');
      }
      if (hobby.timeCostsByLevel.length != maximumHobbyLevel) {
        errors.add('Custos de Tempo de hobby inválidos: ${hobby.id}');
      }
      if (hobby.trainingDurationsByLevel.any(
        (duration) => duration <= Duration.zero,
      )) {
        errors.add('Duração de hobby não positiva: ${hobby.id}');
      }
      if (hobby.timeCostsByLevel.any((cost) => cost < 0)) {
        errors.add('Custo de Tempo de hobby negativo: ${hobby.id}');
      }
      if (hobby.xpPerTrainingCycle <= 0) {
        errors.add('XP por ciclo de hobby inválido: ${hobby.id}');
      }
      for (final requirement in hobby.requires.entries) {
        final parts = requirement.key.split(':');
        final valid =
            parts.length == 2 &&
            parts.first == 'hobby' &&
            hobbyIdSet.contains(parts.last) &&
            requirement.value > 0 &&
            requirement.value <= maximumHobbyLevel;
        if (!valid) {
          errors.add(
            'Requisito de hobby inválido: ${hobby.id}/${requirement.key}',
          );
        }
      }
    }
    for (var order = 1; order <= hobbies.length; order++) {
      if (!orders.contains(order)) errors.add('Ordem ausente: $order');
    }
    return errors;
  }

  static GiftDefinition gift(String id) =>
      gifts.firstWhere((item) => item.id == id);
  static EncounterDefinition encounter(String id) =>
      encounters.firstWhere((item) => item.id == id);
}
