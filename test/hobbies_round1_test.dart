import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/job_requirement_evaluator.dart';
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

Map<String, ActivityProgress> _hobbies({
  Map<String, ActivityProgress> overrides = const {},
}) => {
  for (final id in hobbyIds)
    id:
        overrides[id] ??
        ActivityProgress(isUnlocked: IdleBalance.hobby(id).initialAvailability),
};

void main() {
  test(
    'catálogo definitivo de hobbies possui IDs, ordem e tabelas oficiais',
    () {
      const expectedIds = [
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
      ];

      expect(IdleBalance.hobbies.map((item) => item.id).toList(), expectedIds);
      expect(
        IdleBalance.hobbies.map((item) => item.displayOrder).toList(),
        List<int>.generate(10, (index) => index + 1),
      );
      expect(IdleBalance.validateHobbyCatalog(), isEmpty);
      expect(IdleBalance.maximumHobbyLevel, 10);
      expect(IdleBalance.hobbyXpPerTrainingCycle, 2);
      expect(IdleBalance.baseHobbyTrainingDurationsByLevel, const [
        Duration(seconds: 10),
        Duration(seconds: 9),
        Duration(seconds: 8),
        Duration(seconds: 7),
        Duration(seconds: 6),
        Duration(seconds: 5),
        Duration(seconds: 4),
        Duration(seconds: 3),
        Duration(seconds: 2),
        Duration(seconds: 1),
      ]);
      expect(IdleBalance.baseHobbyTimeCostsByLevel, [
        2,
        2,
        2,
        2,
        1,
        1,
        1,
        1,
        1,
        0,
      ]);
      for (final hobby in IdleBalance.hobbies) {
        expect(hobby.maximumLevel, 10, reason: hobby.id);
        expect(hobby.trainingDurationsByLevel, hasLength(10), reason: hobby.id);
        expect(hobby.timeCostsByLevel, hasLength(10), reason: hobby.id);
        expect(hobby.timeCostAtLevel(5), 1, reason: hobby.id);
        expect(hobby.timeCostAtLevel(10), 0, reason: hobby.id);
        expect(IdleBalance.hobbyXpNeeded(hobby, 1), 10, reason: hobby.id);
        expect(IdleBalance.hobbyXpNeeded(hobby, 10), 0, reason: hobby.id);
      }
    },
  );

  test('hobbies iniciais, bloqueados, requisitos e aliases legados', () {
    final initial = IdleState.fresh();
    expect(hobbyIds.where((id) => initial.hobbies[id]!.isUnlocked).toList(), [
      'leitura',
      'academia',
      'teatro',
      'meditacao',
      'videogames',
    ]);
    expect(hobbyIds.where((id) => !initial.hobbies[id]!.isUnlocked).toList(), [
      'musica',
      'culinaria',
      'fotografia',
      'oratoria',
      'programacao',
    ]);
    expect(IdleBalance.hobby('musica').requires, {'hobby:leitura': 2});
    expect(IdleBalance.hobby('culinaria').requires, {'hobby:meditacao': 2});
    expect(IdleBalance.hobby('fotografia').requires, {'hobby:leitura': 3});
    expect(IdleBalance.hobby('oratoria').requires, {'hobby:teatro': 3});
    expect(IdleBalance.hobby('programacao').requires, {'hobby:leitura': 4});

    final migrated = IdleState.decode(
      jsonEncode({
        'version': 4,
        'hobbies': {
          'condicionamento': {'level': 3},
          'criatividade': {'level': 4},
          'comunicacao': {'level': 5},
          'tecnologia': {'level': 6},
          'carisma': {'level': 7},
        },
      }),
    );
    expect(migrated.hobbies['academia']!.level, 3);
    expect(migrated.hobbies['fotografia']!.level, 4);
    expect(migrated.hobbies['oratoria']!.level, 5);
    expect(migrated.hobbies['programacao']!.level, 6);
    expect(migrated.hobbies['teatro']!.level, 7);
  });

  test('treino concede XP somente em ciclo completo e preserva parcial', () {
    final service = SimulationService();
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _hobbies(
        overrides: {
          'leitura': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            firstStartedAtUtc: start.millisecondsSinceEpoch,
            hasBeenStarted: true,
          ),
        },
      ),
    );

    final beforeCycle = service.advance(
      state,
      start.add(const Duration(seconds: 9)),
    );
    expect(beforeCycle.summary.hobbyExperience, 0);
    expect(beforeCycle.state.hobbies['leitura']!.experience, 0);
    expect(
      beforeCycle.state.hobbies['leitura']!.accumulatedCycleProgressMs,
      9000,
    );

    final afterCycle = service.advance(
      state,
      start.add(const Duration(seconds: 10)),
    );
    expect(afterCycle.summary.hobbyExperience, 2);
    expect(afterCycle.state.hobbies['leitura']!.experience, 2);
    expect(afterCycle.state.hobbies['leitura']!.cycles, 1);
    expect(afterCycle.state.hobbies['leitura']!.accumulatedCycleProgressMs, 0);
  });

  test(
    'cinco ciclos levam Leitura do nível 1 ao 2 com XP excedente correto',
    () {
      final start = DateTime.utc(2026, 8, 14, 12);
      final state = IdleState.fresh().copyWith(
        lastSavedAt: start.millisecondsSinceEpoch,
        hobbies: _hobbies(
          overrides: {
            'leitura': ActivityProgress(
              active: true,
              isUnlocked: true,
              cycleStartedAt: start.millisecondsSinceEpoch,
              lastProcessedAtUtc: start.millisecondsSinceEpoch,
            ),
          },
        ),
      );

      final result = SimulationService().advance(
        state,
        start.add(const Duration(seconds: 50)),
      );
      final leitura = result.state.hobbies['leitura']!;
      expect(leitura.level, 2);
      expect(leitura.experience, 0);
      expect(leitura.cycles, 5);
      expect(result.state.hobbies['musica']!.isUnlocked, isTrue);
    },
  );

  test('pausar e retomar hobby preserva fração de treino', () async {
    final controller = GameController(_MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.debugProcessHobbyTime(
      'leitura',
      const Duration(seconds: 5),
    );
    await controller.toggle(ActivityKind.hobby, 'leitura');
    expect(controller.state.hobbies['leitura']!.active, isFalse);
    expect(
      controller.state.hobbies['leitura']!.accumulatedCycleProgressMs,
      inInclusiveRange(5000, 5100),
    );
    expect(TimeReservationService.snapshot(controller.state).available, 6);

    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.debugProcessHobbyTime(
      'leitura',
      const Duration(seconds: 5),
    );
    expect(controller.state.hobbies['leitura']!.experience, 2);
    expect(controller.state.hobbies['leitura']!.cycles, 1);
  });

  test(
    'Tempo é compartilhado por emprego e hobbies sem reserva parcial',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
      await controller.toggle(ActivityKind.hobby, 'leitura');
      await controller.toggle(ActivityKind.hobby, 'academia');
      var time = TimeReservationService.snapshot(controller.state);
      expect(time.reserved, 6);
      expect(time.available, 0);

      final result = await controller.toggle(ActivityKind.hobby, 'teatro');
      expect(result.message, contains('Tempo'));
      expect(controller.state.hobbies['teatro']!.active, isFalse);
      time = TimeReservationService.snapshot(controller.state);
      expect(time.reserved, 6);
    },
  );

  test(
    'nível 10 domina hobby, zera XP, libera Tempo e impede nível 11',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetHobbyLevel('leitura', 9);
      await controller.debugAddHobbyXp('leitura', 9999);
      final leitura = controller.state.hobbies['leitura']!;
      expect(leitura.level, 10);
      expect(leitura.experience, 0);
      expect(leitura.active, isFalse);
      expect(leitura.accumulatedCycleProgressMs, 0);
      expect(IdleBalance.hobbyTimeCost('leitura', leitura.level), 0);
    },
  );

  test(
    'hobbies reais satisfazem requisitos de emprego sem ignorar AND',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetHobbyLevel('videogames', 2);
      var evaluation = JobRequirementEvaluator.evaluate(
        controller.state,
        IdleBalance.job('game_store'),
      );
      expect(
        evaluation.requirements
            .firstWhere((item) => item.targetId == 'videogames')
            .isMet,
        isTrue,
      );
      expect(evaluation.isUnlocked, isFalse);

      await controller.debugSetJobLevel('cafe_assistant', 2);
      await controller.debugSetRoxanneProgress(stage: 2);
      evaluation = JobRequirementEvaluator.evaluate(
        controller.state,
        IdleBalance.job('game_store'),
      );
      expect(evaluation.requirementsMet, isTrue);

      await controller.debugSetHobbyLevel('academia', 3);
      expect(
        JobRequirementEvaluator.evaluate(
          controller.state,
          IdleBalance.job('gym_reception'),
        ).requirements.firstWhere((item) => item.targetId == 'academia').isMet,
        isTrue,
      );
      await controller.debugSetHobbyLevel('fotografia', 4);
      await controller.debugSetHobbyLevel('oratoria', 6);
      await controller.debugSetHobbyLevel('musica', 4);
      await controller.debugSetHobbyLevel('programacao', 6);
      await controller.debugSetHobbyLevel('teatro', 7);
      for (final entry in {
        'freelance_photography': 'fotografia',
        'radio_assistant': 'oratoria',
        'freelance_programmer': 'programacao',
        'event_producer': 'teatro',
      }.entries) {
        expect(
          JobRequirementEvaluator.evaluate(
                controller.state,
                IdleBalance.job(entry.key),
              ).requirements
              .firstWhere((item) => item.targetId == entry.value)
              .isMet,
          isTrue,
          reason: entry.key,
        );
      }
    },
  );

  test(
    'save mínimo preserva hobby ativo, XP, desbloqueio e progresso parcial',
    () async {
      final storage = _MemoryIdleStorage();
      final controller = GameController(storage);
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.toggle(ActivityKind.hobby, 'leitura');
      await controller.debugProcessHobbyTime(
        'leitura',
        const Duration(seconds: 5),
      );
      await controller.debugUnlockHobby('musica');
      await controller.debugForceSave();

      final loaded = GameController(storage);
      await loaded.initialize();
      addTearDown(loaded.dispose);

      expect(loaded.state.hobbies['leitura']!.active, isTrue);
      expect(
        loaded.state.hobbies['leitura']!.accumulatedCycleProgressMs,
        inInclusiveRange(5000, 5100),
      );
      expect(loaded.state.hobbies['musica']!.isUnlocked, isTrue);
    },
  );

  test('offline definitivo concede XP a hobby ativo', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _hobbies(
        overrides: {
          'leitura': ActivityProgress(
            active: true,
            isUnlocked: true,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(seconds: 10)),
      offline: true,
    );
    expect(result.summary.hobbyExperience, 2);
    expect(result.summary.hobbyLevels, 0);
    expect(result.summary.totalHobbyTrainingCompletions, 1);
    expect(result.state.hobbies['leitura']!.experience, 2);
    expect(result.state.hobbies['leitura']!.level, 1);
    expect(
      result.state.hobbies['leitura']!.lastProcessedAtUtc,
      start.add(const Duration(seconds: 10)).millisecondsSinceEpoch,
    );
  });
}
