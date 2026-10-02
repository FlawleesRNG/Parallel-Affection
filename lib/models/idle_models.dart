import 'dart:convert';

import '../core/character_catalog.dart';
import '../core/player_skill_service.dart';
import '../data/idle_balance.dart';
import 'narrative_models.dart';

enum ActivityKind { job, hobby }

abstract final class IdleSaveSchema {
  static const int currentVersion = 7;
}

class MigrationReport {
  const MigrationReport({
    required this.fromVersion,
    required this.toVersion,
    this.migrated = false,
    this.sanitizedFields = 0,
    this.recoveredJobs = const [],
    this.recoveredHobbies = const [],
    this.ignoredUnknownJobs = const [],
    this.ignoredUnknownHobbies = const [],
    this.missingHobbiesCreated = const [],
    this.aliasesConverted = const {},
    this.backupUsed = false,
    this.offlineSkippedDueToMissingTimestamp = false,
    this.hobbyOfflineSkippedDueToMissingTimestamp = false,
    this.recoveredFromInvalidSource = false,
  });

  final int fromVersion;
  final int toVersion;
  final bool migrated;
  final int sanitizedFields;
  final List<String> recoveredJobs;
  final List<String> recoveredHobbies;
  final List<String> ignoredUnknownJobs;
  final List<String> ignoredUnknownHobbies;
  final List<String> missingHobbiesCreated;
  final Map<String, String> aliasesConverted;
  final bool backupUsed;
  final bool offlineSkippedDueToMissingTimestamp;
  final bool hobbyOfflineSkippedDueToMissingTimestamp;
  final bool recoveredFromInvalidSource;

  MigrationReport copyWith({
    int? fromVersion,
    int? toVersion,
    bool? migrated,
    int? sanitizedFields,
    List<String>? recoveredJobs,
    List<String>? recoveredHobbies,
    List<String>? ignoredUnknownJobs,
    List<String>? ignoredUnknownHobbies,
    List<String>? missingHobbiesCreated,
    Map<String, String>? aliasesConverted,
    bool? backupUsed,
    bool? offlineSkippedDueToMissingTimestamp,
    bool? hobbyOfflineSkippedDueToMissingTimestamp,
    bool? recoveredFromInvalidSource,
  }) => MigrationReport(
    fromVersion: fromVersion ?? this.fromVersion,
    toVersion: toVersion ?? this.toVersion,
    migrated: migrated ?? this.migrated,
    sanitizedFields: sanitizedFields ?? this.sanitizedFields,
    recoveredJobs: recoveredJobs ?? this.recoveredJobs,
    recoveredHobbies: recoveredHobbies ?? this.recoveredHobbies,
    ignoredUnknownJobs: ignoredUnknownJobs ?? this.ignoredUnknownJobs,
    ignoredUnknownHobbies: ignoredUnknownHobbies ?? this.ignoredUnknownHobbies,
    missingHobbiesCreated: missingHobbiesCreated ?? this.missingHobbiesCreated,
    aliasesConverted: aliasesConverted ?? this.aliasesConverted,
    backupUsed: backupUsed ?? this.backupUsed,
    offlineSkippedDueToMissingTimestamp:
        offlineSkippedDueToMissingTimestamp ??
        this.offlineSkippedDueToMissingTimestamp,
    hobbyOfflineSkippedDueToMissingTimestamp:
        hobbyOfflineSkippedDueToMissingTimestamp ??
        this.hobbyOfflineSkippedDueToMissingTimestamp,
    recoveredFromInvalidSource:
        recoveredFromInvalidSource ?? this.recoveredFromInvalidSource,
  );
}

class IdleStateMigrationResult {
  const IdleStateMigrationResult({required this.state, required this.report});

  final IdleState state;
  final MigrationReport report;
}

class _MigrationDraft {
  _MigrationDraft(this.report);

  MigrationReport report;

  void markMigrated() {
    report = report.copyWith(migrated: true);
  }

  void sanitized([int amount = 1]) {
    report = report.copyWith(sanitizedFields: report.sanitizedFields + amount);
  }

  void recoveredJob(String id) {
    if (report.recoveredJobs.contains(id)) return;
    report = report.copyWith(recoveredJobs: [...report.recoveredJobs, id]);
  }

  void recoveredHobby(String id) {
    if (report.recoveredHobbies.contains(id)) return;
    report = report.copyWith(
      recoveredHobbies: [...report.recoveredHobbies, id],
    );
  }

  void ignoredUnknownJob(String id) {
    if (report.ignoredUnknownJobs.contains(id)) return;
    report = report.copyWith(
      ignoredUnknownJobs: [...report.ignoredUnknownJobs, id],
    );
  }

  void ignoredUnknownHobby(String id) {
    if (report.ignoredUnknownHobbies.contains(id)) return;
    report = report.copyWith(
      ignoredUnknownHobbies: [...report.ignoredUnknownHobbies, id],
    );
  }

  void missingHobbyCreated(String id) {
    if (report.missingHobbiesCreated.contains(id)) return;
    report = report.copyWith(
      missingHobbiesCreated: [...report.missingHobbiesCreated, id],
    );
  }

  void aliasConverted(String from, String to) {
    report = report.copyWith(
      aliasesConverted: {...report.aliasesConverted, from: to},
    );
  }

  void skippedOfflineForMissingTimestamp() {
    report = report.copyWith(
      offlineSkippedDueToMissingTimestamp: true,
      hobbyOfflineSkippedDueToMissingTimestamp: true,
    );
  }
}

class ActivityProgress {
  const ActivityProgress({
    this.level = 1,
    this.experience = 0,
    this.cycles = 0,
    this.continuousPayments = 0,
    this.active = false,
    this.cycleStartedAt = 0,
    this.accumulatedCycleProgressMs = 0,
    this.lastProcessedAtUtc = 0,
    this.lifetimeMoneyEarned = 0,
    this.activePlayTimeMs = 0,
    this.firstStartedAtUtc = 0,
    this.hasBeenStarted = false,
    this.isUnlocked = false,
    this.remainingBoostActiveTimeMs = 0,
    this.boostReferenceTimestampUtc = 0,
  });
  final int level;
  final int experience;
  final int cycles;
  final int continuousPayments;
  final bool active;
  final int cycleStartedAt;
  final int accumulatedCycleProgressMs;
  final int lastProcessedAtUtc;
  final int lifetimeMoneyEarned;
  final int activePlayTimeMs;
  final int firstStartedAtUtc;
  final bool hasBeenStarted;
  final bool isUnlocked;
  final int remainingBoostActiveTimeMs;
  final int boostReferenceTimestampUtc;

