import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
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
  test('Novo Jogo inicia apenas Roxanne desbloqueada', () {
    final characters = IdleState.fresh().characters;

    expect(characters[PlayableCharacterIds.roxanne]!.unlocked, isTrue);
    expect(characters[PlayableCharacterIds.kai]!.unlocked, isFalse);
    expect(characters[PlayableCharacterIds.sofia]!.unlocked, isFalse);
    expect(characters[PlayableCharacterIds.astra]!.unlocked, isFalse);
  });

  test('migração v8 concede marcos retroativos uma única vez', () async {
    final fresh = IdleState.fresh();
    final progressed = fresh.copyWith(
      characters: {
        ...fresh.characters,
        PlayableCharacterIds.roxanne: fresh
            .characters[PlayableCharacterIds.roxanne]!
            .copyWith(stage: 2),
      },
    );
    final source = jsonDecode(progressed.encode()) as Map<String, dynamic>;
    source['version'] = 8;
    source.remove('rewardedHighestStageByCharacter');
    source.remove('characterUnlockRewardClaimed');
    source.remove('trueLoveRewardClaimed');
    final storage = _MemoryStorage()..value = jsonEncode(source);

    final controller = GameController(storage);
    addTearDown(controller.dispose);
    await controller.initialize();

    expect(controller.state.totalBlocks, fresh.totalBlocks + 2);
    // Dois marcos (+2), desbloqueio de Kai (+2) e a conquista já existente
    // da rota Roxanne no estágio 3 (+3).
    expect(controller.state.diamonds, fresh.diamonds + 7);
    expect(
      controller.state.characters[PlayableCharacterIds.kai]!.unlocked,
      isTrue,
    );

    final reloaded = GameController(storage);
    addTearDown(reloaded.dispose);
    await reloaded.initialize();
    expect(reloaded.state.totalBlocks, controller.state.totalBlocks);
    expect(reloaded.state.diamonds, controller.state.diamonds);
  });

  test(
    'alteração direta do DEV não concede recompensa nem desbloqueio',
    () async {
      final controller = GameController(_MemoryStorage());
      addTearDown(controller.dispose);
      await controller.initialize();
      final blocks = controller.state.totalBlocks;
      final cherries = controller.state.diamonds;

      await controller.debugSetCharacterProgress(
        PlayableCharacterIds.roxanne,
        stage: 2,
      );

      expect(controller.state.totalBlocks, blocks);
      expect(controller.state.diamonds, cherries);
      expect(
        controller.state.characters[PlayableCharacterIds.kai]!.unlocked,
        isFalse,
      );
    },
  );
}
