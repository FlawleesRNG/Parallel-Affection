import '../../core/relationship_stages.dart';
import 'dialogue_message_v3.dart';

abstract final class RyomiDialogueCatalogV3 {
  static DialogueMessage initial() => DialogueMessage.create(
    id: 'roxanne_idle_initial',
    characterId: 'roxanne',
    speakerName: 'Roxanne',
    text:
        'Você apareceu de novo. Acho que a noite ficou um pouco menos silenciosa.',
    context: DialogueContext.idle,
    canRepeat: false,
  );

  static DialogueMessage fallback() => DialogueMessage.create(
    id: 'roxanne_fallback',
    characterId: 'roxanne',
    speakerName: 'Roxanne',
    text: 'Fica por aqui. Eu ainda estou encontrando as palavras certas.',
    context: DialogueContext.systemFallback,
  );

  static DialogueMessage talk(int stage, int sequence) {
    final lines = [
      'Eu ouvi sua voz no meio do ruído. Pode ficar mais um pouco?',
      'Você tem um jeito curioso de aparecer quando a noite fica longa.',
      'Se quiser conversar, eu deixo o silêncio esperar.',
      'Hoje eu consigo falar sem fugir tanto do assunto.',
    ];
    return DialogueMessage.create(
      id: 'roxanne_talk_${stage}_${sequence % lines.length}',
      characterId: 'roxanne',
      speakerName: 'Roxanne',
      text: lines[sequence % lines.length],
      context: DialogueContext.talk,
      relationshipStage: stage,
    );
  }

  static DialogueMessage interact(int stage, int sequence) {
    final lines = [
      'Ei... isso foi inesperado. Mas não foi ruim.',
      'Você conseguiu arrancar um sorriso meu. Só não espalha.',
      'Tá, admito: sua presença muda um pouco o clima.',
      'Isso foi gentil. Meio perigoso eu me acostumar, né?',
    ];
    return DialogueMessage.create(
      id: 'roxanne_interact_${stage}_${sequence % lines.length}',
      characterId: 'roxanne',
      speakerName: 'Roxanne',
      text: lines[sequence % lines.length],
      context: DialogueContext.interact,
      relationshipStage: stage,
    );
  }

  static DialogueMessage relationshipAdvance(int stage) {
    final config = RelationshipStageCatalog.byIndex(stage);
    return DialogueMessage.create(
      id: 'roxanne_relationship_advance_$stage',
      characterId: 'roxanne',
      speakerName: 'Roxanne',
      text: config.evolutionLine.isEmpty
          ? 'A conexão de vocês mudou de tom.'
          : config.evolutionLine,
      context: DialogueContext.relationshipAdvance,
      priority: DialoguePriority.important,
      relationshipStage: stage,
      canRepeat: false,
    );
  }

  static DialogueMessage unlock(String id, String text) =>
      DialogueMessage.create(
        id: 'roxanne_unlock_$id',
        characterId: 'roxanne',
        speakerName: 'Roxanne',
        text: text,
        context: DialogueContext.unlock,
        priority: DialoguePriority.important,
        canRepeat: false,
      );
}
