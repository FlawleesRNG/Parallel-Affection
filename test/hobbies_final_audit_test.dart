import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/core/job_requirement_evaluator.dart';
import 'package:projeto_conexoes/core/player_skill_service.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/game_storage.dart';
import 'package:projeto_conexoes/services/time_reservation_service.dart';

class _MemoryIdleStorage implements GameStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

Map<String, ActivityProgress> _hobbiesWith({
  Map<String, ActivityProgress> overrides = const {},
}) => {
  for (final id in hobbyIds)
    id:
        overrides[id] ??
        ActivityProgress(isUnlocked: IdleBalance.hobby(id).initialAvailability),
};

void main() {
  test('auditoria final do catálogo oficial de Hobbies e Skills', () {
    expect(IdleBalance.hobbies.length, 10);
    expect(hobbyIds, [
      'leitura',
      'academia',
      'teatro',
      'meditacao',
      'videogames',
      'musica',
      'culinaria',
      'fotografia',
      'oratoria',
      'programacao',
    ]);
    expect(IdleBalance.hobbies.map((item) => item.displayName), [
      'Leitura',
      'Academia',
      'Teatro',
      'Meditação',
      'Videogames',
      'Música',
      'Culinária',
      'Fotografia',
      'Oratória',
      'Programação',
    ]);
    expect(
      IdleBalance.hobbies
          .where((item) => item.initialAvailability)
          .map((item) => item.id),
      ['leitura', 'academia', 'teatro', 'meditacao', 'videogames'],
    );
    expect(IdleBalance.hobby('musica').requires, {'hobby:leitura': 2});
    expect(IdleBalance.hobby('culinaria').requires, {'hobby:meditacao': 2});
    expect(IdleBalance.hobby('fotografia').requires, {'hobby:leitura': 3});
    expect(IdleBalance.hobby('oratoria').requires, {'hobby:teatro': 3});
    expect(IdleBalance.hobby('programacao').requires, {'hobby:leitura': 4});

    for (final hobby in IdleBalance.hobbies) {
      expect(hobby.maximumLevel, 10);
      expect(hobby.xpPerTrainingCycle, 2);
      expect(
        [
          for (var level = 1; level <= 9; level++)
            hobby.trainingDurationAtLevel(level).inSeconds,
        ],
        [10, 9, 8, 7, 6, 5, 4, 3, 2],
      );
      expect(
        [
          for (var level = 1; level <= 10; level++)
            hobby.timeCostAtLevel(level),
        ],
        [2, 2, 2, 2, 1, 1, 1, 1, 1, 0],
      );
    }
    expect(
      [
        for (var level = 1; level <= 9; level++)
          IdleBalance.hobbyXpNeeded(IdleBalance.hobby('leitura'), level),
      ],
      [10, 20, 35, 55, 80, 115, 160, 220, 300],
    );
    expect(PlayerSkillService.validateCatalog(), isEmpty);
    expect(
      PlayerSkillService.skillForHobby('leitura').displayName,
      'Inteligência',
    );
    expect(
      PlayerSkillService.skillForHobby('academia').displayName,
      'Condicionamento',
    );
    expect(PlayerSkillService.skillForHobby('teatro').displayName, 'Carisma');
    expect(
      PlayerSkillService.skillForHobby('meditacao').displayName,
      'Paciência',
    );
    expect(
      PlayerSkillService.skillForHobby('videogames').displayName,
      'Estratégia',
    );
    expect(
      PlayerSkillService.skillForHobby('musica').displayName,
      'Criatividade Musical',
    );
    expect(
      PlayerSkillService.skillForHobby('culinaria').displayName,
      'Talento Culinário',
    );
    expect(
      PlayerSkillService.skillForHobby('fotografia').displayName,
      'Percepção',
    );
    expect(
      PlayerSkillService.skillForHobby('oratoria').displayName,
      'Comunicação',
    );
    expect(
      PlayerSkillService.skillForHobby('programacao').displayName,
      'Tecnologia',
    );
  });

  test(
    'ROOT DEV controla Hobbies usando serviços reais e sem gerar dinheiro',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugStartHobby('leitura');
      expect(controller.state.hobbies['leitura']!.active, isTrue);

      await controller.debugCompleteHobbyCycle('leitura');
      expect(controller.state.hobbies['leitura']!.experience, 2);
      expect(controller.state.hobbies['leitura']!.cycles, 1);
      expect(controller.state.money, 0);
      expect(controller.hobbyFeedbacks['leitura'], isNotNull);

      await controller.debugAddHobbyXp('leitura', 8);
      expect(controller.state.hobbies['leitura']!.level, 2);
      expect(controller.state.hobbies['leitura']!.experience, 0);
      expect(
        PlayerSkillService.getSkillLevel(
          controller.state,
          PlayerSkillId.inteligencia,
        ),
        2,
      );
      expect(controller.state.hobbies['musica']!.isUnlocked, isTrue);

      await controller.debugSetHobbyCycleFraction('leitura', .75);
      expect(
        controller.state.hobbies['leitura']!.accumulatedCycleProgressMs,
        greaterThan(0),
      );
      await controller.debugZeroHobbyXp('leitura');
      expect(controller.state.hobbies['leitura']!.experience, 0);

      await controller.debugSetHobbyLevel('leitura', 10);
      final mastered = controller.state.hobbies['leitura']!;
      expect(mastered.level, 10);
      expect(mastered.active, isFalse);
      expect(mastered.experience, 0);
      expect(mastered.remainingBoostActiveTimeMs, 0);
      expect(
        PlayerSkillService.isSkillMastered(
          controller.state,
          PlayerSkillId.inteligencia,
        ),
        isTrue,
      );
      expect(
        (await controller.debugAddHobbyXp('leitura', 2)).message,
        contains('dominado'),
      );
    },
  );

  test(
    'ROOT Tempo e Cerejas infinitos funcionam para Hobbies e não persistem',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();

      for (final id in hobbyIds) {
        await controller.debugUnlockHobby(id);
      }
      await controller.debugSetResources(totalBlocks: 2, diamonds: 0);
      await controller.debugSetRootPrivileges(
        timeInfinite: true,
        cherriesInfinite: true,
      );
      await controller.debugStartAllHobbies();

      expect(controller.rootTimeInfinite, isTrue);
      expect(controller.rootCherriesInfinite, isTrue);
      expect(
        controller.state.hobbies.values.where((item) => item.active).length,
        10,
      );
      expect(
        TimeReservationService.snapshot(controller.state).reserved,
        greaterThan(controller.state.totalBlocks),
      );

      await controller.purchaseHobbyBoost('leitura');
      expect(controller.state.diamonds, 0);
      expect(
        controller.state.hobbies['leitura']!.remainingBoostActiveTimeMs,
        greaterThan(0),
      );

      await controller.debugSetRootPrivileges(
        timeInfinite: false,
        cherriesInfinite: false,
      );
      final reconciled = TimeReservationService.snapshot(controller.state);
      expect(reconciled.reserved, lessThanOrEqualTo(reconciled.capacity));
      controller.dispose();

      final reloaded = GameController(storage);
      await reloaded.initialize();
      addTearDown(reloaded.dispose);
      expect(reloaded.rootTimeInfinite, isFalse);
      expect(reloaded.rootCherriesInfinite, isFalse);
    },
  );

  test(
    'ROOT reset e bloqueio de Hobbies preservam Jobs personagens e recursos',
    () async {
      final storage = _MemoryIdleStorage();
      final initial = IdleState.fresh().copyWith(
        money: 3210,
        diamonds: 12,
        jobs: {
          for (final id in jobIds)
            id: ActivityProgress(
              isUnlocked: id == 'neighborhood_deliveries',
              level: id == 'neighborhood_deliveries' ? 4 : 1,
            ),
        },
        hobbies: _hobbiesWith(
          overrides: {
            'musica': const ActivityProgress(
              isUnlocked: true,
              active: true,
              level: 6,
              experience: 7,
              cycles: 9,
              remainingBoostActiveTimeMs: 5000,
            ),
          },
        ),
        characters: {
          ...IdleState.fresh().characters,
          PlayableCharacterIds.roxanne: const CharacterProgress(
            unlocked: true,
            stage: 4,
            affection: 44,
          ),
          PlayableCharacterIds.kai: const CharacterProgress(
            unlocked: true,
            stage: 2,
            affection: 22,
          ),
        },
      );
      storage.value = initial.encode();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);
      final diamondsBeforeReset = controller.state.diamonds;

      final lockResult = await controller.debugLockHobby('musica');
      expect(lockResult.message, contains('bloqueado'));
      expect(controller.state.hobbies['musica']!.isUnlocked, isFalse);
      expect(controller.state.hobbies['musica']!.level, 6);
      expect(controller.state.hobbies['musica']!.active, isFalse);

      final initialLock = await controller.debugLockHobby('leitura');
      expect(initialLock.message, contains('desde o início'));
      expect(controller.state.hobbies['leitura']!.isUnlocked, isTrue);

      await controller.debugResetAllHobbies();
      expect(controller.state.money, 3210);
      expect(controller.state.diamonds, diamondsBeforeReset);
      expect(controller.state.jobs['neighborhood_deliveries']!.level, 4);
      expect(
        controller.state.characters[PlayableCharacterIds.roxanne]!.stage,
        4,
      );
      expect(controller.state.characters[PlayableCharacterIds.kai]!.stage, 2);
      expect(
        controller.state.hobbies.entries
            .where((entry) => IdleBalance.hobby(entry.key).initialAvailability)
            .every((entry) => entry.value.isUnlocked && entry.value.level == 1),
        isTrue,
      );
      expect(
        controller.state.hobbies.entries
            .where((entry) => !IdleBalance.hobby(entry.key).initialAvailability)
            .every((entry) => !entry.value.isUnlocked && !entry.value.active),
        isTrue,
      );
    },
  );

  test(
    'níveis reais de Hobbies continuam satisfazendo requisitos de Jobs',
    () async {
      final state = IdleState.fresh().copyWith(
        money: 50000,
        totalMoneyEarned: 50000,
        jobs: {
          for (final id in jobIds)
            id: ActivityProgress(
              isUnlocked: true,
              level: switch (id) {
                'neighborhood_deliveries' => 2,
                'local_flyering' => 3,
                'cafe_assistant' => 4,
                'radio_assistant' => 5,
                _ => 1,
              },
            ),
        },
        hobbies: _hobbiesWith(
          overrides: {
            'videogames': const ActivityProgress(isUnlocked: true, level: 2),
            'academia': const ActivityProgress(isUnlocked: true, level: 3),
            'fotografia': const ActivityProgress(isUnlocked: true, level: 4),
            'oratoria': const ActivityProgress(isUnlocked: true, level: 6),
            'musica': const ActivityProgress(isUnlocked: true, level: 4),
            'programacao': const ActivityProgress(isUnlocked: true, level: 6),
            'teatro': const ActivityProgress(isUnlocked: true, level: 7),
          },
        ),
        characters: {
          ...IdleState.fresh().characters,
          PlayableCharacterIds.roxanne: const CharacterProgress(
            unlocked: true,
            stage: 4,
          ),
          PlayableCharacterIds.legacyRyomi: const CharacterProgress(
            unlocked: true,
            stage: 4,
          ),
        },
      );

      for (final id in [
        'game_store',
        'gym_reception',
        'freelance_photography',
        'radio_assistant',
        'freelance_programmer',
        'event_producer',
      ]) {
        expect(
          JobRequirementEvaluator.evaluate(
            state,
            IdleBalance.job(id),
          ).requirementsMet,
          isTrue,
        );
      }
    },
  );
}
