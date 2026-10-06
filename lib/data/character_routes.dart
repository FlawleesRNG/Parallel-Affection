import '../core/character_catalog.dart';
import 'date_locations.dart';

enum CharacterRouteRequirementType {
  hobbyLevel,
  jobLevel,
  giftDelivered,
  eventCompleted,
  money,
}

class CharacterRouteRequirement {
  const CharacterRouteRequirement({
    required this.type,
    required this.targetId,
    required this.requiredValue,
    this.sourceLabel,
    this.sourceNote,
  });

  const CharacterRouteRequirement.hobbyLevel(String hobbyId, int level)
    : this(
        type: CharacterRouteRequirementType.hobbyLevel,
        targetId: hobbyId,
        requiredValue: level,
      );

  const CharacterRouteRequirement.jobLevel(String jobId, int level)
    : this(
        type: CharacterRouteRequirementType.jobLevel,
        targetId: jobId,
        requiredValue: level,
      );

  const CharacterRouteRequirement.giftDelivered(
    String giftId,
    int quantity, {
    String? sourceLabel,
    String? sourceNote,
  }) : this(
         type: CharacterRouteRequirementType.giftDelivered,
         targetId: giftId,
         requiredValue: quantity,
         sourceLabel: sourceLabel,
         sourceNote: sourceNote,
       );

  const CharacterRouteRequirement.unresolvedGift(
    String giftId, {
    required String sourceLabel,
    required String sourceNote,
  }) : this(
         type: CharacterRouteRequirementType.giftDelivered,
         targetId: giftId,
         requiredValue: null,
         sourceLabel: sourceLabel,
         sourceNote: sourceNote,
       );

  const CharacterRouteRequirement.eventCompleted(
    String eventId, {
    String? sourceLabel,
    String? sourceNote,
  }) : this(
         type: CharacterRouteRequirementType.eventCompleted,
         targetId: eventId,
         requiredValue: 1,
         sourceLabel: sourceLabel,
         sourceNote: sourceNote,
       );

  final CharacterRouteRequirementType type;
  final String targetId;
  final int? requiredValue;
  final String? sourceLabel;
  final String? sourceNote;

  bool get isResolved => requiredValue != null && requiredValue! > 0;
}

class CharacterRouteStageDefinition {
  const CharacterRouteStageDefinition({
    required this.stageIndex,
    required this.affectionRequired,
    required this.requirements,
    required this.sourceSummary,
    this.futureNarrativeEventId,
    this.completionMetadata = const {},
  });

  final int stageIndex;
  final int affectionRequired;
  final List<CharacterRouteRequirement> requirements;
  final String sourceSummary;
  final String? futureNarrativeEventId;
  final Map<String, String> completionMetadata;
}

class CharacterRouteDefinition {
  const CharacterRouteDefinition({
    required this.characterId,
    required this.stageDefinitions,
    required this.sourceMetadata,
    required this.routeContentReady,
    this.sourceName,
    this.futureNarrativeMetadata = const {},
  });

  final String characterId;
  final List<CharacterRouteStageDefinition> stageDefinitions;
  final Map<String, String> sourceMetadata;
  final bool routeContentReady;
  final String? sourceName;
  final Map<String, String> futureNarrativeMetadata;

  CharacterRouteStageDefinition stageFor(int stageIndex) =>
      stageDefinitions[stageIndex.clamp(0, stageDefinitions.length - 1)];
}

abstract final class CharacterRouteCatalog {
  static const sourceDocument =
      'LORE + OBJETIVOS/Nível de Relações de Parallel Affecion.docx';

  static const affectionByStage = [
    100,
    150,
    200,
    250,
    300,
    350,
    400,
    450,
    500,
    550,
  ];

