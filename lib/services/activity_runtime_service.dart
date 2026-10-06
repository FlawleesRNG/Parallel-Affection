import 'dart:math' as math;

import '../data/idle_balance.dart';
import '../models/idle_models.dart';

class JobRuntimeResult {
  const JobRuntimeResult({
    required this.progress,
    this.moneyEarned = 0,
    this.xpEarned = 0,
    this.cyclesCompleted = 0,
    this.continuousPaymentsCompleted = 0,
    this.levelsGained = 0,
    this.boostExpired = false,
    this.boostActiveTimeConsumedMs = 0,
  });

  final ActivityProgress progress;
  final int moneyEarned;
  final int xpEarned;
  final int cyclesCompleted;
  final int continuousPaymentsCompleted;
  final int levelsGained;
  final bool boostExpired;
  final int boostActiveTimeConsumedMs;
}

class HobbyRuntimeResult {
  const HobbyRuntimeResult({
    required this.progress,
    this.xpEarned = 0,
    this.cyclesCompleted = 0,
    this.levelsGained = 0,
    this.reachedMaximumLevel = false,
    this.boostExpired = false,
    this.boostEndedByMastery = false,
    this.boostActiveTimeConsumedMs = 0,
  });

  final ActivityProgress progress;
  final int xpEarned;
  final int cyclesCompleted;
  final int levelsGained;
  final bool reachedMaximumLevel;
  final bool boostExpired;
  final bool boostEndedByMastery;
  final int boostActiveTimeConsumedMs;
}

abstract final class ActivityRuntimeService {
  static const int experiencePerCycle = 10;

  static int effectiveCycleMillis({
    required int baseSeconds,
    required IdleState state,
  }) {
    final speed = state.speedMultiplier * state.prestigeBonus;
    if (speed <= 0) return baseSeconds * 1000;
    return math.max(1, ((baseSeconds * 1000) / speed).round());
  }

  static int effectiveJobCycleMillis({
    required JobDefinition job,
    required int level,
    required IdleState state,
  }) {
    final duration = job.cycleDurationAtLevel(level);
    final speed = state.speedMultiplier * state.prestigeBonus;
    if (speed <= 0) return duration.inMilliseconds;
    return math.max(1, (duration.inMilliseconds / speed).round());
  }

  static int baseJobCycleMillis({
    required JobDefinition job,
    required int level,
  }) => math.max(1, job.cycleDurationAtLevel(level).inMilliseconds);

  static int baseHobbyCycleMillis({
    required HobbyDefinition hobby,
    required int level,
  }) => math.max(1, hobby.trainingDurationAtLevel(level).inMilliseconds);

