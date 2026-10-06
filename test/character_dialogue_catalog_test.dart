import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/data/dialogues/character_dialogue_catalog.dart';
import 'package:projeto_conexoes/services/conversation_dialogue_selector.dart';

void main() {
  group('catálogo de conversas do elenco', () {
    const characterIds = [
      PlayableCharacterIds.roxanne,
      PlayableCharacterIds.kai,
      PlayableCharacterIds.sofia,
      PlayableCharacterIds.astra,
    ];

    test(
      'tem 10 pools independentes com exatamente 5 falas por personagem',
      () {
        for (final characterId in characterIds) {
          final catalog = CharacterDialogueCatalog.conversations[characterId]!;

          expect(
            catalog.keys.toSet(),
            equals(Set<int>.from(List.generate(10, (i) => i))),
          );
          expect(catalog.values.every((pool) => pool.length == 5), isTrue);
          expect(catalog.values.expand((pool) => pool).length, 50);
        }
        expect(
          CharacterDialogueCatalog.conversations.values
              .expand((catalog) => catalog.values)
              .expand((pool) => pool)
              .length,
          200,
        );
      },
    );

    test('resolve somente o pool do estágio solicitado', () {
      final stageOne = CharacterDialogueCatalog.conversationPool(
        PlayableCharacterIds.roxanne,
        0,
      );
      final stageFive = CharacterDialogueCatalog.conversationPool(
        PlayableCharacterIds.roxanne,
        4,
      );
      final stageTen = CharacterDialogueCatalog.conversationPool(
        PlayableCharacterIds.roxanne,
        9,
      );

      expect(
        stageOne.map((item) => item.id),
        everyElement(contains('stage_01')),
      );
      expect(
        stageFive.map((item) => item.id),
        everyElement(contains('stage_05')),
      );
      expect(
        stageTen.map((item) => item.id),
        everyElement(contains('stage_10')),
      );
      expect(
        stageOne.map((item) => item.text),
        contains(
          'Hm? Você queria alguma coisa... ou só resolveu ficar me olhando?',
        ),
      );
    });

    test('resolve somente o pool do estágio e personagem solicitados', () {
      for (final characterId in characterIds) {
        final stageOne = CharacterDialogueCatalog.conversationPool(
          characterId,
          0,
        );
        final stageFive = CharacterDialogueCatalog.conversationPool(
          characterId,
          4,
        );
        final stageTen = CharacterDialogueCatalog.conversationPool(
          characterId,
          9,
        );

        expect(
          stageOne.map((item) => item.id),
          everyElement(contains('stage_01')),
        );
        expect(
          stageFive.map((item) => item.id),
          everyElement(contains('stage_05')),
        );
        expect(
          stageTen.map((item) => item.id),
          everyElement(contains('stage_10')),
        );
        expect(
          stageOne.map((item) => item.id),
          everyElement(startsWith(characterId)),
        );
      }
    });

    test('não repete imediatamente dentro do mesmo personagem e estágio', () {
      for (final characterId in characterIds) {
        final selector = ConversationDialogueSelector(random: Random(4));
        String? lastId;

        for (var index = 0; index < 30; index++) {
          final selected = selector.select(characterId: characterId, stage: 2);
          expect(selected.id, isNot(lastId));
          lastId = selected.id;
        }
        expect(
          selector.lastDialogueIdFor(characterId: characterId, stage: 2),
          lastId,
        );
      }
    });

    test('personagens fora do elenco mantêm fallback seguro', () {
      final selector = ConversationDialogueSelector(random: Random(1));
      final selected = selector.select(characterId: 'unknown', stage: 0);

      expect(selected, same(CharacterDialogueCatalog.unavailableConversation));
      expect(selected.text, 'Mais diálogos serão adicionados futuramente.');
      expect(selected.id, isNot(contains('roxanne')));
    });
  });
}
