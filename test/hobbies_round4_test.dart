import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/core/player_skill_service.dart';
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

Map<String, ActivityProgress> _jobs({
  Map<String, ActivityProgress> overrides = const {},
}) => {
  for (final id in jobIds)
    id:
        overrides[id] ??
        ActivityProgress(isUnlocked: id == 'neighborhood_deliveries'),
};

void main() {
  test('Hobby pausado não progride offline e conserva boost', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _hobbies(
        overrides: {
          'leitura': ActivityProgress(
            active: false,
            isUnlocked: true,
            experience: 4,
            accumulatedCycleProgressMs: 3000,
            remainingBoostActiveTimeMs: 300000,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(hours: 1)),
      offline: true,
    );

    final leitura = result.state.hobbies['leitura']!;
    expect(result.summary.hobbyExperience, 0);
    expect(result.summary.totalHobbyTrainingCompletions, 0);
    expect(leitura.experience, 4);
    expect(leitura.accumulatedCycleProgressMs, 3000);
    expect(leitura.remainingBoostActiveTimeMs, 300000);
  });

  test('offline aplica level up e usa nova duração do Hobby', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _hobbies(
        overrides: {
          'leitura': ActivityProgress(
            active: true,
            isUnlocked: true,
            experience: 8,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(seconds: 30)),
      offline: true,
    );

    final leitura = result.state.hobbies['leitura']!;
    expect(leitura.level, 2);
    expect(leitura.experience, 4);
    expect(leitura.accumulatedCycleProgressMs, 2000);
    expect(result.summary.hobbyExperience, 6);
    expect(result.summary.totalHobbyTrainingCompletions, 3);
    expect(result.summary.hobbyLevels, 1);
    expect(
      result.summary.playerSkillEvents.single.skillId,
      PlayerSkillId.inteligencia,
    );
    expect(
      PlayerSkillService.getSkillLevel(
        result.state,
        PlayerSkillId.inteligencia,
      ),
      2,
    );
  });

  test('offline segmenta expiração do boost entre x2 e x1', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _hobbies(
        overrides: {
          'leitura': ActivityProgress(
            active: true,
            isUnlocked: true,
            accumulatedCycleProgressMs: 2000,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
            remainingBoostActiveTimeMs: 3000,
            boostReferenceTimestampUtc: start.millisecondsSinceEpoch,
          ),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(seconds: 5)),
      offline: true,
    );

    final leitura = result.state.hobbies['leitura']!;
    expect(leitura.experience, 2);
    expect(leitura.accumulatedCycleProgressMs, 0);
    expect(leitura.remainingBoostActiveTimeMs, 0);
    expect(result.summary.hobbyExperience, 2);
    expect(result.summary.boostsExpired, 1);
    expect(result.summary.hobbyEvents['leitura']!.boostExpired, isTrue);
  });

  test('domínio offline encerra treino, boost e libera Tempo', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _hobbies(
        overrides: {
          'leitura': ActivityProgress(
            active: true,
            isUnlocked: true,
            level: 9,
            experience:
                IdleBalance.hobbyXpNeeded(IdleBalance.hobby('leitura'), 9) - 2,
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
      start.add(const Duration(seconds: 1)),
      offline: true,
    );

    final leitura = result.state.hobbies['leitura']!;
    final reconciled = TimeReservationService.reconcile(result.state).state;
    expect(leitura.level, 10);
    expect(leitura.experience, 0);
    expect(leitura.active, isFalse);
    expect(leitura.remainingBoostActiveTimeMs, 0);
    expect(result.summary.hobbiesReachedMaximumLevel, 1);
    expect(result.summary.hobbyEvents['leitura']!.boostEndedByMastery, isTrue);
    expect(
      PlayerSkillService.isSkillMastered(
        result.state,
        PlayerSkillId.inteligencia,
      ),
      isTrue,
    );
    expect(TimeReservationService.reservedByHobby(reconciled, 'leitura'), 0);
  });

  test('offline respeita cap de 8h e não processa novamente', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final service = SimulationService();
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
    final now = start.add(const Duration(hours: 12));

    final first = service.advance(state, now, offline: true);
    final second = service.advance(first.state, now, offline: true);

    expect(first.summary.elapsed, const Duration(hours: 8));
    expect(first.summary.discardedByLimit, const Duration(hours: 4));
    expect(first.summary.hobbyExperience, greaterThan(0));
    expect(first.state.hobbies['leitura']!.remainingBoostActiveTimeMs, 0);
    expect(second.summary.hobbyExperience, 0);
    expect(second.summary.totalHobbyTrainingCompletions, 0);
  });

  test('level offline desbloqueia Hobby dependente sem treino retroativo', () {
    final start = DateTime.utc(2026, 8, 14, 12);
    final state = IdleState.fresh().copyWith(
      lastSavedAt: start.millisecondsSinceEpoch,
      hobbies: _hobbies(
        overrides: {
          'leitura': ActivityProgress(
            active: true,
            isUnlocked: true,
            experience: 8,
            cycleStartedAt: start.millisecondsSinceEpoch,
            lastProcessedAtUtc: start.millisecondsSinceEpoch,
          ),
          'musica': const ActivityProgress(isUnlocked: false),
        },
      ),
    );

    final result = SimulationService().advance(
      state,
      start.add(const Duration(seconds: 10)),
      offline: true,
    );

    expect(result.state.hobbies['leitura']!.level, 2);
    expect(result.state.hobbies['musica']!.isUnlocked, isTrue);
    expect(result.state.hobbies['musica']!.active, isFalse);
    expect(result.state.hobbies['musica']!.experience, 0);
    expect(result.summary.hobbyUnlocks, contains('musica'));
  });

  test('Hobby offline satisfaz requisito de Emprego sem iniciar Job', () async {
    final storage = _MemoryIdleStorage();
    final start = DateTime.now().toUtc();
    storage.value = IdleState.fresh()
        .copyWith(
          lastSavedAt: start.millisecondsSinceEpoch,
          money: 1000,
          jobs: _jobs(
            overrides: {
              'cafe_assistant': const ActivityProgress(
                level: 2,
                isUnlocked: true,
              ),
            },
          ),
          hobbies: _hobbies(
            overrides: {
              'videogames': ActivityProgress(
                active: true,
                isUnlocked: true,
                experience: 8,
                cycleStartedAt: start.millisecondsSinceEpoch,
                lastProcessedAtUtc: start.millisecondsSinceEpoch,
              ),
            },
          ),
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
        )
        .encode();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);

    final result = await controller.debugSimulateOffline(
      const Duration(seconds: 10),
    );

    expect(controller.state.hobbies['videogames']!.level, 2);
    expect(controller.state.jobs['game_store']!.isUnlocked, isTrue);
    expect(controller.state.jobs['game_store']!.active, isFalse);
    expect(result.summary!.jobUnlocks, contains('game_store'));
  });

  test('save v6 migra aliases de Hobby e não persiste Skills derivadas', () {
    final decoded = IdleState.decodeWithReport(
      jsonEncode({
        'version': 5,
        'money': 777,
        'diamonds': 9,
        'lastSavedAt': DateTime.utc(2026, 8, 14).millisecondsSinceEpoch,
        'hobbies': {
          'carisma': {'level': 4, 'experience': 3},
          'fantasma': {'level': 8},
          'leitura': {'level': 11, 'active': true},
          'academia': {'level': 0, 'experience': -4},
          'tecnologia': {'level': 2, 'remainingBoostActiveTimeMs': -1},
        },
        'skills': {'carisma': 9},
      }),
    );

    expect(decoded.report.fromVersion, 5);
    expect(decoded.report.toVersion, IdleSaveSchema.currentVersion);
    expect(decoded.report.migrated, isTrue);
    expect(decoded.report.aliasesConverted['carisma'], 'teatro');
    expect(decoded.report.aliasesConverted['tecnologia'], 'programacao');
    expect(decoded.report.ignoredUnknownHobbies, contains('fantasma'));
    expect(decoded.report.missingHobbiesCreated, contains('meditacao'));
    expect(decoded.state.hobbies.length, 10);
    expect(decoded.state.hobbies['teatro']!.level, 4);
    expect(decoded.state.hobbies['programacao']!.level, 2);
    expect(decoded.state.hobbies['leitura']!.level, 10);
    expect(decoded.state.hobbies['leitura']!.active, isFalse);
    expect(decoded.state.hobbies['leitura']!.remainingBoostActiveTimeMs, 0);
    expect(decoded.state.hobbies['academia']!.level, 1);
    expect(decoded.state.hobbies['academia']!.experience, 0);
    expect(
      PlayerSkillService.getSkillLevel(decoded.state, PlayerSkillId.carisma),
      4,
    );

    final encoded = jsonDecode(decoded.state.encode()) as Map<String, dynamic>;
    expect(encoded['version'], IdleSaveSchema.currentVersion);
    expect(encoded.containsKey('skills'), isFalse);
    expect(
      (encoded['hobbies'] as Map<String, dynamic>).keys,
      containsAll(hobbyIds),
    );
  });
}