  static HobbyRuntimeResult processHobby({
    required HobbyDefinition hobby,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
    required int fallbackStartedAt,
    bool offline = false,
  }) {
    if (!progress.active || progress.level >= hobby.maximumLevel) {
      return HobbyRuntimeResult(
        progress: progress.copyWith(
          active: progress.level >= hobby.maximumLevel
              ? false
              : progress.active,
          experience: progress.level >= hobby.maximumLevel
              ? 0
              : progress.experience,
          accumulatedCycleProgressMs: progress.level >= hobby.maximumLevel
              ? 0
              : progress.accumulatedCycleProgressMs,
          remainingBoostActiveTimeMs: progress.level >= hobby.maximumLevel
              ? 0
              : _safeBoostMs(progress.remainingBoostActiveTimeMs),
          boostReferenceTimestampUtc:
              progress.level >= hobby.maximumLevel ||
                  progress.remainingBoostActiveTimeMs <= 0
              ? 0
              : progress.boostReferenceTimestampUtc,
        ),
      );
    }
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    final startedAt = progress.lastProcessedAtUtc > 0
        ? progress.lastProcessedAtUtc
        : activityStartedAt(
            progress: progress,
            fallbackStartedAt: fallbackStartedAt,
          );
    final rawElapsedMs = math.max(0, nowMs - startedAt);
    final elapsedMs = offline
        ? math.min(
            rawElapsedMs,
            IdleBalance.defaultJobOfflineLimit.inMilliseconds,
          )
        : rawElapsedMs;
    final startingLevel = progress.level.clamp(1, hobby.maximumLevel);
    final globalSpeed = _globalJobSpeed(state);
    var realTimeToProcess = elapsedMs;
    var remainingBoostMs = _safeBoostMs(progress.remainingBoostActiveTimeMs);
    var accumulated = progress.accumulatedCycleProgressMs;
    var level = startingLevel;
    var xp = progress.experience;
    var xpEarned = 0;
    var cycles = 0;
    var boostConsumedMs = 0;
    var boostExpired = false;
    var guard = 128;

    while (realTimeToProcess > 0 && guard-- > 0 && level < hobby.maximumLevel) {
      final segmentHasBoost = remainingBoostMs > 0;
      final segmentRealMs = segmentHasBoost
          ? math.min(realTimeToProcess, remainingBoostMs)
          : realTimeToProcess;
      final individualSpeed = segmentHasBoost
          ? IdleBalance.hobbyBoostSpeedMultiplier
          : 1.0;
      final upgradeMultiplier = progress.upgraded ? 2.0 : 1.0;
      final equivalentMs =
          (segmentRealMs * globalSpeed * individualSpeed * upgradeMultiplier)
              .floor();
      final segment = _applyEquivalentHobbyTime(
        hobby: hobby,
        level: level,
        experience: xp,
        accumulated: accumulated + equivalentMs,
      );
      level = segment.level;
      xp = segment.experience;
      accumulated = segment.accumulated;
      xpEarned += segment.xpEarned;
      cycles += segment.cyclesCompleted;

      if (segmentHasBoost) {
        remainingBoostMs -= segmentRealMs;
        boostConsumedMs += segmentRealMs;
        if (remainingBoostMs <= 0) {
          remainingBoostMs = 0;
          boostExpired = true;
        }
      }
      realTimeToProcess -= segmentRealMs;
    }

    if (level >= hobby.maximumLevel) {
      accumulated = 0;
      xp = 0;
    }
    final cycleMs = baseHobbyCycleMillis(hobby: hobby, level: level);
    accumulated = accumulated.clamp(0, cycleMs <= 1 ? 0 : cycleMs - 1);
    final reachedMax =
        startingLevel < hobby.maximumLevel && level >= hobby.maximumLevel;
    final boostEndedByMastery = reachedMax && remainingBoostMs > 0;
    if (boostEndedByMastery) {
      remainingBoostMs = 0;
    }
    return HobbyRuntimeResult(
      xpEarned: xpEarned,
      cyclesCompleted: cycles,
      levelsGained: level - startingLevel,
      reachedMaximumLevel: reachedMax,
      boostExpired: boostExpired,
      boostEndedByMastery: boostEndedByMastery,
      boostActiveTimeConsumedMs: boostConsumedMs,
      progress: progress.copyWith(
        level: level,
        experience: level >= hobby.maximumLevel ? 0 : xp,
        cycles: progress.cycles + cycles,
        continuousPayments: 0,
        active: level >= hobby.maximumLevel ? false : progress.active,
        accumulatedCycleProgressMs: accumulated,
        lastProcessedAtUtc: nowMs,
        cycleStartedAt: level >= hobby.maximumLevel ? 0 : nowMs,
        activePlayTimeMs: progress.activePlayTimeMs + elapsedMs,
        hasBeenStarted: true,
        firstStartedAtUtc: progress.firstStartedAtUtc == 0
            ? nowMs
            : progress.firstStartedAtUtc,
        remainingBoostActiveTimeMs: remainingBoostMs,
        boostReferenceTimestampUtc: remainingBoostMs > 0 ? nowMs : 0,
      ),
    );
  }