  static const roxanne = CharacterRouteDefinition(
    characterId: PlayableCharacterIds.roxanne,
    sourceName: 'Roxxy',
    routeContentReady: true,
    sourceMetadata: {
      'sourceDocument': sourceDocument,
      'sourceSection': 'Nível de Relação - ROXXY',
      'sourceAlias': 'Roxxy',
    },
    futureNarrativeMetadata: {
      'theme': 'rádio, música, bastidores e persona pública',
    },
    stageDefinitions: [
      CharacterRouteStageDefinition(
        stageIndex: 0,
        affectionRequired: 100,
        sourceSummary:
            'O jogador ouve a Roxxy, mas esbarra na tímida Roxanne na rua.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('musica', 1),
          CharacterRouteRequirement.giftDelivered('coffee', 10),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 1,
        affectionRequired: 150,
        sourceSummary:
            'O jogador descobre a identidade dela; ela teme que o segredo seja vazado.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 2),
          CharacterRouteRequirement.jobLevel('radio_assistant', 1),
          CharacterRouteRequirement.giftDelivered('love_letter', 1),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 2,
        affectionRequired: 200,
        sourceSummary:
            'Trabalhando na mesma rádio, eles começam a se falar sem máscaras.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('leitura', 2),
          CharacterRouteRequirement.jobLevel('radio_assistant', 2),
          CharacterRouteRequirement.giftDelivered('chocolate', 20),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 3,
        affectionRequired: 250,
        sourceSummary:
            'Ela começa a pedir sua opinião sincera sobre a programação da rádio.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('musica', 4),
          CharacterRouteRequirement.jobLevel('radio_assistant', 3),
          CharacterRouteRequirement.giftDelivered('cd_playlist', 50),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 4,
        affectionRequired: 300,
        sourceSummary:
            'Ela revela o lado fofo e passa a confiar no protagonista nos bastidores.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 4),
          CharacterRouteRequirement.jobLevel('radio_assistant', 4),
          CharacterRouteRequirement.giftDelivered('books', 300),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 5,
        affectionRequired: 350,
        sourceSummary:
            'Encontros fora da rádio começam a acontecer em lugares tranquilos.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('leitura', 6),
          CharacterRouteRequirement.jobLevel('radio_assistant', 6),
          CharacterRouteRequirement.giftDelivered('plush', 100),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 6,
        affectionRequired: 400,
        sourceSummary:
            'Ela cria uma persona mais carinhosa no ar, secretamente direcionada a você.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('musica', 7),
          CharacterRouteRequirement.jobLevel('radio_assistant', 7),
          CharacterRouteRequirement.giftDelivered('headphones', 50),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 7,
        affectionRequired: 450,
        sourceSummary:
            'Roxanne aceita os próprios sentimentos e junta as duas personas.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 8),
          CharacterRouteRequirement.jobLevel('radio_assistant', 8),
          CharacterRouteRequirement.giftDelivered('talisman', 75),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 8,
        affectionRequired: 500,
        sourceSummary:
            'O segredo está seguro e vocês constroem uma vida juntos fora dos estúdios.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('leitura', 10),
          CharacterRouteRequirement.jobLevel('radio_assistant', 9),
          CharacterRouteRequirement.giftDelivered('trip', 8),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 9,
        affectionRequired: 550,
        sourceSummary:
            'Conclusão da rota com uma confissão ou declaração oficial.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('musica', 10),
          CharacterRouteRequirement.jobLevel('radio_assistant', 10),
          CharacterRouteRequirement.giftDelivered('wedding_ring', 1),
        ],
      ),
    ],
  );

  static const kai = CharacterRouteDefinition(
    characterId: PlayableCharacterIds.kai,
    routeContentReady: true,
    sourceMetadata: {
      'sourceDocument': sourceDocument,
      'sourceSection': 'Relações - KAI',
    },
    futureNarrativeMetadata: {'theme': 'skate, fotografia e campeonato'},
    stageDefinitions: [
      CharacterRouteStageDefinition(
        stageIndex: 0,
        affectionRequired: 100,
        sourceSummary:
            'Um esbarrão acidental enquanto ela treinava manobras perigosas na rua.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('academia', 1),
          CharacterRouteRequirement.giftDelivered('coffee', 50),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 1,
        affectionRequired: 150,
        sourceSummary:
            'No acidente, ela quebra o braço esquerdo e teme perder o Infinity Loop.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('fotografia', 2),
          CharacterRouteRequirement.jobLevel('freelance_photography', 1),
          CharacterRouteRequirement.giftDelivered('chocolate', 45),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 2,
        affectionRequired: 200,
        sourceSummary:
            'Você ajuda a carregar o skate e as coisas dela durante a recuperação.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 2),
          CharacterRouteRequirement.jobLevel('freelance_photography', 2),
          CharacterRouteRequirement.giftDelivered('cd_playlist', 100),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 3,
        affectionRequired: 250,
        sourceSummary:
            'Ela volta a treinar manobras de perna e pede para você filmá-la.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('academia', 4),
          CharacterRouteRequirement.jobLevel('freelance_photography', 3),
          CharacterRouteRequirement.giftDelivered('cake', 35),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 4,
        affectionRequired: 300,
        sourceSummary: 'A dinâmica de atleta e filmmaker se consolida.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('fotografia', 4),
          CharacterRouteRequirement.jobLevel('freelance_photography', 4),
          CharacterRouteRequirement.giftDelivered('photo_album', 60),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 5,
        affectionRequired: 350,
        sourceSummary:
            'O treino para o Infinity Loop aperta e ela mostra vulnerabilidade.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 6),
          CharacterRouteRequirement.jobLevel('freelance_photography', 6),
          CharacterRouteRequirement.giftDelivered('headphones', 90),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 6,
        affectionRequired: 400,
        sourceSummary:
            'Ela começa a demonstrar interesse de forma física e espontânea.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('academia', 7),
          CharacterRouteRequirement.jobLevel('freelance_photography', 7),
          CharacterRouteRequirement.giftDelivered('talisman', 80),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 7,
        affectionRequired: 450,
        sourceSummary:
            'Chega o Infinity Loop; ela reconhece sua ajuda antes da competição.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('fotografia', 8),
          CharacterRouteRequirement.jobLevel('freelance_photography', 8),
          CharacterRouteRequirement.giftDelivered('camera', 90),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 8,
        affectionRequired: 500,
        sourceSummary: 'Após o pódio, ela assume a relação diante de todos.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 10),
          CharacterRouteRequirement.jobLevel('freelance_photography', 9),
          CharacterRouteRequirement.giftDelivered('trip', 5),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 9,
        affectionRequired: 550,
        sourceSummary:
            'Vocês viajam o mundo juntos, ela como skatista e você como fotógrafo.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('fotografia', 10),
          CharacterRouteRequirement.jobLevel('freelance_photography', 10),
          CharacterRouteRequirement.giftDelivered('wedding_ring', 1),
        ],
      ),
    ],
  );

  static const sofia = CharacterRouteDefinition(
    characterId: PlayableCharacterIds.sofia,
    routeContentReady: true,
    sourceMetadata: {
      'sourceDocument': sourceDocument,
      'sourceSection': 'Relações - Sofia',
    },
    futureNarrativeMetadata: {'theme': 'cafeteria, luxo e família'},
    stageDefinitions: [
      CharacterRouteStageDefinition(
        stageIndex: 0,
        affectionRequired: 100,
        sourceSummary:
            'Você esbarra nela no balcão e derruba café na roupa de grife.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('culinaria', 1),
          CharacterRouteRequirement.giftDelivered('coffee', 1),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 1,
        affectionRequired: 150,
        sourceSummary:
            'Ela reclama e passa a ir à cafeteria para avaliar seu trabalho.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('oratoria', 2),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 1),
          CharacterRouteRequirement.giftDelivered('cake', 20),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 2,
        affectionRequired: 200,
        sourceSummary:
            'As reclamações diminuem e ela pede bebidas secretas complexas.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('leitura', 2),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 2),
          CharacterRouteRequirement.giftDelivered('flowers', 400),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 3,
        affectionRequired: 250,
        sourceSummary: 'Você devolve um livro ou diário esquecido sem ler.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('culinaria', 4),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 3),
          CharacterRouteRequirement.giftDelivered('books', 1000),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 4,
        affectionRequired: 300,
        sourceSummary:
            'Ela desabafa sobre a pressão do pai e inseguranças pessoais.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('oratoria', 4),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 4),
          CharacterRouteRequirement.giftDelivered('perfume', 250),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 5,
        affectionRequired: 350,
        sourceSummary:
            'Ela defende você de um cliente arrogante no modo tsundere.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('leitura', 6),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 6),
          CharacterRouteRequirement.giftDelivered('bag', 15),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 6,
        affectionRequired: 400,
        sourceSummary:
            'Ela obriga você a ser acompanhante falso em uma festa de gala.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('oratoria', 7),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 7),
          CharacterRouteRequirement.giftDelivered('jewelry', 35),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 7,
        affectionRequired: 450,
        sourceSummary:
            'Na varanda da festa, o fingimento cai e ela confessa seus sentimentos.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('culinaria', 8),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 8),
          CharacterRouteRequirement.giftDelivered('painted_portrait', 50),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 8,
        affectionRequired: 500,
        sourceSummary:
            'Você enfrenta o pai dela com classe usando sua Oratória.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('oratoria', 10),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 9),
          CharacterRouteRequirement.giftDelivered('trip', 5),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 9,
        affectionRequired: 550,
        sourceSummary:
            'Ela assume a própria independência e vocês administram negócios juntos.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('culinaria', 10),
          CharacterRouteRequirement.jobLevel('cafe_assistant', 10),
          CharacterRouteRequirement.giftDelivered('wedding_ring', 1),
        ],
      ),
    ],
  );

  static const astra = CharacterRouteDefinition(
    characterId: PlayableCharacterIds.astra,
    routeContentReady: false,
    sourceMetadata: {
      'sourceDocument': sourceDocument,
      'sourceSection': 'Relações - Astra',
      'conflict': 'Estágio 5 cita Vinho, mas não informa quantidade.',
    },
    futureNarrativeMetadata: {
      'theme': 'In-Meow/Guilda, magia, segredo e metamorfose',
    },
    stageDefinitions: [
      CharacterRouteStageDefinition(
        stageIndex: 0,
        affectionRequired: 100,
        sourceSummary:
            'Você visita o In-Meow/Guilda e ela entrega um panfleto.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 1),
          CharacterRouteRequirement.giftDelivered('love_letter', 100000),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 1,
        affectionRequired: 150,
        sourceSummary:
            'Você toca nas orelhas de adereço; elas se mexem e ela entra em pânico.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 2),
          CharacterRouteRequirement.jobLevel('local_flyering', 1),
          CharacterRouteRequirement.giftDelivered('coffee', 500),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 2,
        affectionRequired: 200,
        sourceSummary:
            'Você trabalha entregando panfletos do café para provar que não é ameaça.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 2),
          CharacterRouteRequirement.jobLevel('local_flyering', 2),
          CharacterRouteRequirement.giftDelivered('chocolate', 100000),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 3,
        affectionRequired: 250,
        sourceSummary:
            'Ela volta a provocar de forma mais genuína e maneirismos felinos vazam.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 4),
          CharacterRouteRequirement.jobLevel('local_flyering', 3),
          CharacterRouteRequirement.giftDelivered('plush', 5000),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 4,
        affectionRequired: 300,
        sourceSummary:
            'Ela desabafa sobre o cansaço de manter as aparências todos os dias.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 4),
          CharacterRouteRequirement.jobLevel('local_flyering', 4),
          CharacterRouteRequirement.unresolvedGift(
            'wine',
            sourceLabel: 'Vinho',
            sourceNote: 'Preço documentado, quantidade ausente no DOCX.',
          ),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 5,
        affectionRequired: 350,
        sourceSummary:
            'A ilusão falha por um segundo e você a encobre rapidamente.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 6),
          CharacterRouteRequirement.jobLevel('local_flyering', 6),
          CharacterRouteRequirement.giftDelivered('talisman', 9999),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 6,
        affectionRequired: 400,
        sourceSummary:
            'Ela permite que aura e traços verdadeiros apareçam quando estão sozinhos.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 7),
          CharacterRouteRequirement.jobLevel('local_flyering', 7),
          CharacterRouteRequirement.giftDelivered('perfume', 6767),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 7,
        affectionRequired: 450,
        sourceSummary:
            'Ela desfaz a magia e mostra sua forma real com medo da sua reação.',
        futureNarrativeEventId: 'astra_reveals_true_form',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 8),
          CharacterRouteRequirement.jobLevel('local_flyering', 8),
          CharacterRouteRequirement.giftDelivered('phone', 25000),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 8,
        affectionRequired: 500,
        sourceSummary:
            'Vocês assumem o relacionamento; a ilusão fica só para o público.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('teatro', 10),
          CharacterRouteRequirement.jobLevel('local_flyering', 9),
          CharacterRouteRequirement.giftDelivered('trip', 5),
        ],
      ),
      CharacterRouteStageDefinition(
        stageIndex: 9,
        affectionRequired: 550,
        sourceSummary:
            'Ela aceita quem é de verdade e vocês podem administrar a guilda juntos.',
        requirements: [
          CharacterRouteRequirement.hobbyLevel('meditacao', 10),
          CharacterRouteRequirement.jobLevel('local_flyering', 10),
          CharacterRouteRequirement.giftDelivered('wedding_ring', 1),
        ],
      ),
    ],
  );

  static const all = [roxanne, kai, sofia, astra];

  static CharacterRouteDefinition? maybeFor(String characterId) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    for (final route in all) {
      if (route.characterId == canonicalId) return route;
    }
    return null;
  }

  static CharacterRouteDefinition byCharacterId(String characterId) =>
      maybeFor(characterId) ?? roxanne;
}

