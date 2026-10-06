import '../core/character_catalog.dart';
import '../core/idle_rules.dart';
import '../core/player_skill_service.dart';
import '../data/idle_balance.dart';
import '../data/date_locations.dart';
import '../models/idle_models.dart';
import 'activity_runtime_service.dart';

class SimulationSummary {
  const SimulationSummary({
    this.elapsed = Duration.zero,
    this.actualAwayDuration = Duration.zero,
    this.discardedByLimit = Duration.zero,
    this.money = 0,
    this.affection = 0,
    this.jobExperience = 0,
    this.hobbyExperience = 0,
    this.jobLevels = 0,
    this.hobbyLevels = 0,
    this.totalContinuousPayments = 0,
    this.jobsThatProgressed = 0,
    this.jobsReachedMaximumLevel = 0,
    this.hobbiesThatProgressed = 0,
    this.hobbiesReachedMaximumLevel = 0,
    this.boostsExpired = 0,
    this.jobEvents = const {},
    this.hobbyEvents = const {},
    this.playerSkillEvents = const [],
    this.jobUnlocks = const [],
    this.hobbyUnlocks = const [],
    this.unlocked = const [],
  });
  final Duration elapsed;
  final Duration actualAwayDuration;
  final Duration discardedByLimit;
  final int money,
      affection,
      jobExperience,
      hobbyExperience,
      jobLevels,
      hobbyLevels;
  final int totalContinuousPayments;
  final int jobsThatProgressed;
  final int jobsReachedMaximumLevel;
  final int hobbiesThatProgressed;
  final int hobbiesReachedMaximumLevel;
  final int boostsExpired;
  final Map<String, JobRuntimeResult> jobEvents;
  final Map<String, HobbyRuntimeResult> hobbyEvents;
  final List<PlayerSkillLevelChange> playerSkillEvents;
  final List<String> jobUnlocks;
  final List<String> hobbyUnlocks;
  final List<String> unlocked;
  int get totalJobCompletions => jobEvents.values.fold(
    0,
    (total, result) => total + result.cyclesCompleted,
  );
  int get totalHobbyTrainingCompletions => hobbyEvents.values.fold(
    0,
    (total, result) => total + result.cyclesCompleted,
  );
  bool get hasChanges =>
      money > 0 ||
      affection > 0 ||
      jobExperience > 0 ||
      hobbyExperience > 0 ||
      jobLevels > 0 ||
      hobbyLevels > 0 ||
      totalContinuousPayments > 0 ||
      jobsThatProgressed > 0 ||
      jobsReachedMaximumLevel > 0 ||
      hobbiesThatProgressed > 0 ||
      hobbiesReachedMaximumLevel > 0 ||
      boostsExpired > 0 ||
      jobEvents.isNotEmpty ||
      hobbyEvents.isNotEmpty ||
      playerSkillEvents.isNotEmpty ||
      jobUnlocks.isNotEmpty ||
      hobbyUnlocks.isNotEmpty ||
      unlocked.isNotEmpty;

  SimulationSummary copyWith({
    List<String>? jobUnlocks,
    List<String>? hobbyUnlocks,
  }) => SimulationSummary(
    elapsed: elapsed,
    actualAwayDuration: actualAwayDuration,
    discardedByLimit: discardedByLimit,
    money: money,
    affection: affection,
    jobExperience: jobExperience,
    hobbyExperience: hobbyExperience,
    jobLevels: jobLevels,
    hobbyLevels: hobbyLevels,
    totalContinuousPayments: totalContinuousPayments,
    jobsThatProgressed: jobsThatProgressed,
    jobsReachedMaximumLevel: jobsReachedMaximumLevel,
    hobbiesThatProgressed: hobbiesThatProgressed,
    hobbiesReachedMaximumLevel: hobbiesReachedMaximumLevel,
    boostsExpired: boostsExpired,
    jobEvents: jobEvents,
    hobbyEvents: hobbyEvents,
    playerSkillEvents: playerSkillEvents,
    jobUnlocks: jobUnlocks ?? this.jobUnlocks,
    hobbyUnlocks: hobbyUnlocks ?? this.hobbyUnlocks,
    unlocked: unlocked,
  );
}

