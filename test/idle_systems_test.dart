import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/core/idle_rules.dart';
import 'package:projeto_conexoes/core/job_requirement_evaluator.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/game_storage.dart';
import 'package:projeto_conexoes/services/simulation_service.dart';
import 'package:projeto_conexoes/services/time_reservation_service.dart';

class MemoryIdleStorage implements GameStorage {
  String? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

class RecoverableMemoryIdleStorage implements RecoverableGameStorage {
  String? value;
  String? backup;
  @override
  Future<void> clear() async {
    value = null;
    backup = null;
  }

  @override
  Future<String?> read() async => value;

  @override
  Future<String?> readBackup() async => backup;

  @override
  Future<void> write(String value) async {
    if (this.value != null) backup = this.value;
    this.value = value;
  }

  @override
  Future<void> writeBackup(String value) async => backup = value;
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

Map<String, ActivityProgress> _hobbiesWith({
  Map<String, ActivityProgress> overrides = const {},
}) => {
  for (final id in hobbyIds) id: overrides[id] ?? const ActivityProgress(),
};

void main() {
  test('catálogo oficial de personagens usa o roster da Etapa 15', () {
    expect(PlayableCharacterCatalog.all.map((item) => item.id), [
      PlayableCharacterIds.roxanne,
      PlayableCharacterIds.kai,
      PlayableCharacterIds.sofia,
      PlayableCharacterIds.astra,
    ]);
    expect(PlayableCharacterCatalog.roxanne.visibleName, 'Roxanne');
    expect(PlayableCharacterCatalog.roxanne.routeReady, isTrue);
    expect(PlayableCharacterCatalog.kai.visibleName, 'Kai');
    expect(PlayableCharacterCatalog.kai.routeReady, isTrue);
    expect(PlayableCharacterCatalog.sofia.routeReady, isTrue);
    expect(PlayableCharacterCatalog.astra.routeReady, isFalse);
    expect(
      PlayableCharacterCatalog.canonicalId(PlayableCharacterIds.legacyRyomi),
      PlayableCharacterIds.roxanne,
    );
  });

  test('catálogo oficial de hobbies possui dez IDs permanentes em ordem', () {
    expect(IdleBalance.hobbies.map((item) => item.id).toList(), [
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
    expect(
      IdleBalance.hobbies.map((item) => item.displayOrder).toList(),
      List<int>.generate(10, (index) => index + 1),
    );
    expect(IdleBalance.hobby('academia').attribute, 'Condicionamento');
    expect(IdleBalance.hobby('musica').attribute, 'Criatividade Musical');
    expect(IdleBalance.hobby('culinaria').attribute, 'Talento Culinário');
  });

  test('requisitos oficiais dos hobbies usam IDs definitivos', () {
    expect(IdleBalance.hobby('leitura').requires, isEmpty);
    expect(IdleBalance.hobby('videogames').requires, isEmpty);
    expect(IdleBalance.hobby('musica').requires, {'hobby:leitura': 2});
    expect(IdleBalance.hobby('culinaria').requires, {'hobby:meditacao': 2});
    expect(IdleBalance.hobby('fotografia').requires, {'hobby:leitura': 3});
    expect(IdleBalance.hobby('oratoria').requires, {'hobby:teatro': 3});
    expect(IdleBalance.hobby('programacao').requires, {'hobby:leitura': 4});
  });

  test('migração defensiva cria hobbies oficiais e preserva aliases', () {
    final old = jsonEncode({
      'version': 4,
      'hobbies': {
        'games': {'level': 4, 'experience': 7, 'cycles': 9},
        'programming': {'level': 3, 'experience': 2, 'cycles': 5},
      },
    });

    final migrated = IdleState.decode(old);

    expect(migrated.hobbies.keys.toList(), hobbyIds);
    expect(migrated.hobbies['videogames']!.level, 4);
    expect(migrated.hobbies['programacao']!.level, 3);
    expect(migrated.hobbies.containsKey('games'), isFalse);
    expect(migrated.hobbies.containsKey('programming'), isFalse);
  });

  test('catálogo oficial de empregos possui nove IDs permanentes em ordem', () {
    expect(IdleBalance.jobs.map((item) => item.id).toList(), [
      'neighborhood_deliveries',
      'local_flyering',
      'cafe_assistant',
      'game_store',
      'gym_reception',
      'freelance_photography',
      'radio_assistant',
      'freelance_programmer',
      'event_producer',
    ]);
    expect(IdleBalance.validateJobCatalog(), isEmpty);
    expect(
      IdleBalance.jobs.map((item) => item.displayOrder).toList(),
      List<int>.generate(9, (index) => index + 1),
    );
    for (final job in IdleBalance.jobs) {
      expect(job.roleTitles, hasLength(10), reason: job.id);
      expect(job.cycleDurationsByLevel, hasLength(10), reason: job.id);
      expect(job.timeCostsByLevel, hasLength(10), reason: job.id);
      expect(job.maximumLevel, 10, reason: job.id);
      expect(IdleBalance.jobRoleTitle(job.id, 1), job.roleTitles.first);
      expect(IdleBalance.nextJobRoleTitle(job.id, 1), job.roleTitles[1]);
      expect(IdleBalance.jobRoleTitle(job.id, 99), job.roleTitles.last);
      expect(IdleBalance.nextJobRoleTitle(job.id, 10), isNull);
    }
  });

  test('requisitos oficiais dos empregos usam IDs definitivos', () {
    expect(IdleBalance.job('neighborhood_deliveries').requires, isEmpty);
    expect(IdleBalance.job('local_flyering').requires, {
      'job:neighborhood_deliveries': 2,
    });
    expect(IdleBalance.job('game_store').requires, {
      'hobby:videogames': 2,
      'stage:roxanne': 2,
      'job:cafe_assistant': 2,
    });
    expect(IdleBalance.job('event_producer').requires, {
      'hobby:teatro': 7,
      'hobby:oratoria': 6,
      'job:radio_assistant': 5,
      'money:money': 50000,
    });
  });

  test('Entregas de Bairro possui recompensa, XP e escala oficial', () {
    final job = IdleBalance.job('neighborhood_deliveries');
    expect(job.displayName, 'Entregas de Bairro');
    expect(job.baseReward, 12);
    expect(job.xpPerCycle, 2);
    expect(job.difficulty, JobDifficulty.basic);
    expect(job.futureLocationId, 'neighborhood');
    expect(List<int>.generate(10, (index) => job.rewardAtLevel(index + 1)), [
      12,
      15,
      18,
      21,
      24,
      27,
      30,
      33,
      36,
      39,
    ]);
    expect(IdleBalance.jobXpNeeded(job, 1), 12);
    expect(IdleBalance.jobXpNeeded(job, 10), 0);
    expect(job.cycleDurationAtLevel(10), const Duration(seconds: 1));
    expect(job.timeCostAtLevel(10), 0);
    expect(job.rankAtLevel(10), 'Cidade sem Atrasos');
  });

  test('motor de emprego preserva parcial antes do primeiro ciclo', () {
    final service = SimulationService();
    final start = DateTime(2026, 7, 22, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: {
        'neighborhood_deliveries': ActivityProgress(
          active: true,
          cycleStartedAt: start.millisecondsSinceEpoch,
          lastProcessedAtUtc: start.millisecondsSinceEpoch,
        ),
        for (final id in jobIds.where((id) => id != 'neighborhood_deliveries'))
          id: const ActivityProgress(),
      },
    );

    final beforeCycle = service.advance(
      state,
      start.add(const Duration(seconds: 11)),
    );
    expect(beforeCycle.summary.money, 0);
    expect(beforeCycle.state.jobs['neighborhood_deliveries']!.cycles, 0);
    expect(
      beforeCycle
          .state
          .jobs['neighborhood_deliveries']!
          .accumulatedCycleProgressMs,
      11000,
    );

    final afterCycle = service.advance(
      beforeCycle.state,
      start.add(const Duration(seconds: 12)),
    );
    expect(afterCycle.summary.money, 12);
    expect(afterCycle.summary.jobExperience, 2);
    expect(afterCycle.state.money, 12);
    expect(afterCycle.state.jobs['neighborhood_deliveries']!.cycles, 1);
    expect(
      afterCycle
          .state
          .jobs['neighborhood_deliveries']!
          .accumulatedCycleProgressMs,
      0,
    );
  });

  test('motor de emprego processa múltiplos ciclos determinísticos', () {
    final now = DateTime(2026, 7, 22, 12);
    final start = now.subtract(const Duration(seconds: 24));
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: {
        'neighborhood_deliveries': ActivityProgress(
          active: true,
          cycleStartedAt: start.millisecondsSinceEpoch,
          lastProcessedAtUtc: start.millisecondsSinceEpoch,
        ),
        for (final id in jobIds.where((id) => id != 'neighborhood_deliveries'))
          id: const ActivityProgress(),
      },
    );
    final result = SimulationService().advance(state, now);
    expect(result.summary.money, 24);
    expect(result.summary.jobExperience, 4);
    expect(result.state.jobs['neighborhood_deliveries']!.cycles, 2);
    expect(result.state.jobs['neighborhood_deliveries']!.experience, 4);
  });

  test('pausar e retomar emprego preserva progresso parcial real', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
    await controller.debugProcessJobTime(
      'neighborhood_deliveries',
      const Duration(seconds: 5),
    );
    await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');

    expect(controller.state.jobs['neighborhood_deliveries']!.active, isFalse);
    expect(
      controller
          .state
          .jobs['neighborhood_deliveries']!
          .accumulatedCycleProgressMs,
      inInclusiveRange(5000, 5100),
    );
    expect(controller.state.availableBlocks, 6);

    await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
    await controller.debugProcessJobTime(
      'neighborhood_deliveries',
      const Duration(seconds: 7),
    );
    expect(controller.state.money, 12);
    expect(controller.state.jobs['neighborhood_deliveries']!.cycles, 1);
  });

  test('serviço central de Tempo deriva reservas por proprietário', () {
    final state = IdleState.fresh().copyWith(
      jobs: _jobsWith(
        overrides: const {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            firstStartedAtUtc: 10,
          ),
          'local_flyering': ActivityProgress(
            active: true,
            isUnlocked: true,
            firstStartedAtUtc: 20,
          ),
          'cafe_assistant': ActivityProgress(
            active: true,
            isUnlocked: true,
            firstStartedAtUtc: 30,
          ),
        },
      ),
    );

    final snapshot = TimeReservationService.snapshot(state);

    expect(snapshot.capacity, 6);
    expect(snapshot.reserved, 6);
    expect(snapshot.available, 0);
    expect(snapshot.reservations.map((item) => item.key), [
      'job:neighborhood_deliveries',
      'job:local_flyering',
      'job:cafe_assistant',
    ]);
    expect(snapshot.reservations.map((item) => item.ownerType).toSet(), {
      TimeReservationOwnerType.job,
    });
  });

