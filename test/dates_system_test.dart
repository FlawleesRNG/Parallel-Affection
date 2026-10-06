import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/core/idle_rules.dart';
import 'package:projeto_conexoes/data/character_routes.dart';
import 'package:projeto_conexoes/data/date_locations.dart';
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
  const characterIds = [
    PlayableCharacterIds.roxanne,
    PlayableCharacterIds.kai,
    PlayableCharacterIds.sofia,
    PlayableCharacterIds.astra,
  ];

  test('catálogo oficial possui os sete locais, custos e durações', () {
    expect(DateLocationCatalog.locations.map((item) => item.id), [
      'cafe',
      'park',
      'cinema',
      'arcade',
      'restaurant',
      'amusement_park',
      'night_viewpoint',
    ]);
    expect(DateLocationCatalog.byId('cafe').baseCost, 250);
    expect(
      DateLocationCatalog.byId('night_viewpoint').baseDuration.inSeconds,
      45,
    );
  });

  test(
    'encontro cobra uma única vez, não consome Tempo e separa contador',
    () async {
      final controller = GameController(_MemoryStorage());
      addTearDown(controller.dispose);
      await controller.newGame();
      await controller.debugMoney(1000);
      final beforeBlocks = controller.state.availableBlocks;
      await controller.startDate('roxanne', 'cafe');
      expect(controller.state.money, 750);
      expect(controller.state.availableBlocks, beforeBlocks);
      expect(controller.state.activeEncounter!.characterId, 'roxanne');
      expect(controller.dateCount('roxanne', 'cafe'), 0);
      await controller.startDate('kai', 'cafe');
      expect(controller.state.money, 750);
      expect(controller.state.activeEncounter!.characterId, 'roxanne');
    },
  );

  test('saldo insuficiente não cria encontro nem altera dinheiro', () async {
    final controller = GameController(_MemoryStorage());
    addTearDown(controller.dispose);
    await controller.newGame();
    await controller.debugMoney(100);
    final result = await controller.startDate('roxanne', 'cafe');
    expect(result.message, 'Dinheiro insuficiente.');
    expect(controller.state.money, 100);
    expect(controller.state.activeEncounter, isNull);
  });

  test('encontro vencido ao carregar conclui exatamente uma vez', () async {
    final storage = _MemoryStorage();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    storage.value = IdleState.fresh()
        .copyWith(
          activeEncounter: ActiveEncounter(
            characterId: 'kai',
            encounterId: 'cafe',
            startedAt: now - 10000,
            endsAt: now - 1,
            costPaid: 250,
          ),
        )
        .encode();
    final controller = GameController(storage);
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.dateCount('kai', 'cafe'), 1);
    expect(controller.state.activeEncounter, isNull);
    final reloaded = GameController(storage);
    addTearDown(reloaded.dispose);
    await reloaded.initialize();
    expect(reloaded.dateCount('kai', 'cafe'), 1);
  });

  test(
    'o mesmo fluxo inicia e conclui um encontro para cada personagem isoladamente',
    () async {
      final controller = GameController(_MemoryStorage());
      addTearDown(controller.dispose);
      await controller.newGame();
      await controller.debugMoney(2000);

      for (final characterId in characterIds) {
        await controller.debugSetCharacterUnlocked(characterId, true);
        final beforeMoney = controller.state.money;
        final result = await controller.startDate(characterId, 'cafe');

        expect(result.message, contains('iniciado'));
        expect(controller.state.activeEncounter!.characterId, characterId);
        expect(controller.state.activeEncounter!.locationId, 'cafe');
        expect(controller.state.money, beforeMoney - 250);

        await controller.debugCompleteActiveDate();
        expect(controller.state.activeEncounter, isNull);
        for (final expectedId in characterIds) {
          expect(
            controller.dateCount(expectedId, 'cafe'),
            characterIds.indexOf(expectedId) <=
                    characterIds.indexOf(characterId)
                ? 1
                : 0,
          );
        }
      }
    },
  );

  test(
    'trocar a personagem selecionada não transfere encontro ativo',
    () async {
      final controller = GameController(_MemoryStorage());
      addTearDown(controller.dispose);
      await controller.newGame();
      await controller.debugMoney(1000);
      await controller.debugSetCharacterUnlocked(
        PlayableCharacterIds.kai,
        true,
      );

      await controller.startDate(PlayableCharacterIds.kai, 'cafe');
      expect(
        controller.state.activeEncounter!.characterId,
        PlayableCharacterIds.kai,
      );

      // The caller can now select Sofia in the UI; completion remains owned by
      // the character captured in activeEncounter rather than selection state.
      await controller.debugCompleteActiveDate();

      expect(controller.dateCount(PlayableCharacterIds.kai, 'cafe'), 1);
      expect(controller.dateCount(PlayableCharacterIds.sofia, 'cafe'), 0);
      expect(controller.dateCount(PlayableCharacterIds.roxanne, 'cafe'), 0);
      expect(controller.dateCount(PlayableCharacterIds.astra, 'cafe'), 0);
    },
  );

  test(
    'recuperação offline aplica encontro vencido à personagem dona',
    () async {
      final storage = _MemoryStorage();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      storage.value = IdleState.fresh()
          .copyWith(
            activeEncounter: ActiveEncounter(
              characterId: PlayableCharacterIds.astra,
              encounterId: 'cinema',
              startedAt: now - 20000,
              endsAt: now - 1,
              costPaid: 5000,
            ),
          )
          .encode();
      final controller = GameController(storage);
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.dateCount(PlayableCharacterIds.astra, 'cinema'), 1);
      expect(controller.dateCount(PlayableCharacterIds.roxanne, 'cinema'), 0);
      expect(controller.dateCount(PlayableCharacterIds.kai, 'cinema'), 0);
      expect(controller.dateCount(PlayableCharacterIds.sofia, 'cinema'), 0);
      expect(controller.state.activeEncounter, isNull);
    },
  );

  test('requisitos de encontro usam a rota individual de cada personagem', () {
    expect(
      CharacterDateRequirements.forStage(
        PlayableCharacterIds.roxanne,
        4,
      ).single.locationId,
      'cinema',
    );
    expect(
      CharacterDateRequirements.forStage(
        PlayableCharacterIds.kai,
        4,
      ).single.locationId,
      'arcade',
    );
    expect(
      CharacterDateRequirements.forStage(
        PlayableCharacterIds.sofia,
        4,
      ).single.locationId,
      'restaurant',
    );
    expect(
      CharacterDateRequirements.forStage(
        PlayableCharacterIds.astra,
        4,
      ).single.locationId,
      'cinema',
    );
    expect(
      CharacterDateRequirements.forStage(PlayableCharacterIds.legacyRyomi, 4),
      CharacterDateRequirements.forStage(PlayableCharacterIds.roxanne, 4),
    );
  });

  test(
    'requisito de encontro é cumulativo e bloqueia evolução quando ausente',
    () {
      final fresh = IdleState.fresh();
      final roxanne = fresh.characters['roxanne']!.copyWith(
        stage: 2,
        affection: 200,
        giftDeliveries: const {'chocolate': 20},
      );
      final base = fresh.copyWith(
        characters: {...fresh.characters, 'roxanne': roxanne},
        hobbies: {
          ...fresh.hobbies,
          'leitura': fresh.hobbies['leitura']!.copyWith(level: 2),
        },
        jobs: {
          ...fresh.jobs,
          'radio_assistant': fresh.jobs['radio_assistant']!.copyWith(level: 2),
        },
      );
      expect(IdleRules.canAdvance(base, 'roxanne'), isFalse);
      final complete = base.copyWith(
        dateProgressByCharacter: const {
          'roxanne': {'cafe': 3},
        },
      );
      expect(IdleRules.canAdvance(complete, 'roxanne'), isTrue);
      expect(
        CharacterDateRequirements.forStage('roxanne', 3).single.requiredCount,
        3,
      );
    },
  );
}