class SimulationResult {
  const SimulationResult(this.state, this.summary);
  final IdleState state;
  final SimulationSummary summary;
}

class SimulationService {
  SimulationResult advance(
    IdleState initial,
    DateTime now, {
    bool offline = false,
  }) {
    final nowMs = now.millisecondsSinceEpoch;
    final started = DateTime.fromMillisecondsSinceEpoch(
      initial.lastSavedAt == 0 ? nowMs : initial.lastSavedAt,
      isUtc: true,
    );
    final startedMs = started.millisecondsSinceEpoch;
    final rawElapsed = now.difference(started);
    final safeRawElapsed = rawElapsed.isNegative ? Duration.zero : rawElapsed;
    final elapsed =
        offline && safeRawElapsed > IdleBalance.defaultJobOfflineLimit
        ? IdleBalance.defaultJobOfflineLimit
        : safeRawElapsed;
    final discardedByLimit = offline && safeRawElapsed > elapsed
        ? safeRawElapsed - elapsed
        : Duration.zero;
    var state = _withCanonicalCharacters(initial);
    var money = 0;
    var passiveAffection = 0;
    var jobExperience = 0;
    var hobbyExperience = 0;
    var jobLevels = 0;
    var totalContinuousPayments = 0;
    var jobsThatProgressed = 0;
    var jobsReachedMaximumLevel = 0;
    var hobbiesThatProgressed = 0;
    var hobbiesReachedMaximumLevel = 0;
    var boostsExpired = 0;
    var hobbyLevels = 0;
    final jobEvents = <String, JobRuntimeResult>{};
    final hobbyEvents = <String, HobbyRuntimeResult>{};
    final jobs = {...state.jobs};
    for (final definition in IdleBalance.jobs) {
      final progress = jobs[definition.id] ?? const ActivityProgress();
      final isUnlocked =
          progress.isUnlocked || IdleRules.jobUnlocked(state, definition.id);
      if (!progress.active || !isUnlocked) continue;
      final effectiveProgress =
          offline &&
              progress.lastProcessedAtUtc > 0 &&
              progress.lastProcessedAtUtc < startedMs
          ? progress.copyWith(isUnlocked: true, lastProcessedAtUtc: startedMs)
          : progress.copyWith(isUnlocked: true);
      final initialLevel = effectiveProgress.level;
      final result = ActivityRuntimeService.processJob(
        job: definition,
        progress: effectiveProgress,
        state: state,
        now: now,
        fallbackStartedAt: startedMs,
        offline: offline,
      );
      if (result.cyclesCompleted <= 0 && result.progress == progress) continue;
      jobLevels += result.levelsGained;
      jobExperience += result.xpEarned;
      money += result.moneyEarned;
      totalContinuousPayments += result.continuousPaymentsCompleted;
      if (result.moneyEarned > 0 ||
          result.xpEarned > 0 ||
          result.cyclesCompleted > 0 ||
          result.levelsGained > 0 ||
          result.boostExpired) {
        jobsThatProgressed++;
      }
      if (initialLevel < definition.maximumLevel &&
          result.progress.level >= definition.maximumLevel) {
        jobsReachedMaximumLevel++;
      }
      if (result.boostExpired) boostsExpired++;
      jobs[definition.id] = result.progress;
      if (result.cyclesCompleted > 0 ||
          result.levelsGained > 0 ||
          result.boostExpired) {
        jobEvents[definition.id] = result;
      }
    }
    final hobbies = {...state.hobbies};
    final hobbiesBeforeProcessing = {...hobbies};
    final unlockedHobbiesBeforeProcessing = hobbies.entries
        .where((entry) => entry.value.isUnlocked)
        .map((entry) => entry.key)
        .toSet();
    for (final definition in IdleBalance.hobbies) {
      final progress = hobbies[definition.id] ?? const ActivityProgress();
      final isUnlocked =
          progress.isUnlocked || IdleRules.hobbyUnlocked(state, definition.id);
      if (!progress.active || !isUnlocked) continue;
      final effectiveProgress =
          offline &&
              progress.lastProcessedAtUtc > 0 &&
              progress.lastProcessedAtUtc < startedMs
          ? progress.copyWith(isUnlocked: true, lastProcessedAtUtc: startedMs)
          : progress.copyWith(isUnlocked: true);
      final initialLevel = effectiveProgress.level;
      final result = ActivityRuntimeService.processHobby(
        hobby: definition,
        progress: effectiveProgress,
        state: state,
        now: now,
        fallbackStartedAt: startedMs,
        offline: offline,
      );
      if (result.cyclesCompleted <= 0 && result.progress == progress) {
        continue;
      }
      hobbyLevels += result.levelsGained;
      hobbyExperience += result.xpEarned;
      if (result.xpEarned > 0 ||
          result.cyclesCompleted > 0 ||
          result.levelsGained > 0 ||
          result.boostExpired ||
          result.boostEndedByMastery) {
        hobbiesThatProgressed++;
      }
      if (initialLevel < definition.maximumLevel &&
          result.progress.level >= definition.maximumLevel) {
        hobbiesReachedMaximumLevel++;
      }
      if (result.boostExpired) boostsExpired++;
      hobbies[definition.id] = result.progress;
      if (result.cyclesCompleted > 0 ||
          result.levelsGained > 0 ||
          result.reachedMaximumLevel ||
          result.boostExpired ||
          result.boostEndedByMastery) {
        hobbyEvents[definition.id] = result;
      }
    }
    state = state.copyWith(
      jobs: jobs,
      hobbies: hobbies,
      money: state.money + money,
      totalMoneyEarned: state.totalMoneyEarned + money,
      lastSavedAt: nowMs,
    );
    state = _reconcileHobbyUnlocks(state);
    final hobbyUnlocks = state.hobbies.entries
        .where(
          (entry) =>
              entry.value.isUnlocked &&
              !unlockedHobbiesBeforeProcessing.contains(entry.key),
        )
        .map((entry) => entry.key)
        .toList();
    final playerSkillEvents = PlayerSkillService.deriveLevelChanges(
      before: hobbiesBeforeProcessing,
      after: state.hobbies,
    );
    final passiveCharacters = {...state.characters};
    for (final entry in passiveCharacters.entries) {
      final characterId = PlayableCharacterCatalog.canonicalId(entry.key);
      if (entry.key != characterId) continue;
      final progress = entry.value;
      if (!_canGainPassiveAffection(progress)) {
        continue;
      }
      final intervalMs = IdleBalance.passiveAffectionInterval.inMilliseconds;
      if (intervalMs <= 0) continue;
      final passiveStartedAt = progress.lastPassiveAffectionAt > 0
          ? progress.lastPassiveAffectionAt
          : startedMs;
      final rawPassiveElapsedMs = nowMs - passiveStartedAt;
      final passiveElapsedMs = offline
          ? rawPassiveElapsedMs.clamp(
              0,
              IdleBalance.offlineLimit.inMilliseconds,
            )
          : rawPassiveElapsedMs.clamp(0, 1 << 62);
      final cycles = (passiveElapsedMs / intervalMs).floor();
      if (cycles <= 0) {
        passiveCharacters[characterId] = progress.copyWith(
          lastPassiveAffectionAt: passiveStartedAt,
        );
        continue;
      }
      final rawGain = cycles * IdleBalance.passiveAffectionReward;
      final gain = _passiveAffectionGain(progress, rawGain);
      if (gain <= 0) continue;
      passiveAffection += gain;
      final processedUntil = offline
          ? nowMs
          : passiveStartedAt + cycles * intervalMs;
      passiveCharacters[characterId] = progress.copyWith(
        affection: progress.affection + gain,
        lifetimeAffection: progress.lifetimeAffection + gain,
        lastPassiveAffectionAt: processedUntil,
      );
    }
    if (passiveCharacters[PlayableCharacterIds.roxanne] case final roxanne?) {
      passiveCharacters[PlayableCharacterIds.legacyRyomi] = roxanne;
    }
    state = state.copyWith(characters: passiveCharacters);
    if (state.activeEncounter case final encounter?) {
      final location = DateLocationCatalog.maybeById(encounter.locationId);
      final endsAt = encounter.endsAt;
      if (location == null) {
        // Unknown IDs are discarded safely instead of crashing a recovered save.
        state = state.copyWith(clearEncounter: true);
      } else if (endsAt != null && nowMs >= endsAt) {
        final characters = {...state.characters};
        final characterId = PlayableCharacterCatalog.canonicalId(
          encounter.characterId,
        );
        final old = characters[characterId]!;
        final updated = old.copyWith(encounters: old.encounters + 1);
        characters[characterId] = updated;
        if (characterId == PlayableCharacterIds.roxanne) {
          characters[PlayableCharacterIds.legacyRyomi] = updated;
        }
        final progress = {
          for (final entry in state.dateProgressByCharacter.entries)
            entry.key: {...entry.value},
        };
        final characterProgress = {
          ...(progress[characterId] ?? const <String, int>{}),
        };
        characterProgress[location.id] =
            (characterProgress[location.id] ?? 0) + 1;
        progress[characterId] = characterProgress;
        state = state.copyWith(
          characters: characters,
          dateProgressByCharacter: progress,
          clearEncounter: true,
        );
      }
    }
    final before = state.characters.entries
        .where((item) => item.value.unlocked)
        .map((item) => item.key)
        .toSet();
    final characters = {...state.characters};
    for (final id in characters.keys) {
      if (id != PlayableCharacterCatalog.canonicalId(id)) continue;
      if (IdleRules.characterUnlocked(state, id))
        characters[id] = characters[id]!.copyWith(unlocked: true);
    }
    if (characters[PlayableCharacterIds.roxanne] case final roxanne?) {
      characters[PlayableCharacterIds.legacyRyomi] = roxanne;
    }
    state = state.copyWith(characters: characters);
    final added = characters.entries
        .where((item) => item.value.unlocked && !before.contains(item.key))
        .map((item) => item.key)
        .toList();
    return SimulationResult(
      _evaluateAchievements(state),
      SimulationSummary(
        elapsed: elapsed,
        actualAwayDuration: safeRawElapsed,
        discardedByLimit: discardedByLimit,
        money: money,
        affection: passiveAffection,
        jobExperience: jobExperience,
        hobbyExperience: hobbyExperience,
        jobLevels: jobLevels,
        hobbyLevels: hobbyLevels,
        totalContinuousPayments: totalContinuousPayments,
        jobsThatProgressed: jobsThatProgressed,
        jobsReachedMaximumLevel: jobsReachedMaximumLevel,
        hobbiesThatProgressed: hobbiesThatProgressed,
        hobbiesReachedMaximumLevel: hobbiesReachedMaximumLevel,
        boostsExpired: boostsExpired,
        jobEvents: jobEvents,
        hobbyEvents: hobbyEvents,
        playerSkillEvents: playerSkillEvents,
        hobbyUnlocks: hobbyUnlocks,
        unlocked: added,
      ),
    );
  }