  Duration get remainingBoostActiveTime => Duration(
    milliseconds: remainingBoostActiveTimeMs.clamp(
      0,
      IdleBalance.jobBoostActiveDuration.inMilliseconds,
    ),
  );

  DateTime? get boostLastProcessedAtUtc => boostReferenceTimestampUtc <= 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          boostReferenceTimestampUtc,
          isUtc: true,
        );

  bool get hasActiveBoost => remainingBoostActiveTimeMs > 0;

  double get currentIndividualSpeedMultiplier =>
      hasActiveBoost ? IdleBalance.jobBoostSpeedMultiplier : 1.0;

  ActivityProgress copyWith({
    int? level,
    int? experience,
    int? cycles,
    int? continuousPayments,
    bool? active,
    int? cycleStartedAt,
    int? accumulatedCycleProgressMs,
    int? lastProcessedAtUtc,
    int? lifetimeMoneyEarned,
    int? activePlayTimeMs,
    int? firstStartedAtUtc,
    bool? hasBeenStarted,
    bool? isUnlocked,
    int? remainingBoostActiveTimeMs,
    int? boostReferenceTimestampUtc,
  }) => ActivityProgress(
    level: level ?? this.level,
    experience: experience ?? this.experience,
    cycles: cycles ?? this.cycles,
    continuousPayments: continuousPayments ?? this.continuousPayments,
    active: active ?? this.active,
    cycleStartedAt: cycleStartedAt ?? this.cycleStartedAt,
    accumulatedCycleProgressMs:
        accumulatedCycleProgressMs ?? this.accumulatedCycleProgressMs,
    lastProcessedAtUtc: lastProcessedAtUtc ?? this.lastProcessedAtUtc,
    lifetimeMoneyEarned: lifetimeMoneyEarned ?? this.lifetimeMoneyEarned,
    activePlayTimeMs: activePlayTimeMs ?? this.activePlayTimeMs,
    firstStartedAtUtc: firstStartedAtUtc ?? this.firstStartedAtUtc,
    hasBeenStarted: hasBeenStarted ?? this.hasBeenStarted,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    remainingBoostActiveTimeMs:
        remainingBoostActiveTimeMs ?? this.remainingBoostActiveTimeMs,
    boostReferenceTimestampUtc:
        boostReferenceTimestampUtc ?? this.boostReferenceTimestampUtc,
  );
  Map<String, dynamic> toJson() => {
    'level': level,
    'experience': experience,
    'cycles': cycles,
    'continuousPayments': continuousPayments,
    'active': active,
    'cycleStartedAt': cycleStartedAt,
    'accumulatedCycleProgressMs': accumulatedCycleProgressMs,
    'lastProcessedAtUtc': lastProcessedAtUtc,
    'lifetimeMoneyEarned': lifetimeMoneyEarned,
    'activePlayTimeMs': activePlayTimeMs,
    'firstStartedAtUtc': firstStartedAtUtc,
    'hasBeenStarted': hasBeenStarted,
    'isUnlocked': isUnlocked,
    'remainingBoostActiveTimeMs': remainingBoostActiveTimeMs,
    'boostReferenceTimestampUtc': boostReferenceTimestampUtc,
  };
  factory ActivityProgress.fromJson(
    Map<String, dynamic>? json,
  ) => ActivityProgress(
    level: _readInt(json, 'level', fallback: 1),
    experience: _readInt(
      json,
      'experience',
      fallback: _readInt(json, 'currentXp'),
    ),
    cycles: _readInt(
      json,
      'cycles',
      fallback: _readInt(json, 'completedCycles'),
    ),
    continuousPayments: _readInt(json, 'continuousPayments'),
    active: _readBool(json, 'active', fallback: _readBool(json, 'isActive')),
    cycleStartedAt: _readInt(json, 'cycleStartedAt'),
    accumulatedCycleProgressMs: _readInt(
      json,
      'accumulatedCycleProgressMs',
      fallback: _readInt(json, 'accumulatedCycleProgress'),
    ),
    lastProcessedAtUtc: _readInt(json, 'lastProcessedAtUtc'),
    lifetimeMoneyEarned: _readInt(json, 'lifetimeMoneyEarned'),
    activePlayTimeMs: _readInt(
      json,
      'activePlayTimeMs',
      fallback: _readInt(json, 'activePlayTime'),
    ),
    firstStartedAtUtc: _readInt(json, 'firstStartedAtUtc'),
    hasBeenStarted: _readBool(json, 'hasBeenStarted'),
    isUnlocked: _readBool(
      json,
      'isUnlocked',
      fallback: _readBool(json, 'unlocked'),
    ),
    remainingBoostActiveTimeMs: _readInt(
      json,
      'remainingBoostActiveTimeMs',
      fallback: _readInt(json, 'remainingBoostActiveTime'),
    ),
    boostReferenceTimestampUtc: _readInt(json, 'boostReferenceTimestampUtc'),
  );
}