  test('reconciliação pausa trabalhos mais recentes ao exceder Tempo', () {
    final state = IdleState.fresh().copyWith(
      jobs: _jobsWith(
        overrides: const {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            firstStartedAtUtc: 10,
            accumulatedCycleProgressMs: 900,
          ),
          'cafe_assistant': ActivityProgress(
            active: true,
            isUnlocked: true,
            firstStartedAtUtc: 20,
            accumulatedCycleProgressMs: 800,
          ),
          'radio_assistant': ActivityProgress(
            active: true,
            isUnlocked: true,
            firstStartedAtUtc: 30,
            accumulatedCycleProgressMs: 700,
          ),
        },
      ),
    );

    final result = TimeReservationService.reconcile(state);

    expect(result.pausedJobIds, ['radio_assistant']);
    expect(result.state.jobs['neighborhood_deliveries']!.active, isTrue);
    expect(result.state.jobs['cafe_assistant']!.active, isTrue);
    expect(result.state.jobs['radio_assistant']!.active, isFalse);
    expect(
      result.state.jobs['radio_assistant']!.accumulatedCycleProgressMs,
      700,
    );
    expect(result.snapshot.reserved, 5);
    expect(result.snapshot.available, 1);
  });

  test('nível máximo permanece ativo sem reservar Tempo', () {
    final state = IdleState.fresh().copyWith(
      jobs: _jobsWith(
        overrides: const {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            level: 10,
            firstStartedAtUtc: 10,
          ),
        },
      ),
    );

    final snapshot = TimeReservationService.snapshot(state);

    expect(state.jobs['neighborhood_deliveries']!.active, isTrue);
    expect(snapshot.reserved, 0);
    expect(snapshot.available, 6);
    expect(snapshot.reservations, isEmpty);
  });

  test(
    'XP de emprego evolui nível, ajusta duração, renda e custo de Tempo',
    () {
      final service = SimulationService();
      final start = DateTime(2026, 7, 22, 12);
      final state = IdleState.fresh().copyWith(
        lastSavedAt: start.millisecondsSinceEpoch,
        jobs: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            experience: 10,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
          for (final id in jobIds.where(
            (id) => id != 'neighborhood_deliveries',
          ))
            id: const ActivityProgress(),
        },
      );
      final result = service.advance(
        state,
        start.add(const Duration(seconds: 12)),
      );
      final progress = result.state.jobs['neighborhood_deliveries']!;

      expect(progress.level, 2);
      expect(progress.experience, 0);
      expect(
        IdleBalance.jobReward('neighborhood_deliveries', progress.level),
        15,
      );
      expect(
        IdleBalance.jobCycleDuration('neighborhood_deliveries', progress.level),
        const Duration(seconds: 10),
      );
      expect(
        IdleBalance.jobTimeCost('neighborhood_deliveries', progress.level),
        2,
      );
    },
  );

  test('nível 5 de Entregas reduz reserva de Tempo para um bloco', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetJobLevel('neighborhood_deliveries', 5);
    await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');

    expect(controller.state.jobs['neighborhood_deliveries']!.active, isTrue);
    expect(controller.state.availableBlocks, 5);
    expect(IdleBalance.jobTimeCost('neighborhood_deliveries', 5), 1);
  });

  test(
    'nível máximo usa produção contínua de um segundo sem XP ou nível 11',
    () {
      final service = SimulationService();
      final start = DateTime(2026, 7, 22, 12);
      final baseState = IdleState.fresh().copyWith(
        lastSavedAt: start.millisecondsSinceEpoch,
        jobs: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            level: 10,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
          for (final id in jobIds.where(
            (id) => id != 'neighborhood_deliveries',
          ))
            id: const ActivityProgress(),
        },
      );

      final beforePayment = service.advance(
        baseState,
        start.add(const Duration(milliseconds: 900)),
      );
      expect(beforePayment.summary.money, 0);
      expect(beforePayment.state.jobs['neighborhood_deliveries']!.cycles, 0);

      final oneSecond = service.advance(
        baseState,
        start.add(const Duration(seconds: 1)),
      );
      expect(oneSecond.summary.money, 39);
      expect(oneSecond.summary.jobExperience, 0);
      expect(oneSecond.state.jobs['neighborhood_deliveries']!.level, 10);
      expect(oneSecond.state.jobs['neighborhood_deliveries']!.experience, 0);

      final longRun = service.advance(
        baseState,
        start.add(const Duration(milliseconds: 10500)),
      );
      expect(longRun.summary.money, 390);
      expect(longRun.state.jobs['neighborhood_deliveries']!.cycles, 10);
      expect(
        longRun
            .state
            .jobs['neighborhood_deliveries']!
            .accumulatedCycleProgressMs,
        500,
      );
      expect(longRun.state.jobs['neighborhood_deliveries']!.level, 10);
    },
  );

  test('offline processa ciclo simples de emprego ativo', () {
    final now = DateTime(2026, 7, 22, 12);
    final startedAt = now
        .subtract(const Duration(seconds: 12))
        .millisecondsSinceEpoch;
    final state = IdleState.fresh().copyWith(
      lastSavedAt: startedAt,
      jobs: {
        'neighborhood_deliveries': ActivityProgress(
          active: true,
          cycleStartedAt: startedAt,
          lastProcessedAtUtc: startedAt,
        ),
        for (final id in jobIds.where((id) => id != 'neighborhood_deliveries'))
          id: const ActivityProgress(),
      },
    );

    final result = SimulationService().advance(state, now, offline: true);

    expect(result.summary.money, 12);
    expect(result.summary.jobExperience, 2);
    expect(result.summary.totalJobCompletions, 1);
    expect(result.state.money, 12);
    expect(result.state.jobs['neighborhood_deliveries']!.cycles, 1);
    expect(result.state.jobs['neighborhood_deliveries']!.experience, 2);
    expect(
      result.state.jobs['neighborhood_deliveries']!.accumulatedCycleProgressMs,
      0,
    );
  });

  test('emprego pausado não progride nem consome impulso offline', () {
    final now = DateTime(2026, 7, 22, 12);
    final startedAt = now
        .subtract(const Duration(hours: 1))
        .millisecondsSinceEpoch;
    final state = IdleState.fresh().copyWith(
      lastSavedAt: startedAt,
      jobs: {
        'neighborhood_deliveries': const ActivityProgress(
          active: false,
          isUnlocked: true,
          accumulatedCycleProgressMs: 4000,
          remainingBoostActiveTimeMs: 300000,
        ),
        for (final id in jobIds.where((id) => id != 'neighborhood_deliveries'))
          id: const ActivityProgress(),
      },
    );

    final result = SimulationService().advance(state, now, offline: true);
    final progress = result.state.jobs['neighborhood_deliveries']!;

    expect(result.summary.money, 0);
    expect(result.summary.jobExperience, 0);
    expect(progress.cycles, 0);
    expect(progress.accumulatedCycleProgressMs, 4000);
    expect(progress.remainingBoostActiveTimeMs, 300000);
  });

  test('impulso de emprego ativo custa 5 Cerejas e dura 10 minutos', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetResources(diamonds: 8);
    await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
    final result = await controller.purchaseJobBoost('neighborhood_deliveries');

    final progress = controller.state.jobs['neighborhood_deliveries']!;
    expect(result.message, contains('IMPULSO x2'));
    expect(controller.state.diamonds, 3);
    expect(
      progress.remainingBoostActiveTimeMs,
      IdleBalance.jobBoostActiveDuration.inMilliseconds,
    );
    expect(progress.currentIndividualSpeedMultiplier, 2);
  });

  test(
    'saldo insuficiente não compra impulso nem deixa Cerejas negativas',
    () async {
      final controller = GameController(MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetResources(diamonds: 4);
      await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
      final result = await controller.purchaseJobBoost(
        'neighborhood_deliveries',
      );

      expect(result.message, contains('Faltam 1 Cerejas'));
      expect(controller.state.diamonds, 4);
      expect(
        controller
            .state
            .jobs['neighborhood_deliveries']!
            .remainingBoostActiveTimeMs,
        0,
      );
    },
  );

  test('impulso ativo não empilha nem desconta Cerejas novamente', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetResources(diamonds: 20);
    await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
    await controller.purchaseJobBoost('neighborhood_deliveries');
    final remaining = controller
        .state
        .jobs['neighborhood_deliveries']!
        .remainingBoostActiveTimeMs;
    final second = await controller.purchaseJobBoost('neighborhood_deliveries');

    expect(second.message, contains('não acumula'));
    expect(controller.state.diamonds, 15);
    expect(
      controller
          .state
          .jobs['neighborhood_deliveries']!
          .remainingBoostActiveTimeMs,
      lessThanOrEqualTo(remaining),
    );
    expect(
      controller
          .state
          .jobs['neighborhood_deliveries']!
          .remainingBoostActiveTimeMs,
      greaterThan(remaining - 1000),
    );
  });

  test('impulso x2 acelera ciclo sem dobrar recompensa individual nem XP', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 9, 12);
    final base = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final normal = service.advance(base, start.add(const Duration(seconds: 6)));
    final boosted = service.advance(
      base.copyWith(
        jobs: {
          ...base.jobs,
          'neighborhood_deliveries': base.jobs['neighborhood_deliveries']!
              .copyWith(
                remainingBoostActiveTimeMs:
                    IdleBalance.jobBoostActiveDuration.inMilliseconds,
                boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
              ),
        },
      ),
      start.add(const Duration(seconds: 6)),
    );

    expect(normal.summary.money, 0);
    expect(boosted.summary.money, 12);
    expect(boosted.summary.jobExperience, 2);
    expect(boosted.state.jobs['neighborhood_deliveries']!.cycles, 1);
  });

  test('expiração segmentada aplica x2 até acabar e x1 depois', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 9, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            remainingBoostActiveTimeMs: 3000,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(seconds: 5)),
    );
    final progress = result.state.jobs['neighborhood_deliveries']!;

    expect(result.summary.money, 0);
    expect(progress.accumulatedCycleProgressMs, 8000);
    expect(progress.remainingBoostActiveTimeMs, 0);
    expect(
      result.summary.jobEvents['neighborhood_deliveries']!.boostExpired,
      isTrue,
    );
  });

  test('pausa congela o tempo restante do impulso', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 9, 12);
    final active = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            remainingBoostActiveTimeMs:
                IdleBalance.jobBoostActiveDuration.inMilliseconds,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final afterOneMinute = service.advance(
      active,
      start.add(const Duration(minutes: 1)),
    );
    final pausedProgress = afterOneMinute.state.jobs['neighborhood_deliveries']!
        .copyWith(active: false);
    final pausedState = afterOneMinute.state.copyWith(
      jobs: {
        ...afterOneMinute.state.jobs,
        'neighborhood_deliveries': pausedProgress,
      },
    );
    final afterPausedTime = service.advance(
      pausedState,
      start.add(const Duration(minutes: 2)),
    );

    expect(pausedProgress.remainingBoostActiveTimeMs, 540000);
    expect(
      afterPausedTime
          .state
          .jobs['neighborhood_deliveries']!
          .remainingBoostActiveTimeMs,
      540000,
    );
  });

  test(
    'save preserva impulso restante e offline ativo consome nesta rodada',
    () {
      final start = DateTime(2026, 8, 9, 12);
      final saved = IdleState.fresh()
          .copyWith(
            lastSavedAt: start.millisecondsSinceEpoch,
            jobs: _jobsWith(
              overrides: {
                'neighborhood_deliveries': ActivityProgress(
                  active: true,
                  isUnlocked: true,
                  level: 10,
                  accumulatedCycleProgressMs: 650,
                  lastProcessedAtUtc: start.millisecondsSinceEpoch,
                  remainingBoostActiveTimeMs: 123000,
                  boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
                ),
              },
            ),
          )
          .encode();
      final decoded = IdleState.decode(saved);
      final result = SimulationService().advance(
        decoded,
        start.add(const Duration(hours: 1)),
        offline: true,
      );

      final progress = result.state.jobs['neighborhood_deliveries']!;
      expect(progress.level, 10);
      expect(progress.experience, 0);
      expect(progress.accumulatedCycleProgressMs, 650);
      expect(progress.remainingBoostActiveTimeMs, 0);
      expect(result.summary.money, 145197);
      expect(result.summary.jobExperience, 0);
      expect(result.summary.boostsExpired, 1);
      expect(result.summary.discardedByLimit, Duration.zero);
    },
  );

  test('produção contínua no nível máximo integra impulso x2', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 9, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            level: 10,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            remainingBoostActiveTimeMs:
                IdleBalance.jobBoostActiveDuration.inMilliseconds,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(seconds: 1)),
    );
    final progress = result.state.jobs['neighborhood_deliveries']!;

    expect(result.summary.money, 78);
    expect(result.summary.jobExperience, 0);
    expect(progress.cycles, 2);
    expect(progress.level, 10);
    expect(progress.experience, 0);
    expect(progress.accumulatedCycleProgressMs, 0);
  });

  test('offline preserva resto de ciclo sem level up', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 12, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(seconds: 30)),
      offline: true,
    );
    final progress = result.state.jobs['neighborhood_deliveries']!;

    expect(result.summary.money, 24);
    expect(result.summary.jobExperience, 4);
    expect(progress.level, 1);
    expect(progress.cycles, 2);
    expect(progress.accumulatedCycleProgressMs, 6000);
  });

  test('offline aplica level up e usa duração e recompensa novas depois', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 12, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            experience: 10,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(seconds: 30)),
      offline: true,
    );
    final progress = result.state.jobs['neighborhood_deliveries']!;

    expect(result.summary.money, 27);
    expect(result.summary.jobExperience, 4);
    expect(result.summary.jobLevels, 1);
    expect(progress.level, 2);
    expect(progress.experience, 2);
    expect(progress.cycles, 2);
    expect(progress.accumulatedCycleProgressMs, 8000);
  });

  test('offline no nível 10 agrega pagamentos contínuos', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 12, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            level: 10,
            accumulatedCycleProgressMs: 500,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(seconds: 10)),
      offline: true,
    );
    final progress = result.state.jobs['neighborhood_deliveries']!;

    expect(result.summary.money, 390);
    expect(result.summary.jobExperience, 0);
    expect(result.summary.totalContinuousPayments, 10);
    expect(progress.level, 10);
    expect(progress.experience, 0);
    expect(progress.accumulatedCycleProgressMs, 500);
  });

  test('offline nível 10 com impulso x2 gera dois pagamentos equivalentes', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 12, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            level: 10,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            remainingBoostActiveTimeMs: 20000,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(seconds: 10)),
      offline: true,
    );

    expect(result.summary.money, 780);
    expect(result.summary.totalContinuousPayments, 20);
    expect(result.summary.jobExperience, 0);
    expect(
      result.state.jobs['neighborhood_deliveries']!.remainingBoostActiveTimeMs,
      10000,
    );
  });

  test('offline segmenta expiração de impulso no nível 10', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 12, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            level: 10,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            remainingBoostActiveTimeMs: 3000,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(seconds: 5)),
      offline: true,
    );

    expect(result.summary.money, 312);
    expect(result.summary.totalContinuousPayments, 8);
    expect(result.summary.boostsExpired, 1);
    expect(
      result.state.jobs['neighborhood_deliveries']!.remainingBoostActiveTimeMs,
      0,
    );
  });

  test('offline respeita limite de 8 horas e não consome excedente', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 12, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            level: 10,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            remainingBoostActiveTimeMs:
                IdleBalance.jobBoostActiveDuration.inMilliseconds,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = service.advance(
      state,
      start.add(const Duration(hours: 12)),
      offline: true,
    );

    expect(result.summary.elapsed, IdleBalance.defaultJobOfflineLimit);
    expect(result.summary.discardedByLimit, const Duration(hours: 4));
    expect(result.summary.money, 1146600);
    expect(result.summary.totalContinuousPayments, 29400);
    expect(
      result.state.jobs['neighborhood_deliveries']!.remainingBoostActiveTimeMs,
      0,
    );
  });

  test('offline pode desbloquear requisito sem iniciar emprego novo', () async {
    final now = DateTime.now().toUtc();
    final startedAt = now
        .subtract(const Duration(seconds: 12))
        .millisecondsSinceEpoch;
    final storage = MemoryIdleStorage()
      ..value = IdleState.fresh()
          .copyWith(
            lastSavedAt: startedAt,
            jobs: _jobsWith(
              overrides: {
                'neighborhood_deliveries': ActivityProgress(
                  active: true,
                  isUnlocked: true,
                  experience: 10,
                  cycleStartedAt: startedAt,
                  lastProcessedAtUtc: startedAt,
                ),
              },
            ),
          )
          .encode();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    expect(controller.state.jobs['neighborhood_deliveries']!.level, 2);
    expect(controller.state.jobs['local_flyering']!.isUnlocked, isTrue);
    expect(controller.state.jobs['local_flyering']!.active, isFalse);
    expect(
      controller.takeOfflineSummary()!.jobUnlocks,
      contains('local_flyering'),
    );
  });

  test('offline não aplica o mesmo período duas vezes', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 12, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final first = service.advance(
      state,
      start.add(const Duration(seconds: 12)),
      offline: true,
    );
    final second = service.advance(
      first.state,
      start.add(const Duration(seconds: 12)),
      offline: true,
    );

    expect(first.summary.money, 12);
    expect(second.summary.money, 0);
    expect(second.summary.jobExperience, 0);
    expect(second.summary.totalJobCompletions, 0);
  });

  test('timestamp futuro não gera valores negativos offline', () {
    final service = SimulationService();
    final now = DateTime(2026, 8, 12, 12);
    final future = now.add(const Duration(hours: 1)).millisecondsSinceEpoch;
    final state = IdleState.fresh().copyWith(
      lastSavedAt: future,
      jobs: _jobsWith(
        overrides: {
          'neighborhood_deliveries': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: future,
            lastProcessedAtUtc: future,
          ),
        },
      ),
    );

    final result = service.advance(state, now, offline: true);

    expect(result.summary.elapsed, Duration.zero);
    expect(result.summary.money, 0);
    expect(result.summary.jobExperience, 0);
    expect(
      result.state.jobs['neighborhood_deliveries']!.accumulatedCycleProgressMs,
      0,
    );
  });

  test('Tempo impede atividade que excede a capacidade', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.toggle(ActivityKind.hobby, 'academia');
    final result = await controller.toggle(ActivityKind.hobby, 'teatro');
    expect(controller.state.availableBlocks, 0);
    expect(result.message, contains('insuficientes'));
  });

  test('migra save narrativo v1 sem quebrar Lia e dinheiro', () {
    final old = jsonEncode({
      'money': 140,
      'lia': {
        'affinity': 6,
        'stage': 2,
        'chocolatesGiven': 3,
        'unlockedScenes': ['end_of_day'],
      },
    });
    final migrated = IdleState.decode(old);
    expect(migrated.money, 140);
    expect(migrated.characters['roxanne']!.unlocked, isTrue);
    expect(migrated.characters['roxanne']!.affection, 6);
    expect(migrated.characters['ryomi']!.unlocked, isTrue);
    expect(migrated.characters['ryomi']!.affection, 6);
  });

  test(
    'entrega existente registra quantidade sem bônus favorito inventado',
    () async {
      final controller = GameController(MemoryIdleStorage());
      await controller.initialize();
      await controller.debugMoney(1000);
      final result = await controller.gift('ryomi', 'chocolate', 10);
      expect(result.message, contains('+50'));
      expect(controller.state.money, 500);
      expect(controller.state.characters['ryomi']!.gifts, 10);
      expect(
        controller.state.characters['roxanne']!.giftDeliveries['chocolate'],
        10,
      );
    },
  );

  test('porcentagem da rota combina etapa e afeição atual', () {
    const inicio = CharacterProgress(stage: 0, affection: 0);
    final metadePrimeira = CharacterProgress(
      stage: 0,
      affection: IdleBalance.affectionNeeded(0) ~/ 2,
    );
    const terceiraEtapa = CharacterProgress(stage: 2, affection: 0);
    final finalizada = CharacterProgress(
      stage: IdleRules.totalRelationshipStages - 1,
      affection: IdleBalance.affectionNeeded(
        IdleRules.totalRelationshipStages - 1,
      ),
    );

    expect(IdleRules.routeProgressPercent(inicio), 0);
    expect(
      IdleRules.routeProgressPercent(metadePrimeira),
      greaterThan(IdleRules.routeProgressPercent(inicio)),
    );
    expect(
      IdleRules.routeProgressPercent(terceiraEtapa),
      greaterThan(IdleRules.routeProgressPercent(metadePrimeira)),
    );
    expect(IdleRules.routeProgressPercent(finalizada), 100);
  });

  test('ganho passivo usa regra oficial de um segundo a partir da etapa 3', () {
    final service = SimulationService();
    final now = DateTime(2026, 7, 29, 12);
    final lastSavedAt = now
        .subtract(const Duration(seconds: 10))
        .millisecondsSinceEpoch;

    IdleState stateAt(int stage, {int affection = 0}) =>
        IdleState.fresh().copyWith(
          lastSavedAt: lastSavedAt,
          characters: {
            'ryomi': CharacterProgress(
              unlocked: true,
              stage: stage,
              affection: affection,
            ),
          },
        );

    final stageOne = service.advance(stateAt(0), now);
    final stageTwo = service.advance(stateAt(1), now);
    final stageThree = service.advance(
      stateAt(IdleBalance.passiveAffectionUnlockStage),
      now,
    );

    expect(IdleBalance.passiveAffectionUnlockStageNumber, 3);
    expect(IdleBalance.passiveAffectionInterval, const Duration(seconds: 1));
    expect(IdleBalance.passiveAffectionReward, 1);
    expect(stageOne.summary.affection, 0);
    expect(stageTwo.summary.affection, 0);
    expect(stageThree.summary.affection, 10);
    expect(stageThree.state.characters['ryomi']!.affection, 10);
  });

  test('relógio passivo preserva frações entre ticks curtos', () {
    final service = SimulationService();
    final start = DateTime(2026, 7, 29, 12);
    final initial = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      characters: {
        'ryomi': CharacterProgress(
          unlocked: true,
          stage: IdleBalance.passiveAffectionUnlockStage,
        ),
      },
    );

    final firstTick = service.advance(
      initial,
      start.add(const Duration(milliseconds: 900)),
    );
    expect(firstTick.summary.affection, 0);
    expect(firstTick.state.characters['ryomi']!.affection, 0);

    final secondTick = service.advance(
      firstTick.state,
      start.add(const Duration(milliseconds: 1100)),
    );
    expect(secondTick.summary.affection, 1);
    expect(secondTick.state.characters['ryomi']!.affection, 1);
  });

  test('ganho passivo para quando vínculo finalizado chega a 100%', () {
    final service = SimulationService();
    final now = DateTime(2026, 7, 29, 12);
    final finalStage = IdleRules.totalRelationshipStages - 1;
    final target = IdleBalance.affectionNeeded(finalStage);
    final lastSavedAt = now
        .subtract(const Duration(seconds: 10))
        .millisecondsSinceEpoch;

    final incomplete = IdleState.fresh().copyWith(
      lastSavedAt: lastSavedAt,
      characters: {
        'ryomi': CharacterProgress(
          unlocked: true,
          stage: finalStage,
          affection: target - 2,
        ),
      },
    );
    final complete = IdleState.fresh().copyWith(
      lastSavedAt: lastSavedAt,
      characters: {
        'ryomi': CharacterProgress(
          unlocked: true,
          stage: finalStage,
          affection: target,
        ),
      },
    );

    final incompleteResult = service.advance(incomplete, now);
    expect(incompleteResult.summary.affection, 2);
    expect(incompleteResult.state.characters['ryomi']!.affection, target);

    final completeResult = service.advance(complete, now);
    expect(completeResult.summary.affection, 0);
    expect(completeResult.state.characters['ryomi']!.affection, target);
  });

  test('tick real aplica passivo após mudança de estágio pela DEV', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetRyomiProgress(
      stage: IdleBalance.passiveAffectionUnlockStage,
      affection: 0,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await controller.tick();

    expect(controller.state.characters['ryomi']!.affection, 1);
  });

  test('ganho passivo altera apenas o estado real do controller', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetRyomiProgress(
      stage: IdleBalance.passiveAffectionUnlockStage,
      affection: 0,
    );
    final afterDebug = controller.state.characters['ryomi']!.affection;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await controller.tick();

    expect(afterDebug, 0);
    expect(controller.state.characters['ryomi']!.affection, 1);
  });

  test(
    'os nove empregos processam ciclos independentes pelo motor central',
    () {
      final service = SimulationService();
      final start = DateTime(2026, 8, 3, 12);
      final overrides = <String, ActivityProgress>{};
      for (final job in IdleBalance.jobs) {
        overrides[job.id] = ActivityProgress(
          active: true,
          cycleStartedAt: start.millisecondsSinceEpoch,
          lastProcessedAtUtc: start.millisecondsSinceEpoch,
          isUnlocked: true,
        );
      }
      final state = IdleState.fresh().copyWith(
        jobs: _jobsWith(overrides: overrides, unlocked: true),
        lastSavedAt: start.millisecondsSinceEpoch,
      );
      final longest = IdleBalance.jobs
          .map((job) => job.cycleDurationAtLevel(1).inSeconds)
          .reduce((a, b) => a > b ? a : b);

      final result = service.advance(
        state,
        start.add(Duration(seconds: longest)),
      );

      for (final job in IdleBalance.jobs) {
        final progress = result.state.jobs[job.id]!;
        final expectedCycles = longest ~/ job.cycleDurationAtLevel(1).inSeconds;
        expect(progress.cycles, expectedCycles, reason: job.id);
        expect(
          progress.lifetimeMoneyEarned,
          expectedCycles * job.rewardAtLevel(1),
          reason: job.id,
        );
        expect(progress.level, greaterThanOrEqualTo(1), reason: job.id);
        if (progress.level < job.maximumLevel) {
          expect(
            progress.experience,
            lessThan(IdleBalance.jobXpNeeded(job, progress.level)),
            reason: job.id,
          );
        } else {
          expect(progress.experience, 0, reason: job.id);
        }
      }
      final expectedMoney = IdleBalance.jobs.fold<int>(0, (total, job) {
        final cycles = longest ~/ job.cycleDurationAtLevel(1).inSeconds;
        return total + cycles * job.rewardAtLevel(1);
      });
      expect(result.state.money, expectedMoney);
      expect(result.summary.jobExperience, greaterThan(0));
    },
  );

  test('produção contínua no nível 10 funciona para os nove empregos', () {
    final service = SimulationService();
    final start = DateTime(2026, 8, 3, 12);
    final expectedIncome = {
      'neighborhood_deliveries': 39,
      'local_flyering': 49,
      'cafe_assistant': 163,
      'game_store': 293,
      'gym_reception': 520,
      'freelance_photography': 845,
      'radio_assistant': 1950,
      'freelance_programmer': 2925,
      'event_producer': 5850,
    };

    for (final job in IdleBalance.jobs) {
      final state = IdleState.fresh().copyWith(
        jobs: _jobsWith(
          overrides: {
            job.id: ActivityProgress(
              active: true,
              level: 10,
              cycleStartedAt: start.millisecondsSinceEpoch,
              lastProcessedAtUtc: start.millisecondsSinceEpoch,
              isUnlocked: true,
            ),
          },
          unlocked: true,
        ),
        lastSavedAt: start.millisecondsSinceEpoch,
      );

      final result = service.advance(
        state,
        start.add(const Duration(milliseconds: 2500)),
      );
      final progress = result.state.jobs[job.id]!;
      expect(job.cycleDurationAtLevel(10), const Duration(seconds: 1));
      expect(job.timeCostAtLevel(10), 0);
      expect(result.summary.money, expectedIncome[job.id]! * 2);
      expect(result.summary.jobExperience, 0);
      expect(progress.level, 10);
      expect(progress.experience, 0);
      expect(progress.cycles, 2);
      expect(progress.continuousPayments, 2);
      expect(progress.accumulatedCycleProgressMs, 500);
    }
  });

  test('simultaneidade soma reservas e mantém progresso separado', () async {
    final storage = MemoryIdleStorage()
      ..value = IdleState.fresh()
          .copyWith(
            jobs: _jobsWith(
              overrides: {
                'neighborhood_deliveries': const ActivityProgress(
                  isUnlocked: true,
                ),
                'local_flyering': const ActivityProgress(isUnlocked: true),
                'cafe_assistant': const ActivityProgress(isUnlocked: true),
              },
              unlocked: false,
            ),
          )
          .encode();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    expect(
      (await controller.toggle(
        ActivityKind.job,
        'neighborhood_deliveries',
      )).message,
      contains('iniciada'),
    );
    expect(
      (await controller.toggle(ActivityKind.job, 'local_flyering')).message,
      contains('iniciada'),
    );
    expect(
      (await controller.toggle(ActivityKind.job, 'cafe_assistant')).message,
      contains('iniciada'),
    );

    expect(controller.state.availableBlocks, 0);
    final blocked = await controller.toggle(ActivityKind.hobby, 'leitura');
    expect(blocked.message, contains('insuficientes'));

    await controller.debugProcessJobTime(
      'neighborhood_deliveries',
      const Duration(seconds: 12),
    );
    expect(controller.state.jobs['neighborhood_deliveries']!.cycles, 1);
    expect(controller.state.jobs['local_flyering']!.active, isTrue);
    expect(controller.state.jobs['cafe_assistant']!.cycles, 0);

    await controller.toggle(ActivityKind.job, 'local_flyering');
    expect(controller.state.jobs['local_flyering']!.active, isFalse);
    expect(controller.state.jobs['neighborhood_deliveries']!.active, isTrue);
    expect(controller.state.availableBlocks, 1);
  });

  test(
    'desbloqueio de Panfletagem é automático e não inicia sozinho',
    () async {
      final controller = GameController(MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      expect(
        controller.state.jobs['neighborhood_deliveries']!.isUnlocked,
        isTrue,
      );
      expect(controller.state.jobs['local_flyering']!.isUnlocked, isFalse);
      await controller.debugSetJobLevel('neighborhood_deliveries', 1);
      expect(controller.state.jobs['local_flyering']!.isUnlocked, isFalse);

      await controller.debugSetJobLevel('neighborhood_deliveries', 2);

      expect(controller.state.jobs['local_flyering']!.isUnlocked, isTrue);
      expect(controller.state.jobs['local_flyering']!.active, isFalse);
      expect(
        controller.recentlyUnlockedJobIds.contains('local_flyering'),
        isTrue,
      );
    },
  );

  test('Cafeteria exige Panfletagem nível 3 e saldo sem consumo', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetJobLevel('local_flyering', 2);
    await controller.debugSetResources(money: 250);
    expect(controller.state.jobs['cafe_assistant']!.isUnlocked, isFalse);

    await controller.debugSetResources(money: 249);
    await controller.debugSetJobLevel('local_flyering', 3);
    expect(controller.state.jobs['cafe_assistant']!.isUnlocked, isFalse);

    await controller.debugSetResources(money: 250);
    expect(controller.state.money, 250);
    expect(controller.state.jobs['cafe_assistant']!.isUnlocked, isTrue);

    await controller.debugSetResources(money: 0);
    expect(controller.state.jobs['cafe_assistant']!.isUnlocked, isTrue);
  });

  test(
    'requisitos compostos avaliam Loja, Academia, Fotografia, Rádio e Eventos',
    () {
      final state = IdleState.fresh().copyWith(
        money: 50000,
        jobs: _jobsWith(
          overrides: {
            'cafe_assistant': const ActivityProgress(level: 4),
            'radio_assistant': const ActivityProgress(level: 5),
          },
          unlocked: true,
        ),
        hobbies: _hobbiesWith(
          overrides: {
            'videogames': const ActivityProgress(level: 2),
            'academia': const ActivityProgress(level: 3),
            'fotografia': const ActivityProgress(level: 4),
            'oratoria': const ActivityProgress(level: 6),
            'musica': const ActivityProgress(level: 4),
            'programacao': const ActivityProgress(level: 6),
            'teatro': const ActivityProgress(level: 7),
          },
        ),
        characters: {
          PlayableCharacterIds.roxanne: const CharacterProgress(
            unlocked: true,
            stage: 4,
          ),
          PlayableCharacterIds.kai: const CharacterProgress(unlocked: true),
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
        final evaluation = JobRequirementEvaluator.evaluate(
          state,
          IdleBalance.job(id),
        );
        expect(evaluation.requirementsMet, isTrue, reason: id);
      }
    },
  );

  test('avaliador retorna progresso estruturado e aliases seguros', () {
    final state = IdleState.fresh().copyWith(
      characters: {
        PlayableCharacterIds.roxanne: const CharacterProgress(
          unlocked: true,
          stage: 2,
        ),
        PlayableCharacterIds.kai: const CharacterProgress(unlocked: true),
        PlayableCharacterIds.legacyRyomi: const CharacterProgress(
          unlocked: true,
          stage: 2,
        ),
      },
      hobbies: _hobbiesWith(
        overrides: {
          'academia': const ActivityProgress(level: 3),
          'fotografia': const ActivityProgress(level: 4),
          'oratoria': const ActivityProgress(level: 5),
          'programacao': const ActivityProgress(level: 6),
          'teatro': const ActivityProgress(level: 7),
        },
      ),
    );

    final ryomi = JobRequirementEvaluator.evaluateRequirement(
      state,
      const JobRequirement(JobRequirementType.relationshipStage, 'ryomi', 2),
    );
    final legacyHobbies = {
      'condicionamento': 'academia',
      'criatividade': 'fotografia',
      'comunicacao': 'oratoria',
      'tecnologia': 'programacao',
      'carisma': 'teatro',
    };

    expect(ryomi.targetId, PlayableCharacterIds.roxanne);
    expect(ryomi.isMet, isTrue);
    for (final entry in legacyHobbies.entries) {
      final evaluation = JobRequirementEvaluator.evaluateRequirement(
        state,
        JobRequirement(JobRequirementType.hobbyLevel, entry.key, 1),
      );
      expect(evaluation.targetId, entry.value);
      expect(evaluation.isMet, isTrue);
    }
  });

  test('trabalho bloqueado não inicia nem altera estado', () async {
    final controller = GameController(MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    final before = controller.state.jobs['cafe_assistant']!;
    final result = await controller.toggle(ActivityKind.job, 'cafe_assistant');

    expect(result.message, contains('bloqueado'));
    expect(controller.state.jobs['cafe_assistant']!.active, isFalse);
    expect(controller.state.jobs['cafe_assistant']!.level, before.level);
    expect(controller.state.money, 0);
    expect(controller.state.availableBlocks, 6);
  });

  test('save preserva nove progressos pausados sem ganho offline', () async {
    final start = DateTime.now().subtract(const Duration(minutes: 5));
    final savedState = IdleState.fresh().copyWith(
      money: 100,
      lastSavedAt: start.millisecondsSinceEpoch,
      jobs: _jobsWith(
        overrides: {
          for (final job in IdleBalance.jobs)
            job.id: ActivityProgress(
              active: false,
              level: job.id == 'event_producer' ? 10 : 3,
              experience: 7,
              cycles: 4,
              continuousPayments: job.id == 'event_producer' ? 4 : 0,
              accumulatedCycleProgressMs: 500,
              cycleStartedAt: start.millisecondsSinceEpoch,
              lastProcessedAtUtc: start.millisecondsSinceEpoch,
              lifetimeMoneyEarned: 123,
              activePlayTimeMs: 456,
              firstStartedAtUtc: start.millisecondsSinceEpoch,
              hasBeenStarted: true,
              isUnlocked: true,
            ),
        },
        unlocked: true,
      ),
    );
    final storage = MemoryIdleStorage()..value = savedState.encode();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    expect(controller.state.money, 100);
    for (final job in IdleBalance.jobs) {
      final progress = controller.state.jobs[job.id]!;
      expect(progress.isUnlocked, isTrue, reason: job.id);
      expect(progress.cycles, 4, reason: job.id);
      expect(
        progress.continuousPayments,
        job.id == 'event_producer' ? 4 : 0,
        reason: job.id,
      );
      expect(progress.lifetimeMoneyEarned, 123, reason: job.id);
      expect(progress.hasBeenStarted, isTrue, reason: job.id);
    }
  });

  test('save definitivo usa schema versÃ£o 5 e nove empregos oficiais', () {
    final encoded = IdleState.fresh().encode();
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final decoded = IdleState.decodeWithReport(encoded);

    expect(json['version'], IdleSaveSchema.currentVersion);
    expect(decoded.report.fromVersion, IdleSaveSchema.currentVersion);
    expect(decoded.report.migrated, isFalse);
    expect(decoded.state.jobs.keys.toList(), jobIds);
    expect(decoded.state.jobs['neighborhood_deliveries']!.isUnlocked, isTrue);
    expect(decoded.state.jobs['local_flyering']!.isUnlocked, isFalse);
  });

  test('migra save piloto contendo somente Entregas sem duplicar dinheiro', () {
    final now = DateTime(2026, 8, 12, 12).millisecondsSinceEpoch;
    final result = IdleState.decodeWithReport(
      jsonEncode({
        'version': 4,
        'money': 5000,
        'diamonds': 8,
        'lastSavedAt': now,
        'jobs': {
          'neighborhood_deliveries': {
            'level': 5,
            'experience': 7,
            'active': true,
            'accumulatedCycleProgressMs': 500,
            'lastProcessedAtUtc': now,
            'lifetimeMoneyEarned': 2000,
            'completedCycles': 40,
            'activePlayTime': 12345,
            'hasBeenStarted': true,
          },
        },
      }),
      nowMs: now,
    );
    final state = result.state;
    final deliveries = state.jobs['neighborhood_deliveries']!;

    expect(result.report.fromVersion, 4);
    expect(result.report.toVersion, IdleSaveSchema.currentVersion);
    expect(result.report.migrated, isTrue);
    expect(state.money, 5000);
    expect(state.diamonds, 8);
    expect(state.jobs.keys.toList(), jobIds);
    expect(deliveries.level, 5);
    expect(deliveries.experience, 7);
    expect(deliveries.active, isTrue);
    expect(deliveries.lifetimeMoneyEarned, 2000);
    expect(deliveries.cycles, 40);
    expect(state.jobs['local_flyering']!.active, isFalse);
  });

  test(
    'migra nove empregos preservando progresso e impulso sem repagar counters',
    () {
      final now = DateTime(2026, 8, 12, 12).millisecondsSinceEpoch;
      final jobs = {
        for (final job in IdleBalance.jobs)
          job.id: {
            'level': job.displayOrder == 9 ? 10 : job.displayOrder,
            'currentXp': job.displayOrder,
            'isUnlocked': true,
            'isActive': false,
            'accumulatedCycleProgress': 250,
            'remainingBoostActiveTime': 120000,
            'lastProcessedAtUtc': now,
            'lifetimeMoneyEarned': job.displayOrder * 100,
            'completedCycles': job.displayOrder * 2,
            'continuousPayments': job.displayOrder * 3,
            'activePlayTime': job.displayOrder * 1000,
            'firstStartedAtUtc': now - job.displayOrder,
            'hasBeenStarted': true,
          },
      };

      final result = IdleState.decodeWithReport(
        jsonEncode({
          'version': 4,
          'money': 10000,
          'lastSavedAt': now,
          'jobs': jobs,
        }),
        nowMs: now,
      );

      expect(result.state.money, 10000);
      for (final job in IdleBalance.jobs) {
        final progress = result.state.jobs[job.id]!;
        expect(progress.isUnlocked, isTrue, reason: job.id);
        expect(progress.lifetimeMoneyEarned, job.displayOrder * 100);
        expect(progress.cycles, job.displayOrder * 2);
        expect(progress.continuousPayments, job.displayOrder * 3);
        expect(progress.activePlayTimeMs, job.displayOrder * 1000);
        expect(progress.remainingBoostActiveTimeMs, 120000);
      }
      expect(result.state.jobs['event_producer']!.level, 10);
      expect(result.state.jobs['event_producer']!.experience, 0);
    },
  );

  test('saneamento normaliza nÃ­vel, XP, progresso, boost e counters', () {
    final now = DateTime(2026, 8, 12, 12).millisecondsSinceEpoch;
    final result = IdleState.decodeWithReport(
      jsonEncode({
        'version': 4,
        'lastSavedAt': now,
        'jobs': {
          'neighborhood_deliveries': {
            'level': 11,
            'experience': 999,
            'cycles': -7,
            'continuousPayments': -99,
            'accumulatedCycleProgressMs': 1400,
            'remainingBoostActiveTimeMs': -1,
            'lifetimeMoneyEarned': -20,
            'activePlayTimeMs': -30,
          },
          'local_flyering': {
            'level': 0,
            'experience': -100,
            'accumulatedCycleProgressMs': -500,
            'remainingBoostActiveTimeMs': 999999999,
            'isUnlocked': true,
            'hasBeenStarted': true,
          },
        },
      }),
      nowMs: now,
    );
    final deliveries = result.state.jobs['neighborhood_deliveries']!;
    final flyering = result.state.jobs['local_flyering']!;

    expect(deliveries.level, 10);
    expect(deliveries.experience, 0);
    expect(deliveries.accumulatedCycleProgressMs, 999);
    expect(deliveries.cycles, 0);
    expect(deliveries.continuousPayments, 0);
    expect(deliveries.lifetimeMoneyEarned, 0);
    expect(deliveries.remainingBoostActiveTimeMs, 0);
    expect(flyering.level, 1);
    expect(flyering.experience, 0);
    expect(flyering.accumulatedCycleProgressMs, 0);
    expect(
      flyering.remainingBoostActiveTimeMs,
      IdleBalance.jobBoostActiveDuration.inMilliseconds,
    );
    expect(result.report.sanitizedFields, greaterThan(0));
  });

  test('emprego desconhecido Ã© ignorado e emprego ausente recebe default', () {
    final now = DateTime(2026, 8, 12, 12).millisecondsSinceEpoch;
    final result = IdleState.decodeWithReport(
      jsonEncode({
        'version': 5,
        'lastSavedAt': now,
        'jobs': {
          'deleted_fake_job': {'level': 10, 'active': true},
          'neighborhood_deliveries': {'level': 2, 'isUnlocked': true},
        },
      }),
      nowMs: now,
    );

    expect(result.state.jobs.containsKey('deleted_fake_job'), isFalse);
    expect(result.report.ignoredUnknownJobs, contains('deleted_fake_job'));
    expect(result.state.jobs['game_store'], isNotNull);
    expect(result.state.jobs['game_store']!.level, 1);
    expect(result.state.jobs['game_store']!.active, isFalse);
  });

  test(
    'aliases de Ryomi e hobbies legados sÃ£o migrados para IDs oficiais',
    () {
      final now = DateTime(2026, 8, 12, 12).millisecondsSinceEpoch;
      final result = IdleState.decodeWithReport(
        jsonEncode({
          'version': 3,
          'lastSavedAt': now,
          'characters': {
            'ryomi': {'stage': 4, 'affection': 33, 'unlocked': true},
          },
          'hobbies': {
            'condicionamento': {'level': 3},
            'criatividade': {'level': 4},
            'comunicacao': {'level': 5},
            'tecnologia': {'level': 6},
            'carisma': {'level': 7},
          },
        }),
        nowMs: now,
      );

      expect(result.state.characters[PlayableCharacterIds.roxanne]!.stage, 4);
      expect(result.state.characters['ryomi']!.affection, 33);
      expect(result.state.hobbies['academia']!.level, 3);
      expect(result.state.hobbies['fotografia']!.level, 4);
      expect(result.state.hobbies['oratoria']!.level, 5);
      expect(result.state.hobbies['programacao']!.level, 6);
      expect(result.state.hobbies['teatro']!.level, 7);
      expect(result.report.aliasesConverted['ryomi'], 'roxanne');
    },
  );

  test('save sem timestamp confiÃ¡vel nÃ£o gera offline retroativo', () async {
    final storage = MemoryIdleStorage()
      ..value = jsonEncode({
        'version': 5,
        'money': 100,
        'jobs': {
          'neighborhood_deliveries': {
            'active': true,
            'isUnlocked': true,
            'level': 10,
            'lastProcessedAtUtc': 0,
          },
        },
      });
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    expect(controller.state.money, 100);
    expect(controller.takeOfflineSummary(), isNull);
    expect(
      controller.lastMigrationReport!.offlineSkippedDueToMissingTimestamp,
      isTrue,
    );
  });

  test(
    'timestamp futuro nÃ£o gera dinheiro nem consome boost no load',
    () async {
      final future = DateTime.now()
          .toUtc()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final storage = MemoryIdleStorage()
        ..value = IdleState.fresh()
            .copyWith(
              money: 50,
              lastSavedAt: future,
              jobs: _jobsWith(
                overrides: {
                  'neighborhood_deliveries': ActivityProgress(
                    active: true,
                    isUnlocked: true,
                    level: 10,
                    lastProcessedAtUtc: future,
                    remainingBoostActiveTimeMs: 20000,
                  ),
                },
              ),
            )
            .encode();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      expect(controller.state.money, 50);
      expect(
        controller
            .state
            .jobs['neighborhood_deliveries']!
            .remainingBoostActiveTimeMs,
        20000,
      );
      expect(controller.takeOfflineSummary(), isNull);
    },
  );

  test('desbloqueio permanente e progresso implicam desbloqueio', () {
    final now = DateTime(2026, 8, 12, 12).millisecondsSinceEpoch;
    final result = IdleState.decodeWithReport(
      jsonEncode({
        'version': 5,
        'money': 100,
        'lastSavedAt': now,
        'jobs': {
          'cafe_assistant': {'isUnlocked': true},
          'game_store': {'level': 3},
        },
      }),
      nowMs: now,
    );

    expect(result.state.jobs['cafe_assistant']!.isUnlocked, isTrue);
    expect(result.state.jobs['game_store']!.isUnlocked, isTrue);
  });

  test(
    'emprego ativo bloqueado corrompido Ã© pausado sem reserva de Tempo',
    () {
      final now = DateTime(2026, 8, 12, 12).millisecondsSinceEpoch;
      final result = IdleState.decodeWithReport(
        jsonEncode({
          'version': 5,
          'lastSavedAt': now,
          'jobs': {
            'cafe_assistant': {'active': true},
          },
        }),
        nowMs: now,
      );

      expect(result.state.jobs['cafe_assistant']!.isUnlocked, isFalse);
      expect(result.state.jobs['cafe_assistant']!.active, isFalse);
      expect(result.state.availableBlocks, 6);
    },
  );

  test(
    'reconcilia capacidade excedida apÃ³s migraÃ§Ã£o preservando antigos',
    () async {
      final start = DateTime.now().toUtc();
      final old = IdleState.fresh().copyWith(
        totalBlocks: 3,
        lastSavedAt: start.millisecondsSinceEpoch,
        jobs: _jobsWith(
          overrides: {
            'neighborhood_deliveries': ActivityProgress(
              active: true,
              isUnlocked: true,
              firstStartedAtUtc: start
                  .subtract(const Duration(minutes: 3))
                  .millisecondsSinceEpoch,
            ),
            'cafe_assistant': ActivityProgress(
              active: true,
              isUnlocked: true,
              firstStartedAtUtc: start
                  .subtract(const Duration(minutes: 2))
                  .millisecondsSinceEpoch,
            ),
            'radio_assistant': ActivityProgress(
              active: true,
              isUnlocked: true,
              firstStartedAtUtc: start
                  .subtract(const Duration(minutes: 1))
                  .millisecondsSinceEpoch,
            ),
          },
        ),
      );
      final storage = MemoryIdleStorage()..value = old.encode();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      expect(controller.state.jobs['neighborhood_deliveries']!.active, isTrue);
      expect(controller.state.availableBlocks, greaterThanOrEqualTo(0));
      expect(
        TimeReservationService.snapshot(controller.state).reserved,
        lessThanOrEqualTo(controller.state.totalBlocks),
      );
    },
  );

  test(
    'backup recupera save principal invÃ¡lido sem quebrar release',
    () async {
      final backup = IdleState.fresh().copyWith(money: 777).encode();
      final storage = RecoverableMemoryIdleStorage()
        ..value = '{save quebrado'
        ..backup = backup;
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      expect(controller.state.money, 777);
      expect(controller.lastMigrationReport!.backupUsed, isTrue);
      expect(
        controller.lastMigrationReport!.recoveredFromInvalidSource,
        isTrue,
      );
    },
  );

  test(
    'arquivo totalmente invÃ¡lido sem backup cria estado novo seguro',
    () async {
      final storage = MemoryIdleStorage()..value = 'nÃ£o-json';
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      expect(controller.state.jobs.keys.toList(), jobIds);
      expect(controller.state.money, 0);
      expect(
        controller.lastMigrationReport!.recoveredFromInvalidSource,
        isTrue,
      );
    },
  );

  test(
    'migraÃ§Ã£o Ã© idempotente e nÃ£o repete offline apÃ³s resave',
    () async {
      final start = DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 12))
          .millisecondsSinceEpoch;
      final storage = MemoryIdleStorage()
        ..value = jsonEncode({
          'version': 4,
          'money': 0,
          'lastSavedAt': start,
          'jobs': {
            'neighborhood_deliveries': {
              'level': 1,
              'active': true,
              'isUnlocked': true,
              'lastProcessedAtUtc': start,
            },
          },
        });
      final first = GameController(storage);
      await first.initialize();
      final firstMoney = first.state.money;
      first.dispose();

      final second = GameController(storage);
      await second.initialize();
      addTearDown(second.dispose);

      expect(firstMoney, greaterThanOrEqualTo(12));
      expect(second.state.money, firstMoney);
      expect(second.takeOfflineSummary(), isNull);
    },
  );
}