  bool _canGainPassiveAffection(CharacterProgress progress) {
    if (!progress.unlocked ||
        progress.stage < IdleBalance.passiveAffectionUnlockStage) {
      return false;
    }
    final finalStage = IdleRules.totalRelationshipStages - 1;
    if (progress.stage < finalStage) return true;
    return progress.affection < IdleBalance.affectionNeeded(progress.stage);
  }

  int _passiveAffectionGain(CharacterProgress progress, int rawGain) {
    final finalStage = IdleRules.totalRelationshipStages - 1;
    if (progress.stage < finalStage) return rawGain;
    final remaining =
        IdleBalance.affectionNeeded(progress.stage) - progress.affection;
    return rawGain.clamp(0, remaining);
  }

  IdleState _withCanonicalCharacters(IdleState state) {
    final characters = {...state.characters};
    final roxanne =
        characters[PlayableCharacterIds.roxanne] ??
        characters[PlayableCharacterIds.legacyRyomi];
    if (roxanne != null) {
      characters[PlayableCharacterIds.roxanne] = roxanne;
      characters[PlayableCharacterIds.legacyRyomi] = roxanne;
    }
    characters.putIfAbsent(
      PlayableCharacterIds.kai,
      () => const CharacterProgress(unlocked: true),
    );
    return state.copyWith(characters: characters);
  }

