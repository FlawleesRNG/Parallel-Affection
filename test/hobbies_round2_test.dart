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

Map<String, ActivityProgress> _freshHobbies({
  Iterable<String> active = const [],
  Map<String, ActivityProgress> overrides = const {},
  int? startedAt,
}) => {
  for (final hobby in IdleBalance.hobbies)
    hobby.id:
        overrides[hobby.id] ??
        ActivityProgress(
          active: active.contains(hobby.id),
          isUnlocked: hobby.initialAvailability,
          cycleStartedAt: active.contains(hobby.id) ? startedAt ?? 0 : 0,
          lastProcessedAtUtc: active.contains(hobby.id) ? startedAt ?? 0 : 0,
          firstStartedAtUtc: active.contains(hobby.id) ? startedAt ?? 0 : 0,
          hasBeenStarted: active.contains(hobby.id),
        ),
};

void main() {
  test('dez hobbies funcionam no mesmo runtime com progresso independente', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _freshHobbies(
        active: ['leitura', 'academia', 'teatro'],
        startedAt: start.millisecondsSinceEpoch,
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(seconds: 10)),
    );

    expect(result.state.hobbies['leitura']!.experience, 2);
    expect(result.state.hobbies['academia']!.experience, 2);
    expect(result.state.hobbies['teatro']!.experience, 2);
    expect(result.state.hobbies['meditacao']!.experience, 0);
    expect(
      result.summary.hobbyEvents.keys,
      containsAll(['leitura', 'academia', 'teatro']),
    );
  });

  test(
    'desbloqueios oficiais ocorrem e não iniciam treino automaticamente',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetHobbyLevel('leitura', 2);
      expect(controller.state.hobbies['musica']!.isUnlocked, isTrue);
      expect(controller.state.hobbies['musica']!.active, isFalse);

      await controller.debugSetHobbyLevel('meditacao', 2);
      expect(controller.state.hobbies['culinaria']!.isUnlocked, isTrue);
      expect(controller.state.hobbies['culinaria']!.active, isFalse);

      await controller.debugSetHobbyLevel('leitura', 3);
      expect(controller.state.hobbies['fotografia']!.isUnlocked, isTrue);
      expect(controller.state.hobbies['fotografia']!.active, isFalse);

      await controller.debugSetHobbyLevel('teatro', 3);
      expect(controller.state.hobbies['oratoria']!.isUnlocked, isTrue);
      expect(controller.state.hobbies['oratoria']!.active, isFalse);

      await controller.debugSetHobbyLevel('leitura', 4);
      expect(controller.state.hobbies['programacao']!.isUnlocked, isTrue);
      expect(controller.state.hobbies['programacao']!.active, isFalse);
    },
  );

  test(
    'Tempo compartilhado permite job+hobbies e falha sem reserva parcial',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
      await controller.toggle(ActivityKind.hobby, 'leitura');
      await controller.toggle(ActivityKind.hobby, 'academia');
      expect(TimeReservationService.snapshot(controller.state).available, 0);

      final fail = await controller.toggle(ActivityKind.hobby, 'teatro');
      expect(fail.message, contains('Tempo'));
      expect(controller.state.hobbies['teatro']!.active, isFalse);
      expect(TimeReservationService.snapshot(controller.state).available, 0);

      await controller.toggle(ActivityKind.hobby, 'leitura');
      expect(controller.state.jobs['neighborhood_deliveries']!.active, isTrue);
      expect(controller.state.hobbies['academia']!.active, isTrue);
      expect(TimeReservationService.snapshot(controller.state).available, 2);
    },
  );

  test(
    'nível 5 reduz reserva ativa de 2 para 1 e domínio remove reserva',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.toggle(ActivityKind.hobby, 'leitura');
      await controller.toggle(ActivityKind.hobby, 'academia');
      expect(TimeReservationService.snapshot(controller.state).reserved, 4);

      await controller.debugSetHobbyLevel('leitura', 5);
      expect(controller.state.hobbies['leitura']!.active, isTrue);
      expect(
        TimeReservationService.reservedByHobby(controller.state, 'leitura'),
        1,
      );
      expect(TimeReservationService.snapshot(controller.state).reserved, 3);

      await controller.debugSetHobbyLevel('leitura', 10);
      final leitura = controller.state.hobbies['leitura']!;
      expect(leitura.level, 10);
      expect(leitura.active, isFalse);
      expect(leitura.experience, 0);
      expect(
        TimeReservationService.reservedByHobby(controller.state, 'leitura'),
        0,
      );
      expect(controller.state.hobbies['academia']!.active, isTrue);
    },
  );

  test('feedbacks de Hobby vêm do runtime central', () async {
    final controller = GameController(_MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.debugCompleteHobbyCycle('leitura');

    final feedback = controller.hobbyFeedbacks['leitura'];
    expect(feedback, isNotNull);
    expect(feedback!.xpEarned, 2);
    expect(feedback.cyclesCompleted, 1);
    expect(feedback.resultingLevel, 1);
  });

  test(
    'requisitos oficiais de Emprego consultam níveis reais de Hobby',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetHobbyLevel('videogames', 2);
      await controller.debugSetHobbyLevel('academia', 3);
      await controller.debugSetHobbyLevel('fotografia', 4);
      await controller.debugSetHobbyLevel('oratoria', 6);
      await controller.debugSetHobbyLevel('musica', 4);
      await controller.debugSetHobbyLevel('programacao', 6);
      await controller.debugSetHobbyLevel('teatro', 7);

      final checks = {
        'game_store': ['videogames'],
        'gym_reception': ['academia'],
        'freelance_photography': ['fotografia'],
        'radio_assistant': ['oratoria', 'musica'],
        'freelance_programmer': ['programacao'],
        'event_producer': ['teatro', 'oratoria'],
      };

      for (final entry in checks.entries) {
        final evaluation = JobRequirementEvaluator.evaluate(
          controller.state,
          IdleBalance.job(entry.key),
        );
        for (final hobbyId in entry.value) {
          expect(
            evaluation.requirements
                .firstWhere((item) => item.targetId == hobbyId)
                .isMet,
            isTrue,
            reason: '${entry.key} exige $hobbyId',
          );
        }
      }

      expect(
        JobRequirementEvaluator.evaluate(
          controller.state,
          IdleBalance.job('event_producer'),
        ).requirementsMet,
        isFalse,
        reason: 'Hobby sozinho não deve ignorar dinheiro/emprego exigidos.',
      );
    },
  );

  test(
    'ROOT Tempo infinito aceita Empregos e Hobbies sem corromper logout',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetRootPrivileges(timeInfinite: true);
      await controller.toggle(ActivityKind.job, 'neighborhood_deliveries');
      for (final id in [
        'leitura',
        'academia',
        'teatro',
        'meditacao',
        'videogames',
      ]) {
        await controller.toggle(ActivityKind.hobby, id);
      }
      expect(controller.state.jobs['neighborhood_deliveries']!.active, isTrue);
      expect(
        [
          'leitura',
          'academia',
          'teatro',
          'meditacao',
          'videogames',
        ].every((id) => controller.state.hobbies[id]!.active),
        isTrue,
      );

      await controller.debugSetRootPrivileges(timeInfinite: false);
      expect(
        TimeReservationService.snapshot(controller.state).available,
        greaterThanOrEqualTo(0),
      );
      expect(
        TimeReservationService.snapshot(controller.state).reserved,
        lessThanOrEqualTo(controller.state.totalBlocks),
      );
    },
  );
}
