import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/player_skill_service.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/features/activities/hobbies_view.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/game_storage.dart';
import 'package:projeto_conexoes/services/simulation_service.dart';

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
  for (final hobby in IdleBalance.hobbies)
    hobby.id:
        overrides[hobby.id] ??
        ActivityProgress(isUnlocked: hobby.initialAvailability),
};

Widget _hobbiesApp(GameController controller) => MaterialApp(
  home: Scaffold(body: HobbiesView(controller: controller)),
);

void main() {
  test(
    'catálogo oficial de Skills mapeia os 10 Hobbies sem colidir aliases',
    () {
      expect(PlayerSkillService.validateCatalog(), isEmpty);
      expect(PlayerSkillService.definitions.map((item) => item.key), [
        'inteligencia',
        'condicionamento',
        'carisma',
        'paciencia',
        'estrategia',
        'criatividade_musical',
        'talento_culinario',
        'percepcao',
        'comunicacao',
        'tecnologia',
      ]);
      expect(PlayerSkillService.definitions.map((item) => item.sourceHobbyId), [
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
      expect(PlayerSkillService.byKey('carisma').sourceHobbyId, 'teatro');
      expect(
        IdleState.decode(
          jsonEncode({
            'version': 4,
            'hobbies': {
              'carisma': {'level': 6},
            },
          }),
        ).hobbies['teatro']!.level,
        6,
        reason: 'Alias legado de Hobby continua separado de SkillId carisma.',
      );
    },
  );

  test('nível e domínio de Skill são derivados do Hobby fonte', () {
    final state = IdleState.fresh().copyWith(
      hobbies: _hobbies(
        overrides: {
          'leitura': const ActivityProgress(level: 7, isUnlocked: true),
          'academia': const ActivityProgress(level: 5, isUnlocked: true),
        },
      ),
    );

    expect(
      PlayerSkillService.getSkillLevel(state, PlayerSkillId.inteligencia),
      7,
    );
    expect(
      PlayerSkillService.getSkillLevel(state, PlayerSkillId.condicionamento),
      5,
    );
    expect(
      PlayerSkillService.getSkillLevel(state, PlayerSkillId.carisma),
      1,
      reason: 'Academia não altera Inteligência ou Carisma.',
    );

    final mastered = state.copyWith(
      hobbies: _hobbies(
        overrides: {
          'leitura': const ActivityProgress(level: 10, isUnlocked: true),
        },
      ),
    );
    expect(
      PlayerSkillService.isSkillMastered(mastered, PlayerSkillId.inteligencia),
      isTrue,
    );
  });

  test('Skills não possuem progresso persistido próprio no save', () async {
    final storage = _MemoryIdleStorage();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetHobbyLevel('leitura', 8);
    await controller.debugForceSave();

    final decoded = jsonDecode(storage.value!) as Map<String, dynamic>;
    expect(decoded.containsKey('skills'), isFalse);

    final reloaded = GameController(storage);
    await reloaded.initialize();
    addTearDown(reloaded.dispose);
    expect(
      PlayerSkillService.getSkillLevel(
        reloaded.state,
        PlayerSkillId.inteligencia,
      ),
      8,
    );
  });

  test(
    'compra de boost de Hobby custa 5 Cerejas, é x2 e não empilha',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetResources(diamonds: 5);
      await controller.toggle(ActivityKind.hobby, 'leitura');
      final purchase = await controller.purchaseHobbyBoost('leitura');

      expect(purchase.message, contains('IMPULSO x2'));
      expect(controller.state.diamonds, 0);
      expect(
        controller.state.hobbies['leitura']!.remainingBoostActiveTimeMs,
        IdleBalance.hobbyBoostActiveDuration.inMilliseconds,
      );

      final second = await controller.purchaseHobbyBoost('leitura');
      expect(second.message, contains('não acumula'));
      expect(controller.state.diamonds, 0);
    },
  );

  test('saldo insuficiente não compra boost de Hobby', () async {
    final controller = GameController(_MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetResources(diamonds: 4);
    await controller.toggle(ActivityKind.hobby, 'leitura');
    final result = await controller.purchaseHobbyBoost('leitura');

    expect(result.message, contains('Faltam 1 Cerejas'));
    expect(controller.state.diamonds, 4);
    expect(controller.state.hobbies['leitura']!.remainingBoostActiveTimeMs, 0);
  });

  test('boost x2 acelera ciclos sem dobrar XP por ciclo', () {
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
            remainingBoostActiveTimeMs:
                IdleBalance.hobbyBoostActiveDuration.inMilliseconds,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(seconds: 5)),
    );

    final leitura = result.state.hobbies['leitura']!;
    expect(leitura.cycles, 1);
    expect(leitura.experience, 2);
    expect(result.summary.hobbyExperience, 2);
    expect(
      leitura.remainingBoostActiveTimeMs,
      IdleBalance.hobbyBoostActiveDuration.inMilliseconds - 5000,
    );
  });

  test('expiração segmentada processa parte x2 e restante x1', () {
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
            accumulatedCycleProgressMs: 2000,
            remainingBoostActiveTimeMs: 3000,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(seconds: 5)),
    );

    final leitura = result.state.hobbies['leitura']!;
    expect(leitura.cycles, 1);
    expect(leitura.experience, 2);
    expect(leitura.accumulatedCycleProgressMs, 0);
    expect(leitura.remainingBoostActiveTimeMs, 0);
    expect(result.summary.hobbyEvents['leitura']!.boostExpired, isTrue);
  });

  test('pausa congela boost e retomada volta a consumir', () async {
    final controller = GameController(_MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.debugActivateHobbyBoost('leitura');
    await controller.debugProcessHobbyTime(
      'leitura',
      const Duration(minutes: 1),
    );
    await controller.toggle(ActivityKind.hobby, 'leitura');
    final pausedRemaining =
        controller.state.hobbies['leitura']!.remainingBoostActiveTimeMs;

    await controller.debugProcessHobbyTime(
      'leitura',
      const Duration(minutes: 1),
    );
    expect(
      controller.state.hobbies['leitura']!.remainingBoostActiveTimeMs,
      pausedRemaining,
      reason: 'Hobby pausado não processa nem consome boost.',
    );

    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.debugProcessHobbyTime(
      'leitura',
      const Duration(seconds: 10),
    );
    expect(
      controller.state.hobbies['leitura']!.remainingBoostActiveTimeMs,
      lessThan(pausedRemaining),
    );
  });

  test(
    'domínio durante boost encerra treino, libera boost e não reembolsa',
    () async {
      final controller = GameController(_MemoryIdleStorage());
      await controller.initialize();
      addTearDown(controller.dispose);

      await controller.debugSetResources(diamonds: 5);
      await controller.debugSetHobbyLevel('leitura', 9);
      await controller.debugAddHobbyXp(
        'leitura',
        IdleBalance.hobbyXpNeeded(IdleBalance.hobby('leitura'), 9) - 2,
      );
      await controller.toggle(ActivityKind.hobby, 'leitura');
      final purchase = await controller.purchaseHobbyBoost('leitura');
      expect(purchase.message, contains('IMPULSO x2'));
      expect(controller.state.diamonds, 0);
      final diamondsAfterPurchase = controller.state.diamonds;
      await controller.debugProcessHobbyTime(
        'leitura',
        const Duration(seconds: 1),
      );

      final leitura = controller.state.hobbies['leitura']!;
      expect(leitura.level, 10);
      expect(leitura.active, isFalse);
      expect(leitura.remainingBoostActiveTimeMs, 0);
      expect(
        controller.state.diamonds,
        diamondsAfterPurchase + IdleBalance.hobbyBoostCherryCost,
        reason:
            'O saldo final reflete apenas a conquista hobby_10; o custo do impulso não é reembolsado.',
      );
      expect(controller.state.achievements, contains('hobby_10'));
      expect(controller.hobbyFeedbacks['leitura']!.reachedMaximumLevel, isTrue);
    },
  );

  test('ROOT Cerejas Infinitas compra boost sem alterar saldo real', () async {
    final controller = GameController(_MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetResources(diamonds: 1);
    await controller.debugSetRootPrivileges(cherriesInfinite: true);
    await controller.toggle(ActivityKind.hobby, 'leitura');
    await controller.purchaseHobbyBoost('leitura');

    expect(controller.state.diamonds, 1);
    expect(
      controller.state.hobbies['leitura']!.remainingBoostActiveTimeMs,
      IdleBalance.hobbyBoostActiveDuration.inMilliseconds,
    );
  });

  test('período fechado consome boost e concede XP de Hobby ativo', () {
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
            remainingBoostActiveTimeMs: 300000,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(minutes: 5)),
      offline: true,
    );

    final leitura = result.state.hobbies['leitura']!;
    expect(leitura.experience, greaterThan(0));
    expect(leitura.remainingBoostActiveTimeMs, 0);
    expect(result.summary.hobbyExperience, greaterThan(0));
    expect(result.summary.boostsExpired, 1);
  });

  testWidgets('UI de Hobbies confirma e cancela boost dentro do card', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = GameController(_MemoryIdleStorage());
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.debugSetResources(diamonds: 5);
    await controller.toggle(ActivityKind.hobby, 'leitura');
    await tester.pumpWidget(_hobbiesApp(controller));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.local_florist_rounded).first);
    await tester.pump();
    expect(find.text('APRIMORAR LEITURA?'), findsOneWidget);

    await tester.tap(find.text('CANCELAR'));
    await tester.pump();
    expect(controller.state.diamonds, 5);
    expect(controller.state.hobbies['leitura']!.upgraded, isFalse);

    await tester.tap(find.byIcon(Icons.local_florist_rounded).first);
    await tester.pump();
    await tester.tap(find.text('APRIMORAR'));
    await tester.pump();
    expect(controller.state.diamonds, 0);
    expect(controller.state.hobbies['leitura']!.upgraded, isTrue);
    expect(find.text('Impulsos'), findsNothing);
  });
}