  static JobRuntimeResult processJob({
    required JobDefinition job,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
    required int fallbackStartedAt,
    bool offline = false,
  }) {
    if (!progress.active) return JobRuntimeResult(progress: progress);
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    final startedAt = progress.lastProcessedAtUtc > 0
        ? progress.lastProcessedAtUtc
        : activityStartedAt(
            progress: progress,
            fallbackStartedAt: fallbackStartedAt,
          );
    final rawElapsedMs = math.max(0, nowMs - startedAt);
    final elapsedMs = offline
        ? math.min(
            rawElapsedMs,
            IdleBalance.defaultJobOfflineLimit.inMilliseconds,
          )
        : rawElapsedMs;
    final globalSpeed = _globalJobSpeed(state);
    var realTimeToProcess = elapsedMs;
    var remainingBoostMs = _safeBoostMs(progress.remainingBoostActiveTimeMs);
    var accumulated = progress.accumulatedCycleProgressMs;
    var level = progress.level.clamp(1, job.maximumLevel);
    var xp = level >= job.maximumLevel ? 0 : progress.experience;
    var moneyEarned = 0;
    var xpEarned = 0;
    var cycles = 0;
    var continuousPayments = 0;
    final startingLevel = level;
    var boostConsumedMs = 0;
    var boostExpired = false;
    var guard = 128;

    while (realTimeToProcess > 0 && guard-- > 0) {
      final segmentHasBoost = remainingBoostMs > 0;
      final segmentRealMs = segmentHasBoost
          ? math.min(realTimeToProcess, remainingBoostMs)
          : realTimeToProcess;
      final individualSpeed = segmentHasBoost
          ? IdleBalance.jobBoostSpeedMultiplier
          : 1.0;
      final equivalentMs = (segmentRealMs * globalSpeed * individualSpeed)
          .floor();
      final segment = _applyEquivalentJobTime(
        job: job,
        state: state,
        level: level,
        experience: xp,
        accumulated: accumulated + equivalentMs,
      );
      level = segment.level;
      xp = segment.experience;
      accumulated = segment.accumulated;
      // A permanent Job upgrade changes income, never its XP progression.
      moneyEarned += segment.moneyEarned * (progress.upgraded ? 2 : 1);
      xpEarned += segment.xpEarned;
      cycles += segment.cyclesCompleted;
      continuousPayments += segment.continuousPaymentsCompleted;

      if (segmentHasBoost) {
        remainingBoostMs -= segmentRealMs;
        boostConsumedMs += segmentRealMs;
        if (remainingBoostMs <= 0) {
          remainingBoostMs = 0;
          boostExpired = true;
        }
      }
      realTimeToProcess -= segmentRealMs;
    }

    final cycleMs = baseJobCycleMillis(job: job, level: level);
    accumulated = accumulated.clamp(0, cycleMs - 1);
    return JobRuntimeResult(
      moneyEarned: moneyEarned,
      xpEarned: xpEarned,
      cyclesCompleted: cycles,
      continuousPaymentsCompleted: continuousPayments,
      levelsGained: level - startingLevel,
      boostExpired: boostExpired,
      boostActiveTimeConsumedMs: boostConsumedMs,
      progress: progress.copyWith(
        level: level,
        experience: xp,
        cycles: progress.cycles + cycles,
        continuousPayments: progress.continuousPayments + continuousPayments,
        accumulatedCycleProgressMs: accumulated,
        lastProcessedAtUtc: nowMs,
        cycleStartedAt: nowMs,
        lifetimeMoneyEarned: progress.lifetimeMoneyEarned + moneyEarned,
        activePlayTimeMs: progress.activePlayTimeMs + elapsedMs,
        hasBeenStarted: true,
        firstStartedAtUtc: progress.firstStartedAtUtc == 0
            ? nowMs
            : progress.firstStartedAtUtc,
        remainingBoostActiveTimeMs: remainingBoostMs,
        boostReferenceTimestampUtc: remainingBoostMs > 0 ? nowMs : 0,
      ),
    );
  }

  static int activityStartedAt({
    required ActivityProgress progress,
    required int fallbackStartedAt,
  }) =>
      progress.cycleStartedAt > 0 ? progress.cycleStartedAt : fallbackStartedAt;

  static int completedCycles({
    required ActivityProgress progress,
    required int baseSeconds,
    required IdleState state,
    required int nowMs,
    required int fallbackStartedAt,
    required bool offline,
  }) {
    final startedAt = activityStartedAt(
      progress: progress,
      fallbackStartedAt: fallbackStartedAt,
    );
    final elapsedMs = _elapsedMs(startedAt, nowMs, offline: offline);
    final cycleMs = effectiveCycleMillis(
      baseSeconds: baseSeconds,
      state: state,
    );
    return elapsedMs ~/ cycleMs;
  }

  static int nextCycleStartedAt({
    required ActivityProgress progress,
    required int baseSeconds,
    required IdleState state,
    required int nowMs,
    required int fallbackStartedAt,
    required int cycles,
    required bool offline,
  }) {
    if (offline) return nowMs;
    final startedAt = activityStartedAt(
      progress: progress,
      fallbackStartedAt: fallbackStartedAt,
    );
    final cycleMs = effectiveCycleMillis(
      baseSeconds: baseSeconds,
      state: state,
    );
    return startedAt + cycles * cycleMs;
  }