class CharacterProgress {
  const CharacterProgress({
    this.unlocked = false,
    this.stage = 0,
    this.affection = 0,
    this.lifetimeAffection = 0,
    this.gifts = 0,
    this.giftDeliveries = const {},
    this.encounters = 0,
    this.lastTalkAt = 0,
    this.lastInteractAt = 0,
    this.lastPassiveAffectionAt = 0,
    this.scenes = const {},
  });
  final bool unlocked;
  final int stage;
  final int affection;
  final int lifetimeAffection;
  final int gifts;
  final Map<String, int> giftDeliveries;
  final int encounters;
  final int lastTalkAt;
  final int lastInteractAt;
  final int lastPassiveAffectionAt;
  final Set<String> scenes;
  CharacterProgress copyWith({
    bool? unlocked,
    int? stage,
    int? affection,
    int? lifetimeAffection,
    int? gifts,
    Map<String, int>? giftDeliveries,
    int? encounters,
    int? lastTalkAt,
    int? lastInteractAt,
    int? lastPassiveAffectionAt,
    Set<String>? scenes,
  }) => CharacterProgress(
    unlocked: unlocked ?? this.unlocked,
    stage: stage ?? this.stage,
    affection: affection ?? this.affection,
    lifetimeAffection: lifetimeAffection ?? this.lifetimeAffection,
    gifts: gifts ?? this.gifts,
    giftDeliveries: giftDeliveries ?? this.giftDeliveries,
    encounters: encounters ?? this.encounters,
    lastTalkAt: lastTalkAt ?? this.lastTalkAt,
    lastInteractAt: lastInteractAt ?? this.lastInteractAt,
    lastPassiveAffectionAt:
        lastPassiveAffectionAt ?? this.lastPassiveAffectionAt,
    scenes: scenes ?? this.scenes,
  );
  Map<String, dynamic> toJson() => {
    'unlocked': unlocked,
    'stage': stage,
    'affection': affection,
    'lifetimeAffection': lifetimeAffection,
    'gifts': gifts,
    'giftDeliveries': giftDeliveries,
    'encounters': encounters,
    'lastTalkAt': lastTalkAt,
    'lastInteractAt': lastInteractAt,
    'lastPassiveAffectionAt': lastPassiveAffectionAt,
    'scenes': scenes.toList(),
  };
  factory CharacterProgress.fromJson(Map<String, dynamic>? json) =>
      CharacterProgress(
        unlocked: _readBool(json, 'unlocked'),
        stage: _readInt(json, 'stage'),
        affection: _readInt(
          json,
          'affection',
          fallback: _readInt(json, 'affinity'),
        ),
        lifetimeAffection: _readInt(json, 'lifetimeAffection'),
        gifts: _readInt(
          json,
          'gifts',
          fallback: _readInt(json, 'chocolatesGiven'),
        ),
        giftDeliveries: _readStringIntMap(json, 'giftDeliveries'),
        encounters: _readInt(json, 'encounters'),
        lastTalkAt: _readInt(json, 'lastTalkAt'),
        lastInteractAt: _readInt(json, 'lastInteractAt'),
        lastPassiveAffectionAt: _readInt(json, 'lastPassiveAffectionAt'),
        scenes: _readStringSet(json, 'scenes', fallbackKey: 'unlockedScenes'),
      );
}

class ActiveEncounter {
  const ActiveEncounter({
    required this.characterId,
    required this.encounterId,
    required this.startedAt,
  });
  final String characterId;
  final String encounterId;
  final int startedAt;
  Map<String, dynamic> toJson() => {
    'characterId': characterId,
    'encounterId': encounterId,
    'startedAt': startedAt,
  };
  factory ActiveEncounter.fromJson(Map<String, dynamic> json) =>
      ActiveEncounter(
        characterId: json['characterId'] as String,
        encounterId: json['encounterId'] as String,
        startedAt: json['startedAt'] as int,
      );
}

class IdleState {
  const IdleState({
    this.money = 0,
    this.diamonds = 0,
    this.totalBlocks = 6,
    this.speedMultiplier = 1,
    this.moneyMultiplier = 1,
    this.prestigeBonus = 1,
    this.totalMoneyEarned = 0,
    this.prestiges = 0,
    this.lastSavedAt = 0,
    this.jobs = const {},
    this.hobbies = const {},
    this.characters = const {},
    this.achievements = const {},
    this.narrative = const NarrativeProgress(),
    this.activeEncounter,
  });
  final int money;
  final int diamonds;
  final int totalBlocks;
  final double speedMultiplier;
  final double moneyMultiplier;
  final double prestigeBonus;
  final int totalMoneyEarned;
  final int prestiges;
  final int lastSavedAt;
  final Map<String, ActivityProgress> jobs;
  final Map<String, ActivityProgress> hobbies;
  final Map<String, CharacterProgress> characters;
  final Set<String> achievements;
  final NarrativeProgress narrative;
  final ActiveEncounter? activeEncounter;
  int get occupiedBlocks =>
      jobs.entries
          .where((item) => item.value.active)
          .fold<int>(
            0,
            (sum, item) =>
                sum + IdleBalance.jobTimeCost(item.key, item.value.level),
          ) +
      hobbies.entries
          .where((item) => item.value.active)
          .fold<int>(
            0,
            (sum, item) =>
                sum + IdleBalance.hobbyTimeCost(item.key, item.value.level),
          ) +
      (activeEncounter == null
          ? 0
          : encounterBlockCost[activeEncounter!.encounterId]!);
  int get availableBlocks {
    final available = totalBlocks - occupiedBlocks;
    return available < 0 ? 0 : available;
  }

  IdleState copyWith({
    int? money,
    int? diamonds,
    int? totalBlocks,
    double? speedMultiplier,
    double? moneyMultiplier,
    double? prestigeBonus,
    int? totalMoneyEarned,
    int? prestiges,
    int? lastSavedAt,
    Map<String, ActivityProgress>? jobs,
    Map<String, ActivityProgress>? hobbies,
    Map<String, CharacterProgress>? characters,
    Set<String>? achievements,
    NarrativeProgress? narrative,
    ActiveEncounter? activeEncounter,
    bool clearEncounter = false,
  }) => IdleState(
    money: money ?? this.money,
    diamonds: diamonds ?? this.diamonds,
    totalBlocks: totalBlocks ?? this.totalBlocks,
    speedMultiplier: speedMultiplier ?? this.speedMultiplier,
    moneyMultiplier: moneyMultiplier ?? this.moneyMultiplier,
    prestigeBonus: prestigeBonus ?? this.prestigeBonus,
    totalMoneyEarned: totalMoneyEarned ?? this.totalMoneyEarned,
    prestiges: prestiges ?? this.prestiges,
    lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    jobs: jobs ?? this.jobs,
    hobbies: hobbies ?? this.hobbies,
    characters: characters ?? this.characters,
    achievements: achievements ?? this.achievements,
    narrative: narrative ?? this.narrative,
    activeEncounter: clearEncounter
        ? null
        : activeEncounter ?? this.activeEncounter,
  );