  IdleState _reconcileHobbyUnlocks(IdleState state) {
    final hobbies = {...state.hobbies};
    var changed = false;
    for (final hobby in IdleBalance.hobbies) {
      final current = hobbies[hobby.id] ?? const ActivityProgress();
      final shouldUnlock =
          hobby.initialAvailability ||
          current.isUnlocked ||
          IdleRules.requirementsMet(
            state.copyWith(hobbies: hobbies),
            hobby.requires,
          );
      final shouldStop = current.level >= hobby.maximumLevel;
      final updated = current.copyWith(
        isUnlocked: shouldUnlock,
        active: shouldStop ? false : current.active,
        experience: shouldStop ? 0 : current.experience,
        accumulatedCycleProgressMs: shouldStop
            ? 0
            : current.accumulatedCycleProgressMs,
        cycleStartedAt: shouldStop ? 0 : current.cycleStartedAt,
      );
      if (updated.toJson().toString() != current.toJson().toString()) {
        hobbies[hobby.id] = updated;
        changed = true;
      }
    }
    return changed ? state.copyWith(hobbies: hobbies) : state;
  }

  IdleState _evaluateAchievements(IdleState state) {
    final unlocked = {...state.achievements};
    var diamonds = state.diamonds;
    var blocks = state.totalBlocks;
    void grant(
      String id,
      bool condition, {
      int diamondsReward = 0,
      int blocksReward = 0,
    }) {
      if (condition && unlocked.add(id)) {
        diamonds += diamondsReward;
        blocks += blocksReward;
      }
    }

    final jobCycles = state.jobs.values.fold(
      0,
      (sum, item) => sum + item.cycles,
    );
    final hobbyTop = state.hobbies.values.fold(
      1,
      (top, item) => item.level > top ? item.level : top,
    );
    grant('ciclos_100', jobCycles >= 100, diamondsReward: 2);
    grant('hobby_10', hobbyTop >= 10, diamondsReward: 5);
    grant(
      'primeira_promocao',
      state.jobs.values.any((item) => item.level >= 2),
      diamondsReward: 1,
    );
    grant(
      'ryomi_primeira_conexao',
      (state.characters[PlayableCharacterIds.roxanne]?.stage ?? 0) >= 2,
      diamondsReward: 3,
    );
    grant(
      'presentes_100',
      state.characters.values.fold(0, (sum, item) => sum + item.gifts) >= 100,
      blocksReward: 1,
    );
    grant(
      'encontros_10',
      state.characters.values.fold(0, (sum, item) => sum + item.encounters) >=
          10,
      diamondsReward: 5,
    );
    return state.copyWith(
      achievements: unlocked,
      diamonds: diamonds,
      totalBlocks: blocks,
    );
  }
}