  static double cycleProgress({
    required ActivityProgress progress,
    required int baseSeconds,
    required IdleState state,
    required DateTime now,
  }) {
    if (!progress.active) return 0;
    final nowMs = now.millisecondsSinceEpoch;
    final startedAt = activityStartedAt(
      progress: progress,
      fallbackStartedAt: state.lastSavedAt == 0 ? nowMs : state.lastSavedAt,
    );
    final cycleMs = effectiveCycleMillis(
      baseSeconds: baseSeconds,
      state: state,
    );
    final elapsed = math.max(0, nowMs - startedAt);
    return ((elapsed % cycleMs) / cycleMs).clamp(0, 1);
  }

  static double jobCycleProgress({
    required JobDefinition job,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) {
    final preview = previewJobProgress(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    final cycleMs = baseJobCycleMillis(job: job, level: preview.level);
    if (cycleMs <= 0) return 0;
    return (preview.accumulatedCycleProgressMs / cycleMs).clamp(0, 1);
  }

  static Duration timeUntilNextCycle({
    required ActivityProgress progress,
    required int baseSeconds,
    required IdleState state,
    required DateTime now,
  }) {
    if (!progress.active) return Duration.zero;
    final nowMs = now.millisecondsSinceEpoch;
    final startedAt = activityStartedAt(
      progress: progress,
      fallbackStartedAt: state.lastSavedAt == 0 ? nowMs : state.lastSavedAt,
    );
    final cycleMs = effectiveCycleMillis(
      baseSeconds: baseSeconds,
      state: state,
    );
    final elapsed = math.max(0, nowMs - startedAt);
    final remaining = cycleMs - (elapsed % cycleMs);
    return Duration(milliseconds: remaining == cycleMs ? 0 : remaining);
  }

  static Duration timeUntilNextJobCycle({
    required JobDefinition job,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) {
    if (!progress.active) return Duration.zero;
    final preview = previewJobProgress(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    final cycleMs = baseJobCycleMillis(job: job, level: preview.level);
    final current = preview.accumulatedCycleProgressMs.clamp(0, cycleMs - 1);
    final remainingEquivalent = cycleMs - current;
    final speed =
        _globalJobSpeed(state) *
        (preview.remainingBoostActiveTimeMs > 0
            ? IdleBalance.jobBoostSpeedMultiplier
            : 1.0);
    return Duration(
      milliseconds: speed <= 0
          ? remainingEquivalent
          : (remainingEquivalent / speed).ceil(),
    );
  }

  static Duration timeUntilNextHobbyCycle({
    required HobbyDefinition hobby,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) {
    if (!progress.active || progress.level >= hobby.maximumLevel) {
      return Duration.zero;
    }
    final preview = previewHobbyProgress(
      hobby: hobby,
      progress: progress,
      state: state,
      now: now,
    );
    final cycleMs = baseHobbyCycleMillis(hobby: hobby, level: preview.level);
    final current = preview.accumulatedCycleProgressMs.clamp(0, cycleMs - 1);
    final remainingEquivalent = cycleMs - current;
    final speed =
        _globalJobSpeed(state) *
        (preview.remainingBoostActiveTimeMs > 0
            ? IdleBalance.hobbyBoostSpeedMultiplier
            : 1.0);
    return Duration(
      milliseconds: speed <= 0
          ? remainingEquivalent
          : (remainingEquivalent / speed).ceil(),
    );
  }

  static ActivityProgress previewJobProgress({
    required JobDefinition job,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) {
    if (!progress.active) {
      final level = progress.level.clamp(1, job.maximumLevel);
      final cycleMs = baseJobCycleMillis(job: job, level: level);
      return progress.copyWith(
        level: level,
        experience: level >= job.maximumLevel ? 0 : progress.experience,
        accumulatedCycleProgressMs: progress.accumulatedCycleProgressMs.clamp(
          0,
          cycleMs - 1,
        ),
        remainingBoostActiveTimeMs: _safeBoostMs(
          progress.remainingBoostActiveTimeMs,
        ),
      );
    }
    return processJob(
      job: job,
      progress: progress,
      state: state,
      now: now,
      fallbackStartedAt: state.lastSavedAt == 0
          ? now.toUtc().millisecondsSinceEpoch
          : state.lastSavedAt,
    ).progress;
  }

  static ActivityProgress previewHobbyProgress({
    required HobbyDefinition hobby,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) {
    final level = progress.level.clamp(1, hobby.maximumLevel);
    if (!progress.active || level >= hobby.maximumLevel) {
      final cycleMs = baseHobbyCycleMillis(hobby: hobby, level: level);
      return progress.copyWith(
        level: level,
        active: level >= hobby.maximumLevel ? false : progress.active,
        experience: level >= hobby.maximumLevel ? 0 : progress.experience,
        accumulatedCycleProgressMs: level >= hobby.maximumLevel
            ? 0
            : progress.accumulatedCycleProgressMs.clamp(0, cycleMs - 1),
        remainingBoostActiveTimeMs: level >= hobby.maximumLevel
            ? 0
            : _safeBoostMs(progress.remainingBoostActiveTimeMs),
        boostReferenceTimestampUtc:
            level >= hobby.maximumLevel ||
                progress.remainingBoostActiveTimeMs <= 0
            ? 0
            : progress.boostReferenceTimestampUtc,
      );
    }
    return processHobby(
      hobby: hobby,
      progress: progress,
      state: state,
      now: now,
      fallbackStartedAt: state.lastSavedAt == 0
          ? now.toUtc().millisecondsSinceEpoch
          : state.lastSavedAt,
    ).progress;
  }

  static double hobbyCycleProgress({
    required HobbyDefinition hobby,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) {
    if (!progress.active || progress.level >= hobby.maximumLevel) return 0;
    final preview = previewHobbyProgress(
      hobby: hobby,
      progress: progress,
      state: state,
      now: now,
    );
    final cycleMs = baseHobbyCycleMillis(hobby: hobby, level: preview.level);
    if (cycleMs <= 0) return 0;
    return (preview.accumulatedCycleProgressMs / cycleMs).clamp(0, 1);
  }

  static Duration remainingJobBoostTime({
    required JobDefinition job,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) => previewJobProgress(
    job: job,
    progress: progress,
    state: state,
    now: now,
  ).remainingBoostActiveTime;

  static Duration remainingHobbyBoostTime({
    required HobbyDefinition hobby,
    required ActivityProgress progress,
    required IdleState state,
    required DateTime now,
  }) => previewHobbyProgress(
    hobby: hobby,
    progress: progress,
    state: state,
    now: now,
  ).remainingBoostActiveTime;

  static int jobIncomePerCycle({
    required JobDefinition job,
    required ActivityProgress progress,
    required IdleState state,
  }) =>
      jobIncomeForLevel(job: job, level: progress.level, state: state) *
      (progress.upgraded ? 2 : 1);

  static int jobIncomeForLevel({
    required JobDefinition job,
    required int level,
    required IdleState state,
  }) => (job.rewardAtLevel(level) * state.moneyMultiplier * state.prestigeBonus)
      .floor();

  static double jobIncomePerSecond({
    required JobDefinition job,
    required ActivityProgress progress,
    required IdleState state,
  }) {
    final cycleMs = baseJobCycleMillis(job: job, level: progress.level);
    final speed =
        _globalJobSpeed(state) *
        (progress.hasActiveBoost ? IdleBalance.jobBoostSpeedMultiplier : 1.0);
    return jobIncomePerCycle(job: job, progress: progress, state: state) *
        speed /
        (cycleMs / 1000);
  }

  static int _elapsedMs(int startedAt, int nowMs, {required bool offline}) {
    final raw = math.max(0, nowMs - startedAt);
    if (!offline) return raw;
    return math.min(raw, IdleBalance.offlineLimit.inMilliseconds);
  }

  static double _globalJobSpeed(IdleState state) {
    final speed = state.speedMultiplier * state.prestigeBonus;
    return speed <= 0 ? 1.0 : speed;
  }

  static int _safeBoostMs(int value) => value.clamp(
    0,
    math.max(
      IdleBalance.jobBoostActiveDuration.inMilliseconds,
      IdleBalance.hobbyBoostActiveDuration.inMilliseconds,
    ),
  );

  static _JobEquivalentTimeResult _applyEquivalentJobTime({
    required JobDefinition job,
    required IdleState state,
    required int level,
    required int experience,
    required int accumulated,
  }) {
    var currentLevel = level.clamp(1, job.maximumLevel);
    var xp = currentLevel >= job.maximumLevel ? 0 : experience;
    var currentAccumulated = accumulated;
    var moneyEarned = 0;
    var xpEarned = 0;
    var cycles = 0;
    var continuousPayments = 0;
    var guard = job.maximumLevel + 4;
    while (guard-- > 0) {
      final cycleMs = baseJobCycleMillis(job: job, level: currentLevel);
      final availableCycles = currentAccumulated ~/ cycleMs;
      if (availableCycles <= 0) break;
      final income = jobIncomeForLevel(
        job: job,
        level: currentLevel,
        state: state,
      );
      if (currentLevel >= job.maximumLevel) {
        currentAccumulated %= cycleMs;
        cycles += availableCycles;
        continuousPayments += availableCycles;
        moneyEarned += availableCycles * income;
        xp = 0;
        continue;
      }

      final needed = IdleBalance.jobXpNeeded(job, currentLevel);
      if (needed <= 0) {
        currentLevel++;
        if (currentLevel >= job.maximumLevel) xp = 0;
        continue;
      }
      final remainingXp = math.max(0, needed - xp);
      final cyclesToLevel = math.max(1, (remainingXp / job.xpPerCycle).ceil());
      final cyclesAtLevel = math.min(availableCycles, cyclesToLevel);
      currentAccumulated -= cyclesAtLevel * cycleMs;
      cycles += cyclesAtLevel;
      moneyEarned += cyclesAtLevel * income;
      final xpDelta = cyclesAtLevel * job.xpPerCycle;
      xp += xpDelta;
      xpEarned += xpDelta;
      if (xp < needed) break;
      xp -= needed;
      currentLevel++;
      if (currentLevel >= job.maximumLevel) {
        xp = 0;
      }
    }
    return _JobEquivalentTimeResult(
      level: currentLevel,
      experience: xp,
      accumulated: currentAccumulated,
      moneyEarned: moneyEarned,
      xpEarned: xpEarned,
      cyclesCompleted: cycles,
      continuousPaymentsCompleted: continuousPayments,
    );
  }

  static _HobbyEquivalentTimeResult _applyEquivalentHobbyTime({
    required HobbyDefinition hobby,
    required int level,
    required int experience,
    required int accumulated,
  }) {
    var currentLevel = level.clamp(1, hobby.maximumLevel);
    var xp = currentLevel >= hobby.maximumLevel ? 0 : math.max(0, experience);
    var currentAccumulated = math.max(0, accumulated);
    var xpEarned = 0;
    var cycles = 0;
    var guard = hobby.maximumLevel * 1024;
    while (guard-- > 0 && currentLevel < hobby.maximumLevel) {
      final cycleMs = baseHobbyCycleMillis(hobby: hobby, level: currentLevel);
      final availableCycles = currentAccumulated ~/ cycleMs;
      if (availableCycles <= 0) break;
      final needed = IdleBalance.hobbyXpNeeded(hobby, currentLevel);
      if (needed <= 0) {
        currentLevel++;
        if (currentLevel >= hobby.maximumLevel) xp = 0;
        continue;
      }
      final remainingXp = math.max(0, needed - xp);
      final cyclesToLevel = math.max(
        1,
        (remainingXp / hobby.xpPerTrainingCycle).ceil(),
      );
      final cyclesAtLevel = math.min(availableCycles, cyclesToLevel);
      currentAccumulated -= cyclesAtLevel * cycleMs;
      cycles += cyclesAtLevel;
      final xpDelta = cyclesAtLevel * hobby.xpPerTrainingCycle;
      xp += xpDelta;
      xpEarned += xpDelta;
      if (xp < needed) break;
      xp -= needed;
      currentLevel++;
      if (currentLevel >= hobby.maximumLevel) {
        xp = 0;
        currentAccumulated = 0;
        break;
      }
    }
    return _HobbyEquivalentTimeResult(
      level: currentLevel,
      experience: xp,
      accumulated: currentAccumulated,
      xpEarned: xpEarned,
      cyclesCompleted: cycles,
    );
  }
}

class _JobEquivalentTimeResult {
  const _JobEquivalentTimeResult({
    required this.level,
    required this.experience,
    required this.accumulated,
    required this.moneyEarned,
    required this.xpEarned,
    required this.cyclesCompleted,
    required this.continuousPaymentsCompleted,
  });

  final int level;
  final int experience;
  final int accumulated;
  final int moneyEarned;
  final int xpEarned;
  final int cyclesCompleted;
  final int continuousPaymentsCompleted;
}

class _HobbyEquivalentTimeResult {
  const _HobbyEquivalentTimeResult({
    required this.level,
    required this.experience,
    required this.accumulated,
    required this.xpEarned,
    required this.cyclesCompleted,
  });

  final int level;
  final int experience;
  final int accumulated;
  final int xpEarned;
  final int cyclesCompleted;
}