  String encode() => jsonEncode({
    'version': IdleSaveSchema.currentVersion,
    'money': money,
    'diamonds': diamonds,
    'totalBlocks': totalBlocks,
    'speedMultiplier': speedMultiplier,
    'moneyMultiplier': moneyMultiplier,
    'prestigeBonus': prestigeBonus,
    'totalMoneyEarned': totalMoneyEarned,
    'prestiges': prestiges,
    'lastSavedAt': lastSavedAt,
    'jobs': jobs.map((key, value) => MapEntry(key, value.toJson())),
    'hobbies': hobbies.map((key, value) => MapEntry(key, value.toJson())),
    'characters': characters.map((key, value) => MapEntry(key, value.toJson())),
    'achievements': achievements.toList(),
    'narrative': narrative.toJson(),
    'activeEncounter': activeEncounter?.toJson(),
  });
  factory IdleState.fresh() => IdleState(
    lastSavedAt: DateTime.now().millisecondsSinceEpoch,
    jobs: {
      for (final id in jobIds)
        id: ActivityProgress(isUnlocked: id == 'neighborhood_deliveries'),
    },
    hobbies: {
      for (final id in hobbyIds)
        id: ActivityProgress(
          isUnlocked: IdleBalance.hobby(id).initialAvailability,
        ),
    },
    characters: {
      PlayableCharacterIds.roxanne: const CharacterProgress(unlocked: true),
      PlayableCharacterIds.kai: const CharacterProgress(unlocked: true),
      PlayableCharacterIds.sofia: const CharacterProgress(unlocked: true),
      PlayableCharacterIds.astra: const CharacterProgress(unlocked: true),
      PlayableCharacterIds.legacyRyomi: const CharacterProgress(unlocked: true),
    },
  );
  factory IdleState.decode(String source) =>
      IdleState.decodeWithReport(source).state;

  static IdleStateMigrationResult decodeWithReport(
    String source, {
    int? nowMs,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Save precisa ser um objeto JSON.');
    }
    return fromJsonWithReport(decoded, nowMs: nowMs);
  }

  static IdleStateMigrationResult fromJsonWithReport(
    Map<String, dynamic> source, {
    int? nowMs,
  }) {
    final currentMs = nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    final fromVersion = _readInt(
      source,
      'version',
      fallback: 1,
    ).clamp(1, IdleSaveSchema.currentVersion);
    final draft = _MigrationDraft(
      MigrationReport(
        fromVersion: fromVersion,
        toVersion: IdleSaveSchema.currentVersion,
        migrated: fromVersion < IdleSaveSchema.currentVersion,
      ),
    );
    var json = Map<String, dynamic>.from(source);
    var version = fromVersion;
    if (version < 2) {
      json = _migrateV1ToV2(json, currentMs, draft);
      version = 2;
    }
    if (version < 3) {
      json = _migrateV2ToV3(json, draft);
      version = 3;
    }
    if (version < 4) {
      json = _migrateV3ToV4(json, draft);
      version = 4;
    }
    if (version < 5) {
      json = _migrateV4ToV5(json, draft);
      version = 5;
    }
    if (version < 6) {
      json = _migrateV5ToV6(json, draft);
      version = 6;
    }
    if (version < 7) {
      json = _migrateV6ToV7(json, draft);
    }
    json['version'] = IdleSaveSchema.currentVersion;
    final state = _fromCurrentJson(json, currentMs, draft)._withDefaults(draft);
    return IdleStateMigrationResult(state: state, report: draft.report);
  }

  static IdleState _fromCurrentJson(
    Map<String, dynamic> json,
    int currentMs,
    _MigrationDraft draft,
  ) {
    final hasReliableTimestamp =
        json.containsKey('lastSavedAt') && _readInt(json, 'lastSavedAt') > 0;
    if (!hasReliableTimestamp) {
      draft.skippedOfflineForMissingTimestamp();
    }
    return IdleState(
      money: _nonNegative(_readInt(json, 'money'), draft),
      diamonds: _nonNegative(
        _readInt(json, 'diamonds', fallback: _readInt(json, 'cherries')),
        draft,
      ),
      totalBlocks: _readInt(json, 'totalBlocks', fallback: 6).clamp(0, 99),
      speedMultiplier: _readDouble(json, 'speedMultiplier', fallback: 1),
      moneyMultiplier: _readDouble(json, 'moneyMultiplier', fallback: 1),
      prestigeBonus: _readDouble(json, 'prestigeBonus', fallback: 1),
      totalMoneyEarned: _nonNegative(_readInt(json, 'totalMoneyEarned'), draft),
      prestiges: _nonNegative(_readInt(json, 'prestiges'), draft),
      lastSavedAt: hasReliableTimestamp
          ? _nonNegative(_readInt(json, 'lastSavedAt'), draft)
          : currentMs,
      jobs: _readActivities(json, 'jobs', draft),
      hobbies: _readActivities(json, 'hobbies', draft),
      characters: _readCharacters(json, draft),
      achievements: _readStringSet(json, 'achievements'),
      narrative: _safeNarrative(json['narrative']),
      activeEncounter: _safeEncounter(json['activeEncounter']),
    );
  }

  static Map<String, dynamic> _migrateV1ToV2(
    Map<String, dynamic> old,
    int currentMs,
    _MigrationDraft draft,
  ) {
    draft.markMigrated();
    if (!old.containsKey('lastSavedAt') || _readInt(old, 'lastSavedAt') <= 0) {
      draft.skippedOfflineForMissingTimestamp();
    }
    final legacyLia =
        _asMap(old['lia']) ?? _asMap(old['ryomi']) ?? const <String, dynamic>{};
    final oldAffinity = _readInt(legacyLia, 'affinity');
    final oldStage = _readInt(legacyLia, 'stage').clamp(0, 2);
    final migrated = CharacterProgress(
      unlocked: true,
      stage: oldStage,
      affection: oldAffinity,
      lifetimeAffection: oldAffinity,
      gifts: _readInt(legacyLia, 'chocolatesGiven'),
      scenes: _readStringSet(legacyLia, 'unlockedScenes'),
    );
    return {
      'version': 2,
      'money': _readInt(old, 'money'),
      'diamonds': _readInt(old, 'diamonds'),
      'totalBlocks': _readInt(old, 'totalBlocks', fallback: 6),
      'lastSavedAt': _readInt(old, 'lastSavedAt', fallback: currentMs),
      'jobs': _asMap(old['jobs']) ?? const <String, dynamic>{},
      'hobbies': _asMap(old['hobbies']) ?? const <String, dynamic>{},
      'characters': {
        PlayableCharacterIds.roxanne: migrated.toJson(),
        PlayableCharacterIds.legacyRyomi: migrated.toJson(),
      },
      'achievements': _readStringSet(old, 'achievements').toList(),
      'narrative': _asMap(old['narrative']) ?? const <String, dynamic>{},
    };
  }

