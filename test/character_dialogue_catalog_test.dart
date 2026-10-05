import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/data/dialogues/character_dialogue_catalog.dart';
import 'package:projeto_conexoes/services/conversation_dialogue_selector.dart';

void main() {
  group('catálogo de conversas da Roxanne', () {
    test('tem 10 pools independentes com exatamente 5 falas cada', () {
      final catalog =
          CharacterDialogueCatalog.conversations[PlayableCharacterIds.roxanne]!;

      expect(
        catalog.keys.toSet(),
        equals(Set<int>.from(List.generate(10, (i) => i))),
      );
      expect(catalog.values.every((pool) => pool.length == 5), isTrue);
      expect(catalog.values.expand((pool) => pool).length, 50);
    });

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

    test('não repete imediatamente dentro do mesmo personagem e estágio', () {
      final selector = ConversationDialogueSelector(random: Random(4));
      String? lastId;

      for (var index = 0; index < 30; index++) {
        final selected = selector.select(
          characterId: PlayableCharacterIds.roxanne,
          stage: 2,
        );
        expect(selected.id, isNot(lastId));
        lastId = selected.id;
      }
      expect(
        selector.lastDialogueIdFor(
          characterId: PlayableCharacterIds.roxanne,
          stage: 2,
        ),
        lastId,
      );
    });

    test(
      'personagens sem catálogo usam fallback seguro sem falas da Roxanne',
      () {
        final selector = ConversationDialogueSelector(random: Random(1));
        final selected = selector.select(
          characterId: PlayableCharacterIds.kai,
          stage: 0,
        );

        expect(
          selected,
          same(CharacterDialogueCatalog.unavailableConversation),
        );
        expect(selected.text, 'Mais diálogos serão adicionados futuramente.');
        expect(selected.id, isNot(contains('roxanne')));
      },
    );
  });
}
