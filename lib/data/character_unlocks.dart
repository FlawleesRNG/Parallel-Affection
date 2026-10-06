import '../core/character_catalog.dart';

class CharacterUnlockDefinition {
  const CharacterUnlockDefinition({
    required this.characterId,
    this.sourceCharacterId,
    this.requiredStage,
    this.initiallyUnlocked = false,
  });

  final String characterId;
  final String? sourceCharacterId;
  final int? requiredStage;
  final bool initiallyUnlocked;
}

abstract final class CharacterUnlockCatalog {
  static const definitions = <CharacterUnlockDefinition>[
    CharacterUnlockDefinition(
      characterId: PlayableCharacterIds.roxanne,
      initiallyUnlocked: true,
    ),
    CharacterUnlockDefinition(
      characterId: PlayableCharacterIds.kai,
      sourceCharacterId: PlayableCharacterIds.roxanne,
      requiredStage: 2,
    ),
    CharacterUnlockDefinition(
      characterId: PlayableCharacterIds.sofia,
      sourceCharacterId: PlayableCharacterIds.kai,
      requiredStage: 3,
    ),
    CharacterUnlockDefinition(
      characterId: PlayableCharacterIds.astra,
      sourceCharacterId: PlayableCharacterIds.sofia,
      requiredStage: 4,
    ),
  ];

  static CharacterUnlockDefinition forCharacter(String characterId) =>
      definitions.firstWhere((item) => item.characterId == characterId);

  static bool isSatisfiedBy(
    CharacterUnlockDefinition definition,
    Map<String, int> stages,
  ) =>
      definition.initiallyUnlocked ||
      ((stages[definition.sourceCharacterId] ?? 0) >=
          (definition.requiredStage ?? 0));

  static String requirementText(String characterId) {
    final definition = forCharacter(characterId);
    if (definition.initiallyUnlocked) return 'Disponível desde o início.';
    final source = PlayableCharacterCatalog.visibleName(
      definition.sourceCharacterId!,
    );
    return 'Chegue a ${definition.requiredStage! + 1} com $source para desbloquear.';
  }
}