  static Map<String, dynamic> _migrateV2ToV3(
    Map<String, dynamic> old,
    _MigrationDraft draft,
  ) {
    draft.markMigrated();
    final migrated = Map<String, dynamic>.from(old);
    final characters = Map<String, dynamic>.from(
      _asMap(migrated['characters']) ?? const <String, dynamic>{},
    );
    final ryomi = characters[PlayableCharacterIds.legacyRyomi];
    if (!characters.containsKey(PlayableCharacterIds.roxanne) &&
        ryomi != null) {
      characters[PlayableCharacterIds.roxanne] = ryomi;
      draft.aliasConverted(
        PlayableCharacterIds.legacyRyomi,
        PlayableCharacterIds.roxanne,
      );
    }
    migrated['characters'] = characters;
    migrated['version'] = 3;
    return migrated;
  }

  static Map<String, dynamic> _migrateV3ToV4(
    Map<String, dynamic> old,
    _MigrationDraft draft,
  ) {
    draft.markMigrated();
    final migrated = Map<String, dynamic>.from(old);
    migrated['hobbies'] = _migrateAliasedMap(
      _asMap(migrated['hobbies']) ?? const <String, dynamic>{},
      _legacyHobbyAliases,
      draft,
    );
    migrated['version'] = 4;
    return migrated;
  }

  static Map<String, dynamic> _migrateV4ToV5(
    Map<String, dynamic> old,
    _MigrationDraft draft,
  ) {
    draft.markMigrated();
    final migrated = Map<String, dynamic>.from(old);
    migrated['jobs'] = _migrateAliasedMap(
      _asMap(migrated['jobs']) ?? const <String, dynamic>{},
      _legacyJobAliases,
      draft,
    );
    migrated['version'] = 5;
    return migrated;
  }

  static Map<String, dynamic> _migrateV5ToV6(
    Map<String, dynamic> old,
    _MigrationDraft draft,
  ) {
    draft.markMigrated();
    final migrated = Map<String, dynamic>.from(old);
    migrated['hobbies'] =
        _asMap(migrated['hobbies']) ?? const <String, dynamic>{};
    migrated['version'] = 6;
    return migrated;
  }

  static Map<String, dynamic> _migrateV6ToV7(
    Map<String, dynamic> old,
    _MigrationDraft draft,
  ) {
    draft.markMigrated();
    final migrated = Map<String, dynamic>.from(old);
    final characters = Map<String, dynamic>.from(
      _asMap(migrated['characters']) ?? const <String, dynamic>{},
    );
    for (final entry in characters.entries.toList()) {
      final progress = Map<String, dynamic>.from(
        _asMap(entry.value) ?? const <String, dynamic>{},
      );
      progress.putIfAbsent('giftDeliveries', () => <String, int>{});
      characters[entry.key] = progress;
    }
    migrated['characters'] = characters;
    migrated['version'] = 7;
    return migrated;
  }

  IdleState _withDefaults([_MigrationDraft? draft]) {
    final roxanne =
        characters[PlayableCharacterIds.roxanne] ??
        characters[PlayableCharacterIds.legacyRyomi] ??
        characters[PlayableCharacterIds.legacyLia] ??
        const CharacterProgress(unlocked: true);
    final kai =
        characters[PlayableCharacterIds.kai] ??
        const CharacterProgress(unlocked: true);
    final sofia =
        characters[PlayableCharacterIds.sofia] ??
        const CharacterProgress(unlocked: true);
    final astra =
        characters[PlayableCharacterIds.astra] ??
        const CharacterProgress(unlocked: true);

    var normalized = copyWith(
      jobs: _normalizeJobProgress(jobs, draft),
      hobbies: _normalizeHobbyProgress(hobbies, draft),
      characters: {
        PlayableCharacterIds.roxanne: roxanne.copyWith(unlocked: true),
        PlayableCharacterIds.kai: kai.copyWith(unlocked: true),
        PlayableCharacterIds.sofia: sofia.copyWith(unlocked: true),
        PlayableCharacterIds.astra: astra.copyWith(unlocked: true),
        PlayableCharacterIds.legacyRyomi: roxanne.copyWith(unlocked: true),
      },
    );
    normalized = normalized.copyWith(
      hobbies: _reconcileHobbyUnlocksAfterLoad(normalized, draft),
    );
    normalized = normalized.copyWith(
      jobs: _reconcileJobUnlocksAfterLoad(normalized, draft),
    );
    return normalized;
  }
}

