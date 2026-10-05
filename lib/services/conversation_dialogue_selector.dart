import 'dart:math';

import '../core/character_catalog.dart';
import '../data/dialogues/character_dialogue_catalog.dart';

/// Session-only random selection for conversation dialogue pools.
/// The key scopes anti-repetition to a character and relationship stage.
class ConversationDialogueSelector {
  ConversationDialogueSelector({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, String> _lastDialogueIds = {};

  ConversationDialogue select({
    required String characterId,
    required int stage,
  }) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    final pool = CharacterDialogueCatalog.conversationPool(canonicalId, stage);
    if (pool.isEmpty) return CharacterDialogueCatalog.unavailableConversation;

    final historyKey = '$canonicalId:$stage';
    final previousId = _lastDialogueIds[historyKey];
    final candidates = pool.length == 1 || previousId == null
        ? pool
        : pool
              .where((dialogue) => dialogue.id != previousId)
              .toList(growable: false);
    final selected = candidates[_random.nextInt(candidates.length)];
    _lastDialogueIds[historyKey] = selected.id;
    return selected;
  }

  String? lastDialogueIdFor({
    required String characterId,
    required int stage,
  }) =>
      _lastDialogueIds['${PlayableCharacterCatalog.canonicalId(characterId)}:$stage'];
}