/// Mechanical date goals are kept separate from lore requirements so adding a
/// location never rewrites approved hobby, job, gift or affection data.
abstract final class CharacterDateRequirements {
  static const _none = <DateRequirement>[];

  static const byCharacterAndStage = <String, List<List<DateRequirement>>>{
    PlayableCharacterIds.roxanne: [
      _none,
      _none,
      [DateRequirement('cafe', 1)],
      [DateRequirement('cafe', 3)],
      [DateRequirement('cinema', 1)],
      [DateRequirement('park', 3)],
      [DateRequirement('night_viewpoint', 1)],
      [DateRequirement('night_viewpoint', 3)],
      [DateRequirement('restaurant', 2)],
      [DateRequirement('night_viewpoint', 5)],
    ],
    PlayableCharacterIds.kai: [
      _none,
      _none,
      [DateRequirement('park', 1)],
      [DateRequirement('park', 3)],
      [DateRequirement('arcade', 2)],
      [DateRequirement('cafe', 3)],
      [DateRequirement('amusement_park', 2)],
      [DateRequirement('amusement_park', 4)],
      [DateRequirement('restaurant', 2)],
      [DateRequirement('night_viewpoint', 4)],
    ],
    PlayableCharacterIds.sofia: [
      _none,
      _none,
      [DateRequirement('cafe', 1)],
      [DateRequirement('restaurant', 1)],
      [DateRequirement('restaurant', 3)],
      [DateRequirement('cinema', 2)],
      [DateRequirement('night_viewpoint', 2)],
      [DateRequirement('restaurant', 5)],
      [DateRequirement('night_viewpoint', 4)],
      [DateRequirement('restaurant', 8)],
    ],
    PlayableCharacterIds.astra: [
      _none,
      _none,
      [DateRequirement('cafe', 1)],
      [DateRequirement('arcade', 1)],
      [DateRequirement('cinema', 2)],
      [DateRequirement('park', 3)],
      [DateRequirement('night_viewpoint', 2)],
      [DateRequirement('night_viewpoint', 4)],
      [DateRequirement('restaurant', 3)],
      [DateRequirement('night_viewpoint', 6)],
    ],
  };

  static List<DateRequirement> forStage(String characterId, int stage) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    final values = byCharacterAndStage[canonicalId];
    if (values == null || stage < 0 || stage >= values.length) return _none;
    return values[stage];
  }
}
