import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/core/idle_rules.dart';
import 'package:projeto_conexoes/data/character_routes.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/game_storage.dart';

class _MemoryStorage implements GameStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  test('roster oficial possui quatro IDs estáveis na ordem documentada', () {
    expect(PlayableCharacterCatalog.all.map((item) => item.id), [
      'roxanne',
      'kai',
      'sofia',
      'astra',
    ]);
    expect(PlayableCharacterCatalog.canonicalId('ryomi'), 'roxanne');
    expect(
      PlayableCharacterCatalog.all.map((item) => item.id),
      isNot(contains('roxxy')),
    );
  });

  test('assets canônicos das quatro personagens existem', () {
    for (final character in PlayableCharacterCatalog.all) {
      expect(
        File(character.sceneAsset).existsSync(),
        isTrue,
        reason: character.sceneAsset,
      );
      expect(
        File(character.effectiveSelectorAsset).existsSync(),
        isTrue,
        reason: character.effectiveSelectorAsset,
      );
      expect(character.sceneAsset, isNot(contains('.png.png')));
      expect(character.effectiveSelectorAsset, isNot(contains('.png.png')));
    }
    expect(
      PlayableCharacterCatalog.astra.selectorAsset,
      PlayableCharacterCatalog.astraSelectorAsset,
    );
    expect(
      PlayableCharacterCatalog.astra.effectiveSelectorAsset,
      PlayableCharacterCatalog.astraSelectorAsset,
    );
  });

  test('cada rota usa os dez estágios globais sem duplicar identidade', () {
    expect(CharacterRouteCatalog.all, hasLength(4));
    for (final route in CharacterRouteCatalog.all) {
      expect(route.stageDefinitions, hasLength(10));
      expect(
        route.stageDefinitions.map((stage) => stage.stageIndex),
        List.generate(10, (index) => index),
      );
      expect(
        route.stageDefinitions.every((stage) => stage.affectionRequired > 0),
        isTrue,
      );
    }
    expect(CharacterRouteCatalog.roxanne.sourceName, 'Roxxy');
    expect(CharacterRouteCatalog.astra.routeContentReady, isTrue);
  });

  test('requisitos são AND e consultam hobby, emprego e presente reais', () {
    final fresh = IdleState.fresh();
    final roxanne = fresh.characters['roxanne']!.copyWith(
      affection: 100,
      giftDeliveries: const {'coffee': 9},
    );
    var state = fresh.copyWith(
      characters: {...fresh.characters, 'roxanne': roxanne},
    );
    expect(IdleRules.canAdvance(state, 'roxanne'), isFalse);

    state = state.copyWith(
      characters: {
        ...state.characters,
        'roxanne': roxanne.copyWith(giftDeliveries: const {'coffee': 10}),
      },
    );
    expect(IdleRules.canAdvance(state, 'roxanne'), isTrue);
  });

  test('clique e contadores permanecem isolados por personagem', () async {
    final controller = GameController(_MemoryStorage());
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.debugSetCharacterUnlocked('sofia', true);

    await controller.tapCharacter('sofia');
    expect(controller.state.characters['sofia']!.affection, 1);
    expect(controller.state.characters['astra']!.affection, 0);
    expect(controller.state.characters['roxanne']!.affection, 0);

    await controller.debugSetGiftDelivery('sofia', 'coffee', 7);
    expect(controller.state.characters['sofia']!.giftDeliveries['coffee'], 7);
    expect(
      controller.state.characters['roxanne']!.giftDeliveries['coffee'] ?? 0,
      0,
    );
  });

  test('migração v6 preserva progresso e cria Sofia, Astra e contadores', () {
    final old = IdleState.fresh().copyWith(
      characters: {
        'roxanne': const CharacterProgress(
          unlocked: true,
          stage: 4,
          affection: 77,
        ),
        'kai': const CharacterProgress(unlocked: true, stage: 2, affection: 11),
      },
    );
    final json = jsonDecode(old.encode()) as Map<String, dynamic>;
    json['version'] = 6;
    for (final value in (json['characters'] as Map<String, dynamic>).values) {
      (value as Map<String, dynamic>).remove('giftDeliveries');
    }

    final migrated = IdleState.decode(jsonEncode(json));
    expect(migrated.characters['roxanne']!.stage, 4);
    expect(migrated.characters['kai']!.stage, 2);
    expect(migrated.characters['sofia']!.stage, 0);
    expect(migrated.characters['sofia']!.affection, 0);
    expect(migrated.characters['astra']!.stage, 0);
    expect(migrated.characters['astra']!.affection, 0);
    expect(migrated.characters['roxanne']!.giftDeliveries, isEmpty);
  });

  test(
    'catálogo possui somente os vinte presentes documentados e seus preços',
    () {
      expect(IdleBalance.gifts, hasLength(20));
      expect(IdleBalance.gift('love_letter').unitPrice, 10);
      expect(IdleBalance.gift('coffee').unitPrice, 25);
      expect(IdleBalance.gift('chocolate').unitPrice, 50);
      expect(IdleBalance.gift('wine').unitPrice, 12000);
      expect(IdleBalance.gift('wedding_ring').unitPrice, 200000000);
      expect(
        IdleBalance.gifts.every((gift) => gift.description.isNotEmpty),
        isTrue,
      );
      expect(IdleBalance.gift('love_letter').affection, 1);
      expect(IdleBalance.gift('coffee').affection, 3);
      expect(IdleBalance.gift('wedding_ring').affection, 20000000);
    },
  );
}
