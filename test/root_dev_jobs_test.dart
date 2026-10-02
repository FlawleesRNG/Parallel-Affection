import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
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

Map<String, ActivityProgress> _jobsWith({
  Map<String, ActivityProgress> overrides = const {},
  bool unlocked = false,
}) => {
  for (final id in jobIds)
    id: (overrides[id] ?? const ActivityProgress()).copyWith(
      isUnlocked:
          (overrides[id]?.isUnlocked ?? false) ||
          unlocked ||
          id == 'neighborhood_deliveries',
    ),
};

void main() {
  test(
    'ROOT Tempo infinito permite exceder capacidade e ao desligar reconcilia preservando antigos',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetResources(totalBlocks: 2);
      for (final id in jobIds) {
        await controller.debugUnlockJob(id);
      }
      await controller.debugSetRootPrivileges(timeInfinite: true);
      for (final id in jobIds) {
        await controller.debugStartJob(id);
      }

      expect(controller.rootTimeInfinite, isTrue);
      expect(controller.state.jobs.values.where((job) => job.active).length, 9);
      expect(
        TimeReservationService.snapshot(controller.state).reserved,
        greaterThan(controller.state.totalBlocks),
      );

      await controller.debugSetRootPrivileges(timeInfinite: false);

      final reconciled = TimeReservationService.snapshot(controller.state);
      expect(controller.rootTimeInfinite, isFalse);
      expect(reconciled.reserved, lessThanOrEqualTo(reconciled.capacity));
      expect(controller.state.jobs['neighborhood_deliveries']!.active, isTrue);
      expect(
        controller.state.jobs.values.where((job) => job.active).length,
        lessThan(9),
      );
    },
  );

  test(
    'ROOT Cerejas infinitas compra impulso real sem gastar e nao persiste flag',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();

      await controller.debugSetResources(diamonds: 0);
      await controller.debugStartJob('neighborhood_deliveries');
      await controller.debugSetRootPrivileges(cherriesInfinite: true);
      await controller.purchaseJobBoost('neighborhood_deliveries');

      expect(controller.rootCherriesInfinite, isTrue);
      expect(controller.state.diamonds, 0);
      expect(
        controller
            .state
            .jobs['neighborhood_deliveries']!
            .remainingBoostActiveTimeMs,
        greaterThan(0),
      );
      controller.dispose();

      final reloaded = GameController(storage);
      await reloaded.initialize();
      addTearDown(reloaded.dispose);

      expect(reloaded.rootCherriesInfinite, isFalse);
      expect(
        reloaded
            .state
            .jobs['neighborhood_deliveries']!
            .remainingBoostActiveTimeMs,
        greaterThan(0),
      );
    },
  );

  test('ROOT controla nivel, XP, ciclo, impulso e simulacao reais', () async {
    final storage = _MemoryIdleStorage();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetJobLevel('neighborhood_deliveries', 5);
    expect(controller.state.jobs['neighborhood_deliveries']!.level, 5);
    expect(controller.state.jobs['neighborhood_deliveries']!.experience, 0);

    await controller.debugAddJobXp('neighborhood_deliveries', 3);
    expect(controller.state.jobs['neighborhood_deliveries']!.experience, 3);

    await controller.debugSetJobCycleFraction('neighborhood_deliveries', .5);
    expect(
      controller
          .state
          .jobs['neighborhood_deliveries']!
          .accumulatedCycleProgressMs,
      greaterThan(0),
    );

    await controller.debugStartJob('neighborhood_deliveries');
    await controller.debugCompleteJobCycle('neighborhood_deliveries');
    expect(controller.state.money, greaterThan(0));
    expect(controller.jobFeedbacks['neighborhood_deliveries'], isNotNull);

    await controller.debugActivateJobBoost('neighborhood_deliveries');
    expect(
      controller
          .state
          .jobs['neighborhood_deliveries']!
          .remainingBoostActiveTimeMs,
      greaterThan(0),
    );
    await controller.debugExpireJobBoost('neighborhood_deliveries');
    expect(
      controller
          .state
          .jobs['neighborhood_deliveries']!
          .remainingBoostActiveTimeMs,
      0,
    );
  });

  test(
    'ROOT reset global de empregos preserva recursos personagem e hobbies',
    () async {
      final storage = _MemoryIdleStorage();
      final initial = IdleState.fresh().copyWith(
        money: 1234,
        diamonds: 56,
        jobs: _jobsWith(
          overrides: {
            'neighborhood_deliveries': const ActivityProgress(
              active: true,
              isUnlocked: true,
              level: 6,
              experience: 7,
            ),
          },
        ),
        hobbies: {
          for (final id in hobbyIds)
            id: ActivityProgress(level: id == 'musica' ? 4 : 1),
        },
        characters: {
          ...IdleState.fresh().characters,
          PlayableCharacterIds.roxanne: const CharacterProgress(
            unlocked: true,
            stage: 3,
            affection: 42,
          ),
        },
      );
      storage.value = initial.encode();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);
      final diamondsBefore = controller.state.diamonds;

      await controller.debugResetAllJobs();

      expect(controller.state.money, 1234);
      expect(controller.state.diamonds, diamondsBefore);
      expect(
        controller.state.characters[PlayableCharacterIds.roxanne]!.stage,
        3,
      );
      expect(controller.state.hobbies['musica']!.level, 4);
      expect(
        controller.state.jobs['neighborhood_deliveries']!.isUnlocked,
        isTrue,
      );
      expect(controller.state.jobs['neighborhood_deliveries']!.level, 1);
      expect(
        controller.state.jobs.entries
            .where((entry) => entry.key != 'neighborhood_deliveries')
            .every(
              (entry) => !entry.value.isUnlocked && entry.value.level == 1,
            ),
        isTrue,
      );
    },
  );

  test(
    'ROOT reavalia requisitos reais e producao continua permanece em 1s no maximo',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetJobLevel('neighborhood_deliveries', 2);
      await controller.debugReevaluateJobUnlocks();
      expect(controller.state.jobs['local_flyering']!.isUnlocked, isTrue);

      await controller.debugSetJobLevel('neighborhood_deliveries', 10);
      final job = IdleBalance.job('neighborhood_deliveries');
      expect(job.cycleDurationAtLevel(10), const Duration(seconds: 1));
      expect(controller.state.jobs['neighborhood_deliveries']!.experience, 0);

      final result = await controller.debugAddJobXp(
        'neighborhood_deliveries',
        999,
      );
      expect(result.message, contains('Máximo'));
      expect(controller.state.jobs['neighborhood_deliveries']!.experience, 0);
    },
  );

  test(
    'ROOT flags de empregos sao apenas de sessao e nao entram no save',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();

      await controller.debugSetRootPrivileges(
        timeInfinite: true,
        cherriesInfinite: true,
      );
      await controller.debugForceSave();
      expect(controller.rootTimeInfinite, isTrue);
      expect(controller.rootCherriesInfinite, isTrue);
      controller.dispose();

      final reloaded = GameController(storage);
      await reloaded.initialize();
      addTearDown(reloaded.dispose);

      expect(reloaded.rootTimeInfinite, isFalse);
      expect(reloaded.rootCherriesInfinite, isFalse);
    },
  );
}
