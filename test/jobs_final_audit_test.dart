import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/game_storage.dart';
import 'package:projeto_conexoes/services/simulation_service.dart';
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

Map<String, ActivityProgress> _allJobs({
  int level = 1,
  bool active = false,
  bool unlocked = true,
  int timestamp = 0,
  int boostMs = 0,
}) => {
  for (final id in jobIds)
    id: ActivityProgress(
      level: level,
      active: active,
      isUnlocked: unlocked || id == 'neighborhood_deliveries',
      cycleStartedAt: timestamp,
      lastProcessedAtUtc: timestamp,
      firstStartedAtUtc: timestamp,
      hasBeenStarted: active,
      remainingBoostActiveTimeMs: boostMs,
      boostReferenceTimestampUtc: boostMs > 0 ? timestamp : 0,
    ),
};

void main() {
  test('auditoria final do catalogo oficial de nove empregos', () {
    const expectedIds = [
      'neighborhood_deliveries',
      'local_flyering',
      'cafe_assistant',
      'game_store',
      'gym_reception',
      'freelance_photography',
      'radio_assistant',
      'freelance_programmer',
      'event_producer',
    ];
    const expectedNames = [
      'Entregas de Bairro',
      'Panfletagem Local',
      'Auxiliar de Cafeteria',
      'Loja de Games',
      'Recepção da Academia',
      'Fotografia Freelancer',
      'Assistente de Rádio',
      'Programador Freelancer',
      'Produtor de Eventos',
    ];
    const xpPerCycle = {
      'neighborhood_deliveries': 2,
      'local_flyering': 2,
      'cafe_assistant': 3,
      'game_store': 3,
      'gym_reception': 3,
      'freelance_photography': 3,
      'radio_assistant': 4,
      'freelance_programmer': 4,
      'event_producer': 5,
    };
    const difficulties = {
      'neighborhood_deliveries': JobDifficulty.basic,
      'local_flyering': JobDifficulty.basic,
      'cafe_assistant': JobDifficulty.intermediate,
      'game_store': JobDifficulty.intermediate,
      'gym_reception': JobDifficulty.intermediate,
      'freelance_photography': JobDifficulty.intermediate,
      'radio_assistant': JobDifficulty.advanced,
      'freelance_programmer': JobDifficulty.advanced,
      'event_producer': JobDifficulty.special,
    };

    expect(IdleBalance.jobs.map((job) => job.id).toList(), expectedIds);
    expect(
      IdleBalance.jobs.map((job) => job.displayName).toList(),
      expectedNames,
    );
    expect(IdleBalance.maximumJobLevel, 10);
    expect(IdleBalance.defaultJobOfflineLimit, const Duration(hours: 8));
    expect(IdleBalance.jobBoostCherryCost, 5);
    expect(IdleBalance.jobBoostActiveDuration, const Duration(minutes: 10));
    expect(IdleBalance.jobBoostSpeedMultiplier, 2);
    expect(
      IdleBalance.maximumLevelContinuousIncomeInterval,
      const Duration(seconds: 1),
    );
    expect(IdleBalance.validateJobCatalog(), isEmpty);

    for (final job in IdleBalance.jobs) {
      expect(job.displayOrder, expectedIds.indexOf(job.id) + 1);
      expect(job.maximumLevel, 10, reason: job.id);
      expect(job.rankNames, hasLength(10), reason: job.id);
      expect(job.cycleDurationsByLevel, hasLength(10), reason: job.id);
      expect(job.timeCostsByLevel, hasLength(10), reason: job.id);
      expect(job.timeCostAtLevel(10), 0, reason: job.id);
      expect(job.cycleDurationAtLevel(10), const Duration(seconds: 1));
      expect(job.xpPerCycle, xpPerCycle[job.id], reason: job.id);
      expect(job.difficulty, difficulties[job.id], reason: job.id);
      expect(IdleBalance.nextJobRoleTitle(job.id, 10), isNull);
      expect(IdleBalance.jobXpNeeded(job, 10), 0);
    }
  });

  test('formulas oficiais de recompensa e XP sao unicas no catalogo', () {
    const baseXp = [12, 24, 40, 65, 95, 135, 185, 250, 330];
    const difficultyMultiplier = {
      JobDifficulty.basic: 1.0,
      JobDifficulty.intermediate: 1.35,
      JobDifficulty.advanced: 1.80,
      JobDifficulty.special: 2.40,
    };

    for (final job in IdleBalance.jobs) {
      for (final level in [1, 5, 9, 10]) {
        final expectedReward = (job.baseReward * (1 + ((level - 1) * .25)))
            .round();
        expect(job.rewardAtLevel(level), expectedReward, reason: job.id);
      }
      for (var level = 1; level < job.maximumLevel; level++) {
        final expectedXp =
            (baseXp[level - 1] * difficultyMultiplier[job.difficulty]!).ceil();
        expect(IdleBalance.jobXpNeeded(job, level), expectedXp, reason: job.id);
      }
    }
  });

  test(
    'requisitos oficiais e desbloqueio permanente ficam coerentes',
    () async {
      expect(IdleBalance.job('neighborhood_deliveries').requires, isEmpty);
      expect(IdleBalance.job('local_flyering').requires, {
        'job:neighborhood_deliveries': 2,
      });
      expect(IdleBalance.job('cafe_assistant').requires, {
        'job:local_flyering': 3,
        'money:money': 250,
      });
      expect(IdleBalance.job('game_store').requires, {
        'hobby:videogames': 2,
        'stage:roxanne': 2,
        'job:cafe_assistant': 2,
      });
      expect(IdleBalance.job('gym_reception').requires, {
        'hobby:academia': 3,
        'job:cafe_assistant': 4,
      });
      expect(IdleBalance.job('freelance_photography').requires, {
        'hobby:fotografia': 4,
        'stage:roxanne': 3,
      });
      expect(IdleBalance.job('radio_assistant').requires, {
        'hobby:oratoria': 5,
        'hobby:musica': 4,
        'stage:roxanne': 4,
      });
      expect(IdleBalance.job('freelance_programmer').requires, {
        'hobby:programacao': 6,
        'money:money': 10000,
      });
      expect(IdleBalance.job('event_producer').requires, {
        'hobby:teatro': 7,
        'hobby:oratoria': 6,
        'job:radio_assistant': 5,
        'money:money': 50000,
      });

      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetJobLevel('local_flyering', 3);
      await controller.debugSetResources(money: 250);
      expect(controller.state.jobs['cafe_assistant']!.isUnlocked, isTrue);

      await controller.debugSetResources(money: 0);
      expect(controller.state.money, 0);
      expect(controller.state.jobs['cafe_assistant']!.isUnlocked, isTrue);
    },
  );

  test(
    'dinheiro e XP entram somente em ciclo completo com resto preservado',
    () {
      final service = SimulationService();
      final start = DateTime.utc(2026, 8, 12, 12);
      final job = IdleBalance.job('neighborhood_deliveries');
      final state = IdleState.fresh().copyWith(
        lastSavedAt: start.millisecondsSinceEpoch,
        jobs: {
          ...IdleState.fresh().jobs,
          job.id: ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            firstStartedAtUtc: start.millisecondsSinceEpoch,
            hasBeenStarted: true,
          ),
        },
      );

      final beforeCycle = service.advance(
        state,
        start.add(const Duration(milliseconds: 11900)),
      );
      expect(beforeCycle.summary.money, 0);
      expect(beforeCycle.summary.jobExperience, 0);
      expect(beforeCycle.state.jobs[job.id]!.accumulatedCycleProgressMs, 11900);

      final exactCycle = service.advance(
        state,
        start.add(const Duration(seconds: 12)),
      );
      expect(exactCycle.summary.money, job.rewardAtLevel(1));
      expect(exactCycle.summary.jobExperience, job.xpPerCycle);
      expect(exactCycle.state.jobs[job.id]!.cycles, 1);
      expect(exactCycle.state.jobs[job.id]!.accumulatedCycleProgressMs, 0);
    },
  );

  test('producao continua nivel 10 usa 1s e agrega todos os nove empregos', () {
    final service = SimulationService();
    final start = DateTime.utc(2026, 8, 12, 12);

    for (final job in IdleBalance.jobs) {
      final state = IdleState.fresh().copyWith(
        lastSavedAt: start.millisecondsSinceEpoch,
        jobs: _allJobs(
          level: 10,
          active: true,
          timestamp: start.millisecondsSinceEpoch,
        ),
      );

      final pointNine = service.advance(
        state,
        start.add(const Duration(milliseconds: 900)),
      );
      expect(pointNine.state.jobs[job.id]!.cycles, 0, reason: job.id);
      expect(pointNine.summary.jobExperience, 0, reason: job.id);

      final tenPointFive = service.advance(
        state,
        start.add(const Duration(milliseconds: 10500)),
      );
      final progress = tenPointFive.state.jobs[job.id]!;
      expect(progress.level, 10, reason: job.id);
      expect(progress.experience, 0, reason: job.id);
      expect(progress.cycles, 10, reason: job.id);
      expect(progress.continuousPayments, 10, reason: job.id);
      expect(progress.accumulatedCycleProgressMs, 500, reason: job.id);
    }
  });

  test(
    'boost x2 no dominio maximo acelera intervalo sem dobrar reward unitario',
    () {
      final service = SimulationService();
      final start = DateTime.utc(2026, 8, 12, 12);

      for (final id in ['neighborhood_deliveries', 'event_producer']) {
        final job = IdleBalance.job(id);
        final state = IdleState.fresh().copyWith(
          lastSavedAt: start.millisecondsSinceEpoch,
          jobs: _allJobs(
            level: 10,
            active: true,
            timestamp: start.millisecondsSinceEpoch,
            boostMs: IdleBalance.jobBoostActiveDuration.inMilliseconds,
          ),
        );

        final result = service.advance(
          state,
          start.add(const Duration(seconds: 1)),
        );
        final progress = result.state.jobs[id]!;
        expect(progress.continuousPayments, 2, reason: id);
        expect(progress.lifetimeMoneyEarned, job.rewardAtLevel(10) * 2);
        expect(progress.remainingBoostActiveTimeMs, lessThan(600000));
      }
    },
  );

  test(
    'offline 8h com nove empregos no nivel 10 processa agregado e rapido',
    () {
      final service = SimulationService();
      final start = DateTime.utc(2026, 8, 12, 12);
      final state = IdleState.fresh().copyWith(
        lastSavedAt: start.millisecondsSinceEpoch,
        jobs: _allJobs(
          level: 10,
          active: true,
          timestamp: start.millisecondsSinceEpoch,
        ),
      );

      final stopwatch = Stopwatch()..start();
      final result = service.advance(
        state,
        start.add(const Duration(hours: 9)),
        offline: true,
      );
      stopwatch.stop();

      expect(result.summary.elapsed, const Duration(hours: 8));
      expect(result.summary.discardedByLimit, const Duration(hours: 1));
      expect(result.summary.totalContinuousPayments, 28800 * 9);
      expect(
        result.state.jobs.values.every(
          (progress) =>
              progress.level == 10 &&
              progress.experience == 0 &&
              progress.continuousPayments == 28800,
        ),
        isTrue,
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    },
  );

  test(
    'ROOT DEV nao aceita XP negativo nem persiste privilegios temporarios',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();

      final before =
          controller.state.jobs['neighborhood_deliveries']!.experience;
      final xpResult = await controller.debugAddJobXp(
        'neighborhood_deliveries',
        -5,
      );
      expect(xpResult.message, contains('positivo'));
      expect(
        controller.state.jobs['neighborhood_deliveries']!.experience,
        before,
      );

      await controller.debugSetRootPrivileges(
        timeInfinite: true,
        cherriesInfinite: true,
      );
      await controller.debugForceSave();
      controller.dispose();

      final reloaded = GameController(storage);
      await reloaded.initialize();
      addTearDown(reloaded.dispose);

      expect(reloaded.rootTimeInfinite, isFalse);
      expect(reloaded.rootCherriesInfinite, isFalse);
    },
  );

  test(
    'downgrade DEV de nivel 10 ativo reconcilia custo de Tempo normal',
    () async {
      final now = DateTime.utc(2026, 8, 12, 12).millisecondsSinceEpoch;
      final storage = _MemoryIdleStorage()
        ..value = IdleState.fresh()
            .copyWith(
              totalBlocks: 1,
              jobs: {
                ...IdleState.fresh().jobs,
                'neighborhood_deliveries': ActivityProgress(
                  active: true,
                  isUnlocked: true,
                  level: 10,
                  cycleStartedAt: now,
                  lastProcessedAtUtc: now,
                  firstStartedAtUtc: now,
                  hasBeenStarted: true,
                ),
              },
            )
            .encode();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      expect(TimeReservationService.snapshot(controller.state).reserved, 0);
      await controller.debugSetJobLevel('neighborhood_deliveries', 1);

      expect(controller.state.jobs['neighborhood_deliveries']!.active, isFalse);
      expect(TimeReservationService.snapshot(controller.state).available, 1);
    },
  );

  test('reset global de empregos preserva Kai e Roxanne', () async {
    final storage = _MemoryIdleStorage()
      ..value = IdleState.fresh()
          .copyWith(
            characters: {
              ...IdleState.fresh().characters,
              PlayableCharacterIds.roxanne: const CharacterProgress(
                unlocked: true,
                stage: 4,
                affection: 77,
              ),
              PlayableCharacterIds.kai: const CharacterProgress(
                unlocked: true,
                stage: 1,
                affection: 22,
              ),
            },
            jobs: _allJobs(level: 7, active: true),
          )
          .encode();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugResetAllJobs();

    expect(controller.state.characters[PlayableCharacterIds.roxanne]!.stage, 4);
    expect(
      controller.state.characters[PlayableCharacterIds.roxanne]!.affection,
      77,
    );
    expect(controller.state.characters[PlayableCharacterIds.kai]!.stage, 1);
    expect(
      controller.state.characters[PlayableCharacterIds.kai]!.affection,
      22,
    );
  });
}