const jobIds = [
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
const hobbyIds = [
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
const jobBlockCost = {
  'neighborhood_deliveries': 2,
  'local_flyering': 1,
  'cafe_assistant': 3,
  'game_store': 3,
  'gym_reception': 3,
  'freelance_photography': 3,
  'radio_assistant': 4,
  'freelance_programmer': 4,
  'event_producer': 5,
};
const hobbyBlockCost = {
  'leitura': 2,
  'academia': 2,
  'teatro': 2,
  'meditacao': 2,
  'videogames': 2,
  'musica': 2,
  'culinaria': 2,
  'fotografia': 2,
  'oratoria': 2,
  'programacao': 2,
};
const encounterBlockCost = {
  'cafeteria': 2,
  'parque': 2,
  'cinema': 3,
  'restaurante': 3,
  'viagem': 4,
};

Map<String, ActivityProgress> _normalizeJobProgress(
  Map<String, ActivityProgress> source,
  _MigrationDraft? draft,
) {
  final migrated = {...source};
  for (final id in source.keys) {
    if (!jobIds.contains(id) && !_legacyJobAliases.containsKey(id)) {
      draft?.ignoredUnknownJob(id);
    }
  }
  for (final entry in _legacyJobAliases.entries) {
    final legacy = migrated[entry.key];
    if (legacy == null) continue;
    final current = migrated[entry.value];
    migrated[entry.value] = _bestActivityProgress(current, legacy);
    draft?.aliasConverted(entry.key, entry.value);
  }
  return {
    for (final id in jobIds)
      id: _normalizeSingleJobProgress(
        id,
        migrated[id] ??
            ActivityProgress(isUnlocked: id == 'neighborhood_deliveries'),
        draft,
      ),
  };
}

ActivityProgress _normalizeSingleJobProgress(
  String id,
  ActivityProgress progress,
  _MigrationDraft? draft,
) {
  final job = IdleBalance.job(id);
  var level = progress.level.clamp(1, job.maximumLevel);
  var xp = progress.experience < 0 ? 0 : progress.experience;
  while (level < job.maximumLevel) {
    final needed = IdleBalance.jobXpNeeded(job, level);
    if (needed <= 0 || xp < needed) break;
    xp -= needed;
    level++;
  }
  if (level >= job.maximumLevel) xp = 0;

  final cycleMs = job.cycleDurationAtLevel(level).inMilliseconds;
  final accumulated = progress.accumulatedCycleProgressMs.clamp(
    0,
    cycleMs <= 1 ? 0 : cycleMs - 1,
  );
  final cycles = progress.cycles < 0 ? 0 : progress.cycles;
  final continuousPayments = progress.continuousPayments < 0
      ? 0
      : progress.continuousPayments;
  final lifetimeMoney = progress.lifetimeMoneyEarned < 0
      ? 0
      : progress.lifetimeMoneyEarned;
  final activePlayTime = progress.activePlayTimeMs < 0
      ? 0
      : progress.activePlayTimeMs;
  final firstStartedAt = progress.firstStartedAtUtc < 0
      ? 0
      : progress.firstStartedAtUtc;
  final lastProcessedAt = progress.lastProcessedAtUtc < 0
      ? 0
      : progress.lastProcessedAtUtc;
  final cycleStartedAt = progress.cycleStartedAt < 0
      ? 0
      : progress.cycleStartedAt;
  final hasHistory =
      level > 1 ||
      xp > 0 ||
      cycles > 0 ||
      continuousPayments > 0 ||
      lifetimeMoney > 0 ||
      activePlayTime > 0 ||
      firstStartedAt > 0 ||
      accumulated > 0 ||
      progress.hasBeenStarted;
  var remainingBoost = progress.remainingBoostActiveTimeMs.clamp(
    0,
    IdleBalance.jobBoostActiveDuration.inMilliseconds,
  );
  if (remainingBoost > 0 && !hasHistory && !progress.isUnlocked) {
    remainingBoost = 0;
  }
  final boostReference = remainingBoost > 0
      ? (progress.boostReferenceTimestampUtc < 0
            ? 0
            : progress.boostReferenceTimestampUtc)
      : 0;
  final normalized = progress.copyWith(
    level: level,
    experience: xp,
    cycles: cycles,
    continuousPayments: continuousPayments,
    cycleStartedAt: cycleStartedAt,
    accumulatedCycleProgressMs: accumulated,
    lastProcessedAtUtc: lastProcessedAt,
    lifetimeMoneyEarned: lifetimeMoney,
    activePlayTimeMs: activePlayTime,
    firstStartedAtUtc: firstStartedAt,
    hasBeenStarted: progress.hasBeenStarted || hasHistory,
    isUnlocked:
        progress.isUnlocked || hasHistory || id == 'neighborhood_deliveries',
    remainingBoostActiveTimeMs: remainingBoost,
    boostReferenceTimestampUtc: boostReference,
  );
  if (normalized.toJson().toString() != progress.toJson().toString()) {
    draft?.sanitized();
    if (hasHistory || progress.isUnlocked) draft?.recoveredJob(id);
  }
  return normalized;
}

Map<String, ActivityProgress> _reconcileJobUnlocksAfterLoad(
  IdleState state,
  _MigrationDraft? draft,
) {
  final jobs = {...state.jobs};
  for (final definition in IdleBalance.jobs) {
    final current = jobs[definition.id] ?? const ActivityProgress();
    final requirementsMet = _jobRequirementsMet(
      state.copyWith(jobs: jobs),
      definition,
    );
    final hasHistory = _jobHasHistory(current);
    final unlocked =
        definition.id == 'neighborhood_deliveries' ||
        current.isUnlocked ||
        hasHistory ||
        requirementsMet;
    final shouldPause = current.active && !unlocked && !hasHistory;
    final updated = current.copyWith(
      isUnlocked: unlocked,
      active: shouldPause ? false : current.active,
      cycleStartedAt: shouldPause ? 0 : current.cycleStartedAt,
      remainingBoostActiveTimeMs: shouldPause
          ? 0
          : current.remainingBoostActiveTimeMs,
      boostReferenceTimestampUtc: shouldPause
          ? 0
          : current.boostReferenceTimestampUtc,
    );
    if (updated.toJson().toString() != current.toJson().toString()) {
      draft?.sanitized();
    }
    jobs[definition.id] = updated;
  }
  return jobs;
}

Map<String, ActivityProgress> _reconcileHobbyUnlocksAfterLoad(
  IdleState state,
  _MigrationDraft? draft,
) {
  final hobbies = {...state.hobbies};
  for (final definition in IdleBalance.hobbies) {
    final current = hobbies[definition.id] ?? const ActivityProgress();
    final hasHistory = _hobbyHasHistory(current);
    final requirementsMet = _hobbyRequirementsMet(
      state.copyWith(hobbies: hobbies),
      definition,
    );
    final unlocked =
        definition.initialAvailability ||
        current.isUnlocked ||
        hasHistory ||
        requirementsMet;
    final shouldStop = current.level >= definition.maximumLevel;
    final shouldPause = current.active && (!unlocked || shouldStop);
    final updated = current.copyWith(
      isUnlocked: unlocked,
      active: shouldPause ? false : current.active,
      experience: shouldStop ? 0 : current.experience,
      accumulatedCycleProgressMs: shouldStop
          ? 0
          : current.accumulatedCycleProgressMs,
      cycleStartedAt: shouldPause ? 0 : current.cycleStartedAt,
      remainingBoostActiveTimeMs: shouldStop
          ? 0
          : current.remainingBoostActiveTimeMs,
      boostReferenceTimestampUtc: shouldStop
          ? 0
          : current.boostReferenceTimestampUtc,
    );
    if (updated.toJson().toString() != current.toJson().toString()) {
      draft?.sanitized();
    }
    hobbies[definition.id] = updated;
  }
  return hobbies;
}

bool _jobHasHistory(ActivityProgress progress) =>
    progress.level > 1 ||
    progress.experience > 0 ||
    progress.cycles > 0 ||
    progress.continuousPayments > 0 ||
    progress.lifetimeMoneyEarned > 0 ||
    progress.activePlayTimeMs > 0 ||
    progress.firstStartedAtUtc > 0 ||
    progress.accumulatedCycleProgressMs > 0 ||
    progress.remainingBoostActiveTimeMs > 0 ||
    progress.hasBeenStarted;

bool _hobbyHasHistory(ActivityProgress progress) =>
    progress.level > 1 ||
    progress.experience > 0 ||
    progress.cycles > 0 ||
    progress.activePlayTimeMs > 0 ||
    progress.firstStartedAtUtc > 0 ||
    progress.accumulatedCycleProgressMs > 0 ||
    progress.hasBeenStarted;

bool _hobbyRequirementsMet(IdleState state, HobbyDefinition hobby) {
  for (final entry in hobby.requires.entries) {
    final parts = entry.key.split(':');
    if (parts.length != 2 || parts.first != 'hobby') return false;
    if ((state.hobbies[parts.last]?.level ?? 0) < entry.value) return false;
  }
  return true;
}

bool _jobRequirementsMet(IdleState state, JobDefinition job) {
  for (final requirement in job.requirements) {
    final targetId = _canonicalRequirementTarget(requirement);
    final met = switch (requirement.type) {
      JobRequirementType.jobLevel =>
        (state.jobs[targetId]?.level ?? 0) >= requirement.value,
      JobRequirementType.hobbyLevel =>
        (state.hobbies[targetId]?.level ?? 0) >= requirement.value,
      JobRequirementType.skillLevel => _skillRequirementMet(
        state,
        targetId,
        requirement.value,
      ),
      JobRequirementType.relationshipStage =>
        (state
                    .characters[PlayableCharacterCatalog.canonicalId(targetId)]
                    ?.stage ??
                0) >=
            requirement.value,
      JobRequirementType.money => state.money >= requirement.value,
      JobRequirementType.eventCompleted ||
      JobRequirementType.locationDiscovered => false,
    };
    if (!met) return false;
  }
  return true;
}

bool _skillRequirementMet(IdleState state, String targetId, int requiredValue) {
  try {
    return PlayerSkillService.getSkillLevelByKey(state, targetId) >=
        requiredValue;
  } catch (_) {
    return false;
  }
}

String _canonicalRequirementTarget(JobRequirement requirement) {
  if (requirement.type == JobRequirementType.relationshipStage) {
    return PlayableCharacterCatalog.canonicalId(requirement.targetId);
  }
  if (requirement.type == JobRequirementType.hobbyLevel) {
    return _legacyHobbyAliases[requirement.targetId] ?? requirement.targetId;
  }
  if (requirement.type == JobRequirementType.jobLevel) {
    return _legacyJobAliases[requirement.targetId] ?? requirement.targetId;
  }
  return requirement.targetId;
}

Map<String, ActivityProgress> _normalizeHobbyProgress(
  Map<String, ActivityProgress> source,
  _MigrationDraft? draft,
) {
  final migrated = {...source};
  for (final id in source.keys) {
    if (!hobbyIds.contains(id) && !_legacyHobbyAliases.containsKey(id)) {
      draft?.ignoredUnknownHobby(id);
    }
  }
  for (final entry in _legacyHobbyAliases.entries) {
    final legacy = migrated[entry.key];
    if (legacy == null) continue;
    final current = migrated[entry.value];
    migrated[entry.value] = _bestActivityProgress(current, legacy);
    draft?.aliasConverted(entry.key, entry.value);
  }
  for (final id in hobbyIds) {
    if (!migrated.containsKey(id)) draft?.missingHobbyCreated(id);
  }
  return {
    for (final id in hobbyIds)
      id: _normalizeHobbyActivityProgress(
        id,
        migrated[id] ?? const ActivityProgress(),
        draft,
      ),
  };
}

ActivityProgress _normalizeHobbyActivityProgress(
  String id,
  ActivityProgress progress,
  _MigrationDraft? draft,
) {
  final hobby = IdleBalance.hobby(id);
  var level = progress.level.clamp(1, hobby.maximumLevel);
  var xp = progress.experience < 0 ? 0 : progress.experience;
  while (level < hobby.maximumLevel) {
    final needed = IdleBalance.hobbyXpNeeded(hobby, level);
    if (needed <= 0 || xp < needed) break;
    xp -= needed;
    level++;
  }
  if (level >= hobby.maximumLevel) xp = 0;
  final cycleMs = hobby.trainingDurationAtLevel(level).inMilliseconds;
  final accumulated = level >= hobby.maximumLevel
      ? 0
      : progress.accumulatedCycleProgressMs.clamp(
          0,
          cycleMs <= 1 ? 0 : cycleMs - 1,
        );
  final hasHistory =
      level > 1 ||
      xp > 0 ||
      progress.cycles > 0 ||
      progress.activePlayTimeMs > 0 ||
      progress.firstStartedAtUtc > 0 ||
      accumulated > 0 ||
      progress.remainingBoostActiveTimeMs > 0 ||
      progress.hasBeenStarted;
  final remainingBoost = level >= hobby.maximumLevel
      ? 0
      : progress.remainingBoostActiveTimeMs.clamp(
          0,
          IdleBalance.hobbyBoostActiveDuration.inMilliseconds,
        );
  final boostReference = remainingBoost <= 0
      ? 0
      : (progress.boostReferenceTimestampUtc < 0
            ? 0
            : progress.boostReferenceTimestampUtc);
  final normalized = progress.copyWith(
    level: level,
    experience: xp,
    cycles: progress.cycles < 0 ? 0 : progress.cycles,
    continuousPayments: 0,
    active: level >= hobby.maximumLevel ? false : progress.active,
    accumulatedCycleProgressMs: accumulated,
    lastProcessedAtUtc: progress.lastProcessedAtUtc < 0
        ? 0
        : progress.lastProcessedAtUtc,
    activePlayTimeMs: progress.activePlayTimeMs < 0
        ? 0
        : progress.activePlayTimeMs,
    firstStartedAtUtc: progress.firstStartedAtUtc < 0
        ? 0
        : progress.firstStartedAtUtc,
    hasBeenStarted: progress.hasBeenStarted || hasHistory,
    isUnlocked: progress.isUnlocked || hobby.initialAvailability || hasHistory,
    remainingBoostActiveTimeMs: remainingBoost,
    boostReferenceTimestampUtc: boostReference,
  );
  if (normalized.toJson().toString() != progress.toJson().toString()) {
    draft?.sanitized();
    if (hasHistory || progress.isUnlocked) draft?.recoveredHobby(id);
  }
  return normalized;
}

ActivityProgress _bestActivityProgress(
  ActivityProgress? current,
  ActivityProgress legacy,
) {
  if (current == null) return legacy;
  final legacyScore = legacy.level * 100000 + legacy.experience + legacy.cycles;
  final currentScore =
      current.level * 100000 + current.experience + current.cycles;
  if (legacyScore > currentScore) return legacy;
  return current;
}

Map<String, ActivityProgress> _readActivities(
  Map<String, dynamic> json,
  String key,
  _MigrationDraft draft,
) {
  final source = _asMap(json[key]) ?? const <String, dynamic>{};
  return {
    for (final entry in source.entries)
      if (entry.value is Map || entry.value == null)
        entry.key: ActivityProgress.fromJson(_asMap(entry.value)),
  };
}

Map<String, CharacterProgress> _readCharacters(
  Map<String, dynamic> json,
  _MigrationDraft draft,
) {
  final source = _asMap(json['characters']) ?? const <String, dynamic>{};
  final characters = <String, CharacterProgress>{};
  for (final entry in source.entries) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(entry.key);
    if (canonicalId != entry.key) {
      draft.aliasConverted(entry.key, canonicalId);
    }
    final progress = CharacterProgress.fromJson(_asMap(entry.value));
    final current = characters[canonicalId];
    characters[canonicalId] = _bestCharacterProgress(current, progress);
  }
  return characters;
}

CharacterProgress _bestCharacterProgress(
  CharacterProgress? current,
  CharacterProgress candidate,
) {
  if (current == null) return candidate;
  final currentScore =
      current.stage * 100000 + current.affection + current.lifetimeAffection;
  final candidateScore =
      candidate.stage * 100000 +
      candidate.affection +
      candidate.lifetimeAffection;
  final best = candidateScore > currentScore ? candidate : current;
  final deliveries = <String, int>{...current.giftDeliveries};
  for (final entry in candidate.giftDeliveries.entries) {
    final previous = deliveries[entry.key] ?? 0;
    if (entry.value > previous) deliveries[entry.key] = entry.value;
  }
  return best.copyWith(giftDeliveries: deliveries);
}

Map<String, dynamic> _migrateAliasedMap(
  Map<String, dynamic> source,
  Map<String, String> aliases,
  _MigrationDraft draft,
) {
  final migrated = Map<String, dynamic>.from(source);
  for (final entry in aliases.entries) {
    if (!migrated.containsKey(entry.key)) continue;
    if (!migrated.containsKey(entry.value)) {
      migrated[entry.value] = migrated[entry.key];
    }
    draft.aliasConverted(entry.key, entry.value);
  }
  return migrated;
}

NarrativeProgress _safeNarrative(Object? value) {
  try {
    return NarrativeProgress.fromJson(_asMap(value));
  } catch (_) {
    return const NarrativeProgress();
  }
}

ActiveEncounter? _safeEncounter(Object? value) {
  try {
    final map = _asMap(value);
    return map == null ? null : ActiveEncounter.fromJson(map);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry('$key', item));
  }
  return null;
}

int _readInt(Map<String, dynamic>? json, String key, {int fallback = 0}) {
  final value = json?[key];
  if (value is int) return value;
  if (value is num && value.isFinite) return value.floor();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _readDouble(
  Map<String, dynamic>? json,
  String key, {
  double fallback = 0,
}) {
  final value = json?[key];
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool _readBool(
  Map<String, dynamic>? json,
  String key, {
  bool fallback = false,
}) {
  final value = json?[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

Set<String> _readStringSet(
  Map<String, dynamic>? json,
  String key, {
  String? fallbackKey,
}) {
  final value = json?[key] ?? (fallbackKey == null ? null : json?[fallbackKey]);
  if (value is Iterable) return value.map((item) => '$item').toSet();
  return const {};
}

Map<String, int> _readStringIntMap(Map<String, dynamic>? json, String key) {
  final value = _asMap(json?[key]);
  if (value == null) return const {};
  return {
    for (final entry in value.entries)
      entry.key: entry.value is num
          ? (entry.value as num).toInt().clamp(0, 2147483647)
          : int.tryParse('${entry.value}')?.clamp(0, 2147483647) ?? 0,
  };
}

int _nonNegative(int value, _MigrationDraft draft) {
  if (value >= 0) return value;
  draft.sanitized();
  return 0;
}

const _legacyHobbyAliases = {
  'condicionamento': 'academia',
  'criatividade': 'fotografia',
  'tecnologia': 'programacao',
  'carisma': 'teatro',
  'games': 'videogames',
  'video_games': 'videogames',
  'jogos': 'videogames',
  'fotografia_basica': 'fotografia',
  'foto': 'fotografia',
  'programacao_basica': 'programacao',
  'programming': 'programacao',
  'codigo': 'programacao',
  'oratoria_basica': 'oratoria',
  'comunicacao': 'oratoria',
};

const _legacyJobAliases = {
  'lanchonete': 'neighborhood_deliveries',
  'limpeza': 'local_flyering',
  'restaurante': 'cafe_assistant',
  'escritorio': 'freelance_programmer',
  'tecnologia': 'freelance_programmer',
};
