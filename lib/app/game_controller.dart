import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/character_catalog.dart';
import '../core/idle_rules.dart';
import '../core/job_requirement_evaluator.dart';
import '../data/idle_balance.dart';
import '../data/character_routes.dart';
import '../data/character_unlocks.dart';
import '../data/date_locations.dart';
import '../models/idle_models.dart';
import '../services/activity_runtime_service.dart';
import '../services/game_storage.dart';
import '../services/narrative_service.dart';
import '../services/simulation_service.dart';
import '../services/time_reservation_service.dart';

class ActionResult {
  const ActionResult(this.message, {this.summary, this.storyEpisodeId});

  final String message;
  final SimulationSummary? summary;
  final String? storyEpisodeId;
}

class JobFeedbackRecord {
  const JobFeedbackRecord({
    required this.jobId,
    required this.moneyEarned,
    required this.cyclesCompleted,
    required this.levelsGained,
    required this.resultingLevel,
    required this.createdAtUtc,
  });

  final String jobId;
  final int moneyEarned;
  final int cyclesCompleted;
  final int levelsGained;
  final int resultingLevel;
  final int createdAtUtc;

  bool get hasMoney => moneyEarned > 0 && cyclesCompleted > 0;
  bool get hasLevelUp => levelsGained > 0;
  bool get reachedMaximumLevel =>
      hasLevelUp && resultingLevel >= IdleBalance.maximumJobLevel;
}

class HobbyFeedbackRecord {
  const HobbyFeedbackRecord({
    required this.hobbyId,
    required this.xpEarned,
    required this.cyclesCompleted,
    required this.levelsGained,
    required this.resultingLevel,
    required this.reachedMaximumLevel,
    required this.createdAtUtc,
  });

  final String hobbyId;
  final int xpEarned;
  final int cyclesCompleted;
  final int levelsGained;
  final int resultingLevel;
  final bool reachedMaximumLevel;
  final int createdAtUtc;

  bool get hasXp => xpEarned > 0 && cyclesCompleted > 0;
  bool get hasLevelUp => levelsGained > 0;
}

enum SaveIndicatorPhase { idle, saving, saved, error }

class GameController extends ChangeNotifier {
  GameController(
    this._storage, {
    SimulationService? simulation,
    NarrativeService? narrative,
  }) : _simulation = simulation ?? SimulationService(),
       _narrative = narrative ?? LocalNarrativeService();

  final GameStorage _storage;
  final SimulationService _simulation;
  final NarrativeService _narrative;
  IdleState _state = IdleState.fresh();
  SimulationSummary? _offlineSummary;
  SaveIndicatorPhase _savePhase = SaveIndicatorPhase.idle;
  String? _saveError;
  int _saveSequence = 0;
  Timer? _directClickSaveTimer;
  bool _directClickSavePending = false;
  bool _giftTransactionInFlight = false;
  bool _dateTransactionInFlight = false;
  final Set<String> _recentlyUnlockedJobIds = {};
  final Set<String> _recentlyUnlockedHobbyIds = {};
  final Map<String, JobFeedbackRecord> _jobFeedbacks = {};
  final Map<String, HobbyFeedbackRecord> _hobbyFeedbacks = {};
  final Map<String, String> _jobTimeWarnings = {};
  final Map<String, String> _hobbyTimeWarnings = {};
  final Map<String, String> _jobBoostWarnings = {};
  final Map<String, String> _hobbyBoostWarnings = {};
  MigrationReport? _lastMigrationReport;
  bool _rootTimeInfinite = false;
  bool _rootCherriesInfinite = false;
  bool _hasPersistedSave = false;

  IdleState get state => _state;
  SaveIndicatorPhase get savePhase => _savePhase;
  String? get saveError => _saveError;
  int get saveSequence => _saveSequence;
  Set<String> get recentlyUnlockedJobIds =>
      Set.unmodifiable(_recentlyUnlockedJobIds);
  Set<String> get recentlyUnlockedHobbyIds =>
      Set.unmodifiable(_recentlyUnlockedHobbyIds);
  Map<String, JobFeedbackRecord> get jobFeedbacks =>
      Map.unmodifiable(_jobFeedbacks);
  Map<String, HobbyFeedbackRecord> get hobbyFeedbacks =>
      Map.unmodifiable(_hobbyFeedbacks);
  Map<String, String> get jobTimeWarnings => Map.unmodifiable(_jobTimeWarnings);
  Map<String, String> get hobbyTimeWarnings =>
      Map.unmodifiable(_hobbyTimeWarnings);
  Map<String, String> get jobBoostWarnings =>
      Map.unmodifiable(_jobBoostWarnings);
  Map<String, String> get hobbyBoostWarnings =>
      Map.unmodifiable(_hobbyBoostWarnings);
  MigrationReport? get lastMigrationReport => _lastMigrationReport;
  bool get rootTimeInfinite => _rootTimeInfinite;
  bool get rootCherriesInfinite => _rootCherriesInfinite;

  /// Whether this session started from a valid persisted gameplay save.
  /// A fresh boot deliberately remains false until the player starts a game.
  bool get hasPersistedSave => _hasPersistedSave;

  String _canonicalCharacterId(String id) =>
      PlayableCharacterCatalog.canonicalId(id);

  CharacterProgress _characterProgress(String id) =>
      _state.characters[_canonicalCharacterId(id)]!;

  bool _characterIsUnlocked(String id) => _characterProgress(id).unlocked;

  Map<String, CharacterProgress> _charactersWithProgress(
    String id,
    CharacterProgress progress,
  ) {
    final canonicalId = _canonicalCharacterId(id);
    final characters = {..._state.characters, canonicalId: progress};
    if (canonicalId == PlayableCharacterIds.roxanne) {
      characters[PlayableCharacterIds.legacyRyomi] = progress;
    }
    return characters;
  }

  SimulationSummary? takeOfflineSummary() {
    final value = _offlineSummary;
    _offlineSummary = null;
    return value;
  }

  @override
  void dispose() {
    _directClickSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    final saved = await _storage.read();
    if (saved != null) {
      final migration = await _decodeSaveSafely(saved);
      _state = migration.state;
      _lastMigrationReport = migration.report;
      if (migration.report.fromVersion < IdleSaveSchema.currentVersion) {
        _applyRetroactiveProgressionRewards();
      }
      _hasPersistedSave = !migration.report.recoveredFromInvalidSource;
      final unlockedJobsBeforeOffline = _unlockedJobIds(_state);
      final unlockedHobbiesBeforeOffline = _unlockedHobbyIds(_state);
      final result = _simulation.advance(_state, DateTime.now(), offline: true);
      _state = result.state;
      _applyAutomaticStageAdvancements();
      _reconcileHobbyUnlocks();
      _reconcileJobUnlocks();
      _reconcileTimeReservations();
      final summary = result.summary.copyWith(
        jobUnlocks: _unlockedJobIds(
          _state,
        ).difference(unlockedJobsBeforeOffline).toList(),
        hobbyUnlocks: _unlockedHobbyIds(
          _state,
        ).difference(unlockedHobbiesBeforeOffline).toList(),
      );
      _offlineSummary = summary.hasChanges ? summary : null;
    }
    // Do not create a save just by opening the main menu. A save is written
    // after a valid existing save is reconciled, or when New Game/gameplay
    // explicitly creates progress.
    if (_hasPersistedSave) await _save(quiet: true);
    notifyListeners();
  }

  Future<IdleStateMigrationResult> _decodeSaveSafely(String saved) async {
    try {
      return IdleState.decodeWithReport(saved);
    } catch (_) {
      if (_storage case final RecoverableGameStorage recoverable) {
        final backup = await recoverable.readBackup();
        if (backup != null) {
          try {
            final recovered = IdleState.decodeWithReport(backup);
            return IdleStateMigrationResult(
              state: recovered.state,
              report: recovered.report.copyWith(
                backupUsed: true,
                recoveredFromInvalidSource: true,
              ),
            );
          } catch (_) {
            // Continua para fallback seguro abaixo.
          }
        }
      }
      return IdleStateMigrationResult(
        state: IdleState.fresh(),
        report: const MigrationReport(
          fromVersion: IdleSaveSchema.currentVersion,
          toVersion: IdleSaveSchema.currentVersion,
          recoveredFromInvalidSource: true,
        ),
      );
    }
  }

  Future<void> newGame() async {
    _state = IdleState.fresh();
    _recentlyUnlockedJobIds.clear();
    _recentlyUnlockedHobbyIds.clear();
    _jobFeedbacks.clear();
    _hobbyFeedbacks.clear();
    _jobTimeWarnings.clear();
    _hobbyTimeWarnings.clear();
    _jobBoostWarnings.clear();
    _hobbyBoostWarnings.clear();
    await _save();
    _hasPersistedSave = true;
    notifyListeners();
  }

  Future<void> eraseProgress() async {
    _state = IdleState.fresh();
    _recentlyUnlockedJobIds.clear();
    _recentlyUnlockedHobbyIds.clear();
    _jobFeedbacks.clear();
    _hobbyFeedbacks.clear();
    _jobTimeWarnings.clear();
    _hobbyTimeWarnings.clear();
    _jobBoostWarnings.clear();
    _hobbyBoostWarnings.clear();
    await _storage.clear();
    _hasPersistedSave = false;
    notifyListeners();
  }

  Future<void> tick() async {
    final previousEncounter = _state.activeEncounter;
    final result = _simulation.advance(_state, DateTime.now());
    _state = result.state;
    _recordJobFeedbacks(result.summary);
    _recordHobbyFeedbacks(result.summary);
    final automatic = _applyAutomaticStageAdvancements();
    final unlockedHobbies = _reconcileHobbyUnlocks();
    final unlockedJobs = _reconcileJobUnlocks();
    final timeReconciled = _reconcileTimeReservations();
    if (!result.summary.hasChanges &&
        result.state.activeEncounter == previousEncounter &&
        !automatic.changed &&
        !unlockedHobbies &&
        !unlockedJobs &&
        !timeReconciled) {
      return;
    }
    await _save();
    notifyListeners();
  }

  Future<ActionResult> toggle(ActivityKind kind, String id) async {
    await tick();
    if (kind == ActivityKind.job) {
      _reconcileJobUnlocks();
    } else {
      _reconcileHobbyUnlocks();
    }
    final current = kind == ActivityKind.job
        ? _state.jobs[id]!
        : _state.hobbies[id]!;
    final unlocked = kind == ActivityKind.job
        ? IdleRules.jobUnlocked(_state, id)
        : IdleRules.hobbyUnlocked(_state, id);
    if (!unlocked) {
      return const ActionResult('Este sistema ainda está bloqueado.');
    }
    if (kind == ActivityKind.hobby &&
        current.level >= IdleBalance.hobby(id).maximumLevel) {
      return const ActionResult('Hobby dominado.');
    }
    if (kind == ActivityKind.job && !current.active && !_rootTimeInfinite) {
      final reservation = TimeReservationService.canReserveJob(_state, id);
      if (!reservation.isSuccess) {
        _jobTimeWarnings[id] = reservation.message;
        notifyListeners();
        return ActionResult(
          reservation.message.isEmpty
              ? 'Tempo insuficiente. Pause outra atividade primeiro.'
              : reservation.message,
        );
      }
      _jobTimeWarnings.remove(id);
    } else if (kind == ActivityKind.hobby &&
        !current.active &&
        !_rootTimeInfinite) {
      final reservation = TimeReservationService.canReserveHobby(_state, id);
      if (!reservation.isSuccess) {
        _hobbyTimeWarnings[id] = reservation.message;
        notifyListeners();
        return ActionResult(
          reservation.message.isEmpty
              ? 'Tempo insuficiente. Pause outra atividade primeiro.'
              : reservation.message,
        );
      }
      _hobbyTimeWarnings.remove(id);
    }
    final nextActive = !current.active;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updated = current.copyWith(
      active: nextActive,
      cycleStartedAt: nextActive ? now : 0,
      lastProcessedAtUtc: nextActive ? now : current.lastProcessedAtUtc,
      firstStartedAtUtc: nextActive && current.firstStartedAtUtc == 0
          ? now
          : current.firstStartedAtUtc,
      hasBeenStarted: nextActive || current.hasBeenStarted,
    );
    _state = kind == ActivityKind.job
        ? _state.copyWith(jobs: {..._state.jobs, id: updated})
        : _state.copyWith(hobbies: {..._state.hobbies, id: updated});
    if (kind == ActivityKind.job && !nextActive) {
      TimeReservationService.releaseJob(_state, id);
      _jobTimeWarnings.remove(id);
    } else if (kind == ActivityKind.hobby && !nextActive) {
      TimeReservationService.releaseHobby(_state, id);
      _hobbyTimeWarnings.remove(id);
    }
    _applyAutomaticStageAdvancements();
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult(
      updated.active
          ? (kind == ActivityKind.hobby
                ? 'Treino iniciado.'
                : 'Atividade iniciada.')
          : (kind == ActivityKind.hobby
                ? 'Treino pausado; Tempo liberado.'
                : 'Atividade pausada; Tempo liberado.'),
    );
  }

  Future<ActionResult> purchaseJobBoost(String id, {bool free = false}) async {
    await tick();
    final effectiveFree = free || _rootCherriesInfinite;
    final validation = _validateJobBoostPurchase(id, free: effectiveFree);
    if (validation != null) {
      _jobBoostWarnings[id] = validation;
      notifyListeners();
      return ActionResult(validation);
    }

    final current = _state.jobs[id]!;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final jobs = {
      ..._state.jobs,
      id: current.copyWith(
        remainingBoostActiveTimeMs:
            IdleBalance.jobBoostActiveDuration.inMilliseconds,
        boostReferenceTimestampUtc: now,
      ),
    };
    _state = _state.copyWith(
      diamonds: effectiveFree
          ? _state.diamonds
          : (_state.diamonds - IdleBalance.jobBoostCherryCost).clamp(
              0,
              999999999,
            ),
      jobs: jobs,
    );
    _jobBoostWarnings.remove(id);
    await _save();
    notifyListeners();
    return ActionResult(
      effectiveFree
          ? 'DEV: Impulso x2 ativado gratuitamente.'
          : 'IMPULSO x2 ativado por ${IdleBalance.jobBoostCherryCost} Cerejas.',
    );
  }

  Future<ActionResult> purchaseHobbyBoost(
    String id, {
    bool free = false,
  }) async {
    await tick();
    final effectiveFree = free || _rootCherriesInfinite;
    final validation = _validateHobbyBoostPurchase(id, free: effectiveFree);
    if (validation != null) {
      _hobbyBoostWarnings[id] = validation;
      notifyListeners();
      return ActionResult(validation);
    }

    final current = _state.hobbies[id]!;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    _state = _state.copyWith(
      diamonds: effectiveFree
          ? _state.diamonds
          : (_state.diamonds - IdleBalance.hobbyBoostCherryCost).clamp(
              0,
              999999999,
            ),
      hobbies: {
        ..._state.hobbies,
        id: current.copyWith(
          remainingBoostActiveTimeMs:
              IdleBalance.hobbyBoostActiveDuration.inMilliseconds,
          boostReferenceTimestampUtc: now,
        ),
      },
    );
    _hobbyBoostWarnings.remove(id);
    await _save();
    notifyListeners();
    return ActionResult(
      effectiveFree
          ? 'DEV: Impulso x2 de Hobby ativado gratuitamente.'
          : 'IMPULSO x2 ativado por ${IdleBalance.hobbyBoostCherryCost} Cerejas.',
    );
  }

  /// Permanent, per-activity Alpha upgrade. The old temporary-boost APIs are
  /// kept only for compatibility with historical saves and developer tests;
  /// normal gameplay uses these methods exclusively.
  Future<ActionResult> purchaseActivityUpgrade(
    ActivityKind kind,
    String id, {
    bool free = false,
  }) async {
    await tick();
    final activities = kind == ActivityKind.job ? _state.jobs : _state.hobbies;
    final current = activities[id];
    if (current == null) return const ActionResult('Atividade inexistente.');
    if (!current.isUnlocked) return const ActionResult('Atividade bloqueada.');
    if (current.upgraded)
      return const ActionResult('Esta atividade já foi aprimorada.');
    final effectiveFree = free || _rootCherriesInfinite;
    const cost = IdleBalance.activityUpgradeCherryCost;
    if (!effectiveFree && _state.diamonds < cost) {
      return ActionResult('Cerejas insuficientes: ${_state.diamonds} / $cost.');
    }
    final updated = current.copyWith(upgraded: true);
    _state = kind == ActivityKind.job
        ? _state.copyWith(
            diamonds: effectiveFree ? _state.diamonds : _state.diamonds - cost,
            jobs: {..._state.jobs, id: updated},
          )
        : _state.copyWith(
            diamonds: effectiveFree ? _state.diamonds : _state.diamonds - cost,
            hobbies: {..._state.hobbies, id: updated},
          );
    await _save();
    notifyListeners();
    return ActionResult(
      effectiveFree
          ? 'DEV: atividade aprimorada permanentemente.'
          : 'Aprimoramento permanente x2 adquirido por $cost Cerejas.',
    );
  }

  Future<ActionResult> debugSetActivityUpgrade(
    ActivityKind kind,
    String id,
    bool upgraded,
  ) async {
    final activities = kind == ActivityKind.job ? _state.jobs : _state.hobbies;
    final current = activities[id];
    if (current == null) return const ActionResult('Atividade inexistente.');
    final updated = current.copyWith(upgraded: upgraded);
    _state = kind == ActivityKind.job
        ? _state.copyWith(jobs: {..._state.jobs, id: updated})
        : _state.copyWith(hobbies: {..._state.hobbies, id: updated});
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: aprimoramento ${upgraded ? 'ativado' : 'removido'}.',
    );
  }

  Future<ActionResult> talk(String id) =>
      _affectionAction(id, cooldown: IdleBalance.talkCooldown, talk: true);

  Future<ActionResult> interact(String id) =>
      _affectionAction(id, cooldown: IdleBalance.interactCooldown, talk: false);

  Future<ActionResult> tapCharacter(String id) async {
    final characterId = _canonicalCharacterId(id);
    if (!_characterIsUnlocked(characterId)) {
      return ActionResult(CharacterUnlockCatalog.requirementText(characterId));
    }
    final simulation = _simulation.advance(_state, DateTime.now());
    if (simulation.summary.hasChanges ||
        simulation.state.activeEncounter != _state.activeEncounter) {
      _state = simulation.state;
    }
    final current = _characterProgress(characterId);
    const gain = IdleBalance.directCharacterClickAffection;
    final updated = current.copyWith(
      affection: current.affection + gain,
      lifetimeAffection: current.lifetimeAffection + gain,
    );
    _state = _state.copyWith(
      characters: _charactersWithProgress(characterId, updated),
    );
    _reconcileJobUnlocks();
    _scheduleDirectClickSave();
    notifyListeners();
    return const ActionResult('+1 afeição.');
  }

  Future<ActionResult> _affectionAction(
    String id, {
    required Duration cooldown,
    required bool talk,
  }) async {
    final characterId = _canonicalCharacterId(id);
    if (!_characterIsUnlocked(characterId)) {
      return ActionResult(CharacterUnlockCatalog.requirementText(characterId));
    }
    await tick();
    final current = _characterProgress(characterId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = talk ? current.lastTalkAt : current.lastInteractAt;
    if (now - last < cooldown.inMilliseconds) {
      return ActionResult(
        'Aguarde ${(cooldown.inMilliseconds - (now - last)) ~/ 1000 + 1}s para esta ação.',
      );
    }
    final gain = talk
        ? IdleBalance.talkAffectionReward
        : IdleBalance.interactAffectionReward;
    final updated = current.copyWith(
      affection: current.affection + gain,
      lifetimeAffection: current.lifetimeAffection + gain,
      lastTalkAt: talk ? now : current.lastTalkAt,
      lastInteractAt: talk ? current.lastInteractAt : now,
    );
    _state = _state.copyWith(
      characters: _charactersWithProgress(characterId, updated),
    );
    _applyAutomaticStageAdvancements();
    _reconcileJobUnlocks();
    await _save();
    notifyListeners();
    return ActionResult('+$gain afeição.');
  }

  Future<ActionResult> gift(
    String characterId,
    String giftId,
    int quantity,
  ) async {
    if (_giftTransactionInFlight) {
      return const ActionResult('Uma entrega já está sendo processada.');
    }
    _giftTransactionInFlight = true;
    try {
      characterId = _canonicalCharacterId(characterId);
      if (!_characterIsUnlocked(characterId)) {
        return ActionResult(
          CharacterUnlockCatalog.requirementText(characterId),
        );
      }
      await tick();
      final gift = IdleBalance.gift(giftId);
      if (quantity <= 0) {
        return const ActionResult('Escolha uma quantidade válida.');
      }
      if (quantity > 2147483647 ~/ gift.price) {
        return const ActionResult('Quantidade muito alta para este presente.');
      }
      final cost = gift.price * quantity;
      if (_state.money < cost) {
        return const ActionResult(
          'Dinheiro insuficiente para esta quantidade.',
        );
      }
      final character = _characterProgress(characterId);
      final gain = gift.affection * quantity;
      _state = _state.copyWith(
        money: _state.money - cost,
        characters: _charactersWithProgress(
          characterId,
          character.copyWith(
            affection: character.affection + gain,
            lifetimeAffection: character.lifetimeAffection + gain,
            gifts: character.gifts + quantity,
            giftDeliveries: {
              ...character.giftDeliveries,
              giftId: (character.giftDeliveries[giftId] ?? 0) + quantity,
            },
          ),
        ),
      );
      _applyAutomaticStageAdvancements();
      _reconcileJobUnlocks();
      await _save();
      notifyListeners();
      return ActionResult('$quantity presente(s) entregue(s): +$gain afeição.');
    } finally {
      _giftTransactionInFlight = false;
    }
  }

  Future<ActionResult> startEncounter(String characterId, String encounterId) =>
      startDate(characterId, encounterId);

  int dateCount(String characterId, String locationId) =>
      _state.dateProgressByCharacter[_canonicalCharacterId(
        characterId,
      )]?[locationId] ??
      0;

  Duration dateDuration(DateLocationDefinition location) {
    final multiplier = _state.speedMultiplier <= 0
        ? 1.0
        : _state.speedMultiplier;
    final milliseconds = (location.baseDuration.inMilliseconds / multiplier)
        .round();
    return Duration(
      milliseconds: milliseconds.clamp(1, location.baseDuration.inMilliseconds),
    );
  }

  Future<ActionResult> startDate(String characterId, String locationId) async {
    if (_dateTransactionInFlight) {
      return const ActionResult('Um encontro já está sendo iniciado.');
    }
    _dateTransactionInFlight = true;
    try {
      characterId = _canonicalCharacterId(characterId);
      if (!_characterIsUnlocked(characterId)) {
        return ActionResult(
          CharacterUnlockCatalog.requirementText(characterId),
        );
      }
      await tick();
      if (_state.activeEncounter != null) {
        return const ActionResult('Um encontro já está em andamento.');
      }
      final location = DateLocationCatalog.maybeById(locationId);
      if (location == null)
        return const ActionResult('Local de encontro inválido.');
      if (_state.money < location.baseCost) {
        return const ActionResult('Dinheiro insuficiente.');
      }
      final startedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
      final duration = dateDuration(location);
      _state = _state.copyWith(
        money: _state.money - location.baseCost,
        activeEncounter: ActiveEncounter(
          characterId: characterId,
          encounterId: locationId,
          startedAt: startedAt,
          endsAt: startedAt + duration.inMilliseconds,
          costPaid: location.baseCost,
        ),
      );
      await _save();
      notifyListeners();
      return ActionResult(
        '${location.name} iniciado. O pagamento foi confirmado.',
      );
    } finally {
      _dateTransactionInFlight = false;
    }
  }

  Future<ActionResult> advanceStage(String id) async {
    id = _canonicalCharacterId(id);
    if (!_characterIsUnlocked(id)) {
      return ActionResult(CharacterUnlockCatalog.requirementText(id));
    }
    await tick();
    if (!IdleRules.canAdvance(_state, id)) {
      return const ActionResult(
        'Complete a barra e os requisitos do próximo estágio.',
      );
    }
    final outcome = _advanceStageInMemory(id);
    _reconcileJobUnlocks();
    await _save();
    notifyListeners();
    return ActionResult(
      'Novo estágio: ${IdleRules.stageName(outcome.stage)}.',
      storyEpisodeId: outcome.storyEpisodeId,
    );
  }

  Future<ActionResult> prestige() async {
    if (_state.totalMoneyEarned < 5000 &&
        _characterProgress(PlayableCharacterIds.roxanne).stage < 5) {
      return const ActionResult(
        'Alcance 5.000 moedas totais ou estágio Próxima com Roxanne para prestigiar.',
      );
    }
    final old = _state;
    final chars = {
      for (final entry in old.characters.entries)
        entry.key: entry.value.copyWith(
          stage: 0,
          affection: 0,
          lastPassiveAffectionAt: 0,
        ),
    };
    _state = IdleState.fresh().copyWith(
      diamonds: old.diamonds,
      totalBlocks: old.totalBlocks,
      prestigeBonus: old.prestigeBonus + .15,
      prestiges: old.prestiges + 1,
      achievements: old.achievements,
      characters: chars.map(
        (id, progress) =>
            MapEntry(id, progress.copyWith(unlocked: progress.unlocked)),
      ),
      lastSavedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _recentlyUnlockedJobIds.clear();
    _reconcileJobUnlocks();
    await _save();
    notifyListeners();
    return const ActionResult(
      'Prestígio realizado: velocidade geral aumentada.',
    );
  }

  /// ROOT/DEV entry points deliberately reuse the persisted date state and the
  /// same completion path as real gameplay.
  Future<ActionResult> debugSetDateCount(
    String characterId,
    String locationId,
    int value,
  ) async {
    characterId = _canonicalCharacterId(characterId);
    if (DateLocationCatalog.maybeById(locationId) == null) {
      return const ActionResult('Local de encontro inválido.');
    }
    final progress = {
      for (final entry in _state.dateProgressByCharacter.entries)
        entry.key: {...entry.value},
    };
    progress[characterId] = {
      ...(progress[characterId] ?? const <String, int>{}),
      locationId: value.clamp(0, 2147483647),
    };
    _state = _state.copyWith(dateProgressByCharacter: progress);
    await _save();
    notifyListeners();
    return ActionResult(
      '${DateLocationCatalog.byId(locationId).name}: ${progress[characterId]![locationId]}.',
    );
  }

  Future<ActionResult> debugCompleteActiveDate() async {
    final active = _state.activeEncounter;
    if (active == null) return const ActionResult('Nenhum encontro ativo.');
    _state = _state.copyWith(
      activeEncounter: active.copyWith(
        endsAt: DateTime.now().toUtc().millisecondsSinceEpoch - 1,
      ),
    );
    await tick();
    return const ActionResult('Encontro concluído.');
  }

  Future<ActionResult> debugClearActiveDate() async {
    if (_state.activeEncounter == null)
      return const ActionResult('Nenhum encontro ativo.');
    _state = _state.copyWith(clearEncounter: true);
    await _save();
    notifyListeners();
    return const ActionResult('Encontro ativo removido.');
  }

  Future<void> debugMoney(int value) async {
    _state = _state.copyWith(
      money: _state.money + value,
      totalMoneyEarned: _state.totalMoneyEarned + value,
    );
    _reconcileJobUnlocks();
    await _save();
    notifyListeners();
  }

  Future<ActionResult> debugSetResources({
    int? money,
    int? diamonds,
    int? totalBlocks,
  }) async {
    final previousMoney = _state.money;
    final previousDiamonds = _state.diamonds;
    final previousBlocks = _state.totalBlocks;
    final nextMoney = (money ?? _state.money).clamp(0, 999999999);
    final nextDiamonds = (diamonds ?? _state.diamonds).clamp(0, 999999999);
    final nextBlocks = (totalBlocks ?? _state.totalBlocks).clamp(0, 99);
    _state = _state.copyWith(
      money: nextMoney,
      diamonds: nextDiamonds,
      totalBlocks: nextBlocks,
      totalMoneyEarned: nextMoney > _state.totalMoneyEarned
          ? nextMoney
          : _state.totalMoneyEarned,
    );
    _reconcileJobUnlocks();
    await _save();
    notifyListeners();
    return ActionResult(
      'RECURSOS ATUALIZADOS\n'
      'Dinheiro: $previousMoney → $nextMoney\n'
      'Cerejas: $previousDiamonds → $nextDiamonds\n'
      'Tempo: $previousBlocks → $nextBlocks\n'
      'Tipo: PERSISTENTE\n'
      'Save solicitado: sim',
    );
  }

  Future<ActionResult> debugSetRyomiProgress({
    int? stage,
    int? affection,
    int? gifts,
    int? encounters,
    int? totalMoneyEarned,
  }) async {
    return debugSetCharacterProgress(
      PlayableCharacterIds.roxanne,
      stage: stage,
      affection: affection,
      gifts: gifts,
      encounters: encounters,
      totalMoneyEarned: totalMoneyEarned,
    );
  }

  Future<ActionResult> debugSetCharacterProgress(
    String characterId, {
    int? stage,
    int? affection,
    int? gifts,
    int? encounters,
    int? totalMoneyEarned,
  }) async {
    characterId = _canonicalCharacterId(characterId);
    final current = _characterProgress(characterId);
    final nextStage = (stage ?? current.stage).clamp(
      0,
      IdleRules.totalRelationshipStages - 1,
    );
    final nextAffection = (affection ?? current.affection).clamp(0, 999999);
    final stageChanged = stage != null && stage != current.stage;
    final now = DateTime.now().millisecondsSinceEpoch;
    _state = _state.copyWith(
      totalMoneyEarned: totalMoneyEarned ?? _state.totalMoneyEarned,
      characters: _charactersWithProgress(
        characterId,
        current.copyWith(
          stage: nextStage,
          affection: nextAffection,
          lifetimeAffection: current.lifetimeAffection < nextAffection
              ? nextAffection
              : current.lifetimeAffection,
          gifts: gifts ?? current.gifts,
          encounters: encounters ?? current.encounters,
          lastPassiveAffectionAt: stageChanged
              ? _passiveAffectionClockStartFor(nextStage, now)
              : current.lastPassiveAffectionAt,
        ),
      ),
    );
    _reconcileJobUnlocks();
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${PlayableCharacterCatalog.visibleName(characterId)} em '
      '${IdleRules.stageName(_characterProgress(characterId).stage)}.',
    );
  }

  Future<ActionResult> debugSetCharacterUnlocked(
    String characterId,
    bool unlocked,
  ) async {
    characterId = _canonicalCharacterId(characterId);
    if (characterId == PlayableCharacterIds.roxanne) unlocked = true;
    final current = _characterProgress(characterId);
    _state = _state.copyWith(
      characters: _charactersWithProgress(
        characterId,
        current.copyWith(unlocked: unlocked),
      ),
    );
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${PlayableCharacterCatalog.visibleName(characterId)} ${unlocked ? 'desbloqueada' : 'bloqueada'}.',
    );
  }

  Future<ActionResult> debugUnlockAllCharacters() async {
    for (final character in PlayableCharacterCatalog.all) {
      _state = _state.copyWith(
        characters: _charactersWithProgress(
          character.id,
          _characterProgress(character.id).copyWith(unlocked: true),
        ),
      );
    }
    await _save();
    notifyListeners();
    return const ActionResult('DEV: todas as personagens desbloqueadas.');
  }

  Future<ActionResult> debugResetCharacterUnlocks() async {
    var characters = {..._state.characters};
    for (final character in PlayableCharacterCatalog.all) {
      characters = _charactersWithProgress(
        character.id,
        _characterProgress(
          character.id,
        ).copyWith(unlocked: character.id == PlayableCharacterIds.roxanne),
      );
    }
    _state = _state.copyWith(characters: characters);
    await _save();
    notifyListeners();
    return const ActionResult(
      'DEV: desbloqueios retornaram ao estado de Novo Jogo.',
    );
  }

  Future<ActionResult> debugSetGiftDelivery(
    String characterId,
    String giftId,
    int quantity,
  ) async {
    characterId = _canonicalCharacterId(characterId);
    IdleBalance.gift(giftId);
    final current = _characterProgress(characterId);
    final deliveries = <String, int>{...current.giftDeliveries};
    final normalized = quantity.clamp(0, 2147483647);
    if (normalized == 0) {
      deliveries.remove(giftId);
    } else {
      deliveries[giftId] = normalized;
    }
    _state = _state.copyWith(
      characters: _charactersWithProgress(
        characterId,
        current.copyWith(giftDeliveries: deliveries),
      ),
    );
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${PlayableCharacterCatalog.visibleName(characterId)} recebeu '
      '$normalized × ${IdleBalance.gift(giftId).displayName}.',
    );
  }

  Future<ActionResult> debugSetRoxanneProgress({
    int? stage,
    int? affection,
    int? gifts,
    int? encounters,
    int? totalMoneyEarned,
  }) => debugSetRyomiProgress(
    stage: stage,
    affection: affection,
    gifts: gifts,
    encounters: encounters,
    totalMoneyEarned: totalMoneyEarned,
  );

  Future<ActionResult> debugResetActionCooldowns(String id) async {
    id = _canonicalCharacterId(id);
    final current = _characterProgress(id);
    _state = _state.copyWith(
      characters: _charactersWithProgress(
        id,
        current.copyWith(lastTalkAt: 0, lastInteractAt: 0),
      ),
    );
    await _save();
    notifyListeners();
    return const ActionResult('DEV: cooldowns liberados.');
  }

  Future<ActionResult> debugSimulateOffline(Duration elapsed) async {
    final now = DateTime.now();
    final simulatedStart = now.toUtc().subtract(elapsed).millisecondsSinceEpoch;
    final jobs = {
      for (final entry in _state.jobs.entries)
        entry.key: entry.value.active
            ? entry.value.copyWith(lastProcessedAtUtc: simulatedStart)
            : entry.value,
    };
    final hobbies = {
      for (final entry in _state.hobbies.entries)
        entry.key: entry.value.active
            ? entry.value.copyWith(lastProcessedAtUtc: simulatedStart)
            : entry.value,
    };
    final simulatedState = _state.copyWith(
      lastSavedAt: simulatedStart,
      jobs: jobs,
      hobbies: hobbies,
    );
    final unlockedJobsBeforeOffline = _unlockedJobIds(simulatedState);
    final unlockedHobbiesBeforeOffline = _unlockedHobbyIds(simulatedState);
    final result = _simulation.advance(simulatedState, now, offline: true);
    _state = result.state;
    _applyAutomaticStageAdvancements();
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    final summary = result.summary.copyWith(
      jobUnlocks: _unlockedJobIds(
        _state,
      ).difference(unlockedJobsBeforeOffline).toList(),
      hobbyUnlocks: _unlockedHobbyIds(
        _state,
      ).difference(unlockedHobbiesBeforeOffline).toList(),
    );
    _offlineSummary = summary.hasChanges ? summary : null;
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${summary.elapsed.inMinutes} min offline, '
      '+${summary.money} dinheiro, '
      '+${summary.jobExperience} XP, '
      '+${summary.hobbyExperience} XP de Hobbies, '
      '+${summary.affection} afeição passiva.',
      summary: summary,
    );
  }

  Future<ActionResult> debugProcessJobTime(String id, Duration elapsed) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    if (!current.active) return const ActionResult('DEV: emprego pausado.');
    final now = DateTime.now().toUtc();
    final jobs = {..._state.jobs};
    jobs[id] = current.copyWith(
      lastProcessedAtUtc: now.subtract(elapsed).millisecondsSinceEpoch,
    );
    final result = _simulation.advance(_state.copyWith(jobs: jobs), now);
    _state = result.state;
    _recordJobFeedbacks(result.summary);
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${elapsed.inSeconds}s processados. +${result.summary.money} dinheiro.',
      summary: result.summary,
    );
  }

  Future<ActionResult> debugActivateJobBoost(String id) =>
      purchaseJobBoost(id, free: true);

  Future<ActionResult> debugSetRootPrivileges({
    bool? timeInfinite,
    bool? cherriesInfinite,
  }) async {
    final disablingTime =
        _rootTimeInfinite && timeInfinite != null && !timeInfinite;
    if (disablingTime) {
      await tick();
    }
    _rootTimeInfinite = timeInfinite ?? _rootTimeInfinite;
    _rootCherriesInfinite = cherriesInfinite ?? _rootCherriesInfinite;
    var changed = false;
    if (disablingTime) {
      changed = _reconcileTimeReservations(force: true);
    }
    if (changed) {
      await _save();
    }
    notifyListeners();
    return ActionResult(
      'DEV: privilégios ROOT atualizados. '
      'Tempo infinito: ${_rootTimeInfinite ? 'ON' : 'OFF'}; '
      'Cerejas infinitas: ${_rootCherriesInfinite ? 'ON' : 'OFF'}.',
    );
  }

  Future<ActionResult> debugRemoveJobBoost(String id) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    _state = _state.copyWith(
      jobs: {
        ..._state.jobs,
        id: current.copyWith(
          remainingBoostActiveTimeMs: 0,
          boostReferenceTimestampUtc: 0,
        ),
      },
    );
    _jobBoostWarnings.remove(id);
    await _save();
    notifyListeners();
    return const ActionResult('DEV: impulso removido.');
  }

  Future<ActionResult> debugSetJobBoostRemaining(
    String id,
    Duration remaining,
  ) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    final safeMs = remaining.inMilliseconds.clamp(
      0,
      IdleBalance.jobBoostActiveDuration.inMilliseconds,
    );
    _state = _state.copyWith(
      jobs: {
        ..._state.jobs,
        id: current.copyWith(
          remainingBoostActiveTimeMs: safeMs,
          boostReferenceTimestampUtc: safeMs > 0
              ? DateTime.now().toUtc().millisecondsSinceEpoch
              : 0,
        ),
      },
    );
    _jobBoostWarnings.remove(id);
    await _save();
    notifyListeners();
    return ActionResult('DEV: impulso definido em ${remaining.inSeconds}s.');
  }

  Future<ActionResult> debugExpireJobBoost(String id) =>
      debugSetJobBoostRemaining(id, Duration.zero);

  Future<ActionResult> debugProcessJobUntilBoostExpires(String id) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    if (!current.active) return const ActionResult('DEV: emprego pausado.');
    if (current.remainingBoostActiveTimeMs <= 0) {
      return const ActionResult('DEV: emprego sem impulso ativo.');
    }
    return debugProcessJobTime(
      id,
      Duration(milliseconds: current.remainingBoostActiveTimeMs),
    );
  }

  Future<ActionResult> debugCompleteJobCycle(String id) async {
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    final job = IdleBalance.job(id);
    final remaining = ActivityRuntimeService.timeUntilNextJobCycle(
      job: job,
      progress: current.active
          ? current
          : current.copyWith(
              active: true,
              lastProcessedAtUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
            ),
      state: _state,
      now: DateTime.now().toUtc(),
    );
    if (!current.active) await toggle(ActivityKind.job, id);
    return debugProcessJobTime(
      id,
      remaining == Duration.zero
          ? job.cycleDurationAtLevel(current.level)
          : remaining,
    );
  }

  Future<ActionResult> debugAddJobXp(String id, int amount) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    if (amount <= 0) {
      return const ActionResult('DEV: informe um XP positivo.');
    }
    final job = IdleBalance.job(id);
    var level = current.level.clamp(1, job.maximumLevel);
    if (level >= job.maximumLevel) {
      return const ActionResult('DEV: emprego já está em Domínio Máximo.');
    }
    var xp = level >= job.maximumLevel ? 0 : current.experience + amount;
    while (level < job.maximumLevel) {
      final needed = IdleBalance.jobXpNeeded(job, level);
      if (needed <= 0 || xp < needed) break;
      xp -= needed;
      level++;
      if (level >= job.maximumLevel) {
        xp = 0;
        break;
      }
    }
    final jobs = {
      ..._state.jobs,
      id: current.copyWith(level: level, experience: xp),
    };
    _state = _state.copyWith(jobs: jobs);
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult('DEV: XP aplicado em ${job.displayName}.');
  }

  Future<ActionResult> debugSetJobLevel(String id, int level) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    final job = IdleBalance.job(id);
    final safeLevel = level.clamp(1, job.maximumLevel);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final cycleMs = ActivityRuntimeService.effectiveJobCycleMillis(
      job: job,
      level: safeLevel,
      state: _state,
    );
    final jobs = {
      ..._state.jobs,
      id: current.copyWith(
        level: safeLevel,
        experience: 0,
        accumulatedCycleProgressMs: current.accumulatedCycleProgressMs.clamp(
          0,
          cycleMs - 1,
        ),
        lastProcessedAtUtc: current.active ? now : current.lastProcessedAtUtc,
      ),
    };
    _state = _state.copyWith(jobs: jobs);
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${job.displayName} definido no nível $safeLevel.',
    );
  }

  Future<ActionResult> debugUnlockJob(String id) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    _state = _state.copyWith(
      jobs: {..._state.jobs, id: current.copyWith(isUnlocked: true)},
    );
    _recentlyUnlockedJobIds.add(id);
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${IdleBalance.job(id).displayName} desbloqueado.',
    );
  }

  Future<ActionResult> debugLockJob(String id) async {
    await tick();
    if (id == 'neighborhood_deliveries') {
      return const ActionResult(
        'DEV: Entregas de Bairro fica disponível desde o início.',
      );
    }
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    _state = _state.copyWith(
      jobs: {
        ..._state.jobs,
        id: current.copyWith(
          active: false,
          isUnlocked: false,
          cycleStartedAt: 0,
        ),
      },
    );
    _recentlyUnlockedJobIds.remove(id);
    _reconcileTimeReservations(force: true);
    await _save();
    notifyListeners();
    return ActionResult('DEV: ${IdleBalance.job(id).displayName} bloqueado.');
  }

  Future<ActionResult> debugStartJob(String id) async {
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    if (current.active) return const ActionResult('DEV: emprego já ativo.');
    return toggle(ActivityKind.job, id);
  }

  Future<ActionResult> debugPauseJob(String id) async {
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    if (!current.active) return const ActionResult('DEV: emprego já pausado.');
    return toggle(ActivityKind.job, id);
  }

  Future<ActionResult> debugCompleteJobLevel(String id) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    final job = IdleBalance.job(id);
    if (current.level >= job.maximumLevel) {
      return const ActionResult('DEV: emprego já está em Domínio Máximo.');
    }
    final needed = IdleBalance.jobXpNeeded(job, current.level);
    final missing = (needed - current.experience).clamp(0, needed);
    return debugAddJobXp(id, missing);
  }

  Future<ActionResult> debugZeroJobXp(String id) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    _state = _state.copyWith(
      jobs: {..._state.jobs, id: current.copyWith(experience: 0)},
    );
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: XP de ${IdleBalance.job(id).displayName} zerado.',
    );
  }

  Future<ActionResult> debugSetJobCycleFraction(
    String id,
    double fraction,
  ) async {
    await tick();
    final current = _state.jobs[id];
    if (current == null) return const ActionResult('DEV: emprego inexistente.');
    final job = IdleBalance.job(id);
    final cycleMs = ActivityRuntimeService.baseJobCycleMillis(
      job: job,
      level: current.level,
    );
    final safeFraction = fraction.clamp(0.0, .999);
    final progressMs = (cycleMs * safeFraction).floor().clamp(0, cycleMs - 1);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    _state = _state.copyWith(
      jobs: {
        ..._state.jobs,
        id: current.copyWith(
          accumulatedCycleProgressMs: progressMs,
          lastProcessedAtUtc: current.active ? now : current.lastProcessedAtUtc,
        ),
      },
    );
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: progresso de ${IdleBalance.job(id).displayName} definido em ${(safeFraction * 100).round()}%.',
    );
  }

  Future<ActionResult> debugProcessJobsNow() async {
    final beforeMoney = _state.money;
    final result = _simulation.advance(_state, DateTime.now().toUtc());
    _state = result.state;
    _recordJobFeedbacks(result.summary);
    _recordHobbyFeedbacks(result.summary);
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: pendências processadas. +${_state.money - beforeMoney} dinheiro.',
      summary: result.summary,
    );
  }

  Future<ActionResult> debugReevaluateJobUnlocks() async {
    await tick();
    final before = _unlockedJobIds(_state);
    final changed = _reconcileJobUnlocks();
    final after = _unlockedJobIds(_state);
    if (changed) await _save();
    notifyListeners();
    final unlocked = after.difference(before).toList();
    return ActionResult(
      unlocked.isEmpty
          ? 'DEV: requisitos reavaliados; nenhum novo desbloqueio.'
          : 'DEV: desbloqueados: ${unlocked.map((id) => IdleBalance.job(id).displayName).join(', ')}.',
    );
  }

  Future<ActionResult> debugReconcileTime() async {
    await tick();
    final before = TimeReservationService.snapshot(_state);
    final changed = _reconcileTimeReservations(force: true);
    final after = TimeReservationService.snapshot(_state);
    if (changed) await _save();
    notifyListeners();
    return ActionResult(
      'DEV: Tempo reconciliado. Reservado ${before.reserved} → ${after.reserved}; livre ${after.available}.',
    );
  }

  Future<ActionResult> debugResetJob(String id) async {
    if (!_state.jobs.containsKey(id)) {
      return const ActionResult('DEV: emprego inexistente.');
    }
    _state = _state.copyWith(
      jobs: {
        ..._state.jobs,
        id: ActivityProgress(isUnlocked: id == 'neighborhood_deliveries'),
      },
    );
    _recentlyUnlockedJobIds.remove(id);
    _jobFeedbacks.remove(id);
    _jobTimeWarnings.remove(id);
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult('DEV: ${IdleBalance.job(id).displayName} resetado.');
  }

  Future<ActionResult> debugResetAllJobs() async {
    await tick();
    _state = _state.copyWith(
      jobs: {
        for (final id in jobIds)
          id: ActivityProgress(isUnlocked: id == 'neighborhood_deliveries'),
      },
    );
    _recentlyUnlockedJobIds.clear();
    _jobFeedbacks.clear();
    _jobTimeWarnings.clear();
    _jobBoostWarnings.clear();
    _reconcileJobUnlocks();
    _reconcileTimeReservations(force: true);
    await _save();
    notifyListeners();
    return const ActionResult('DEV: todos os empregos foram resetados.');
  }

  Future<ActionResult> debugUnlockHobby(String id) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    _state = _state.copyWith(
      hobbies: {..._state.hobbies, id: current.copyWith(isUnlocked: true)},
    );
    _recentlyUnlockedHobbyIds.add(id);
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${IdleBalance.hobby(id).displayName} desbloqueado.',
    );
  }

  Future<ActionResult> debugLockHobby(String id) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    final hobby = IdleBalance.hobby(id);
    if (hobby.initialAvailability) {
      return ActionResult(
        'DEV: ${hobby.displayName} fica disponível desde o início.',
      );
    }
    _state = _state.copyWith(
      hobbies: {
        ..._state.hobbies,
        id: current.copyWith(
          active: false,
          isUnlocked: false,
          cycleStartedAt: 0,
        ),
      },
    );
    _recentlyUnlockedHobbyIds.remove(id);
    _hobbyTimeWarnings.remove(id);
    _reconcileJobUnlocks();
    _reconcileTimeReservations(force: true);
    await _save();
    notifyListeners();
    return ActionResult('DEV: ${hobby.displayName} bloqueado sem reset.');
  }

  Future<ActionResult> debugStartHobby(String id) async {
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    if (current.active) return const ActionResult('DEV: hobby já ativo.');
    return toggle(ActivityKind.hobby, id);
  }

  Future<ActionResult> debugPauseHobby(String id) async {
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    if (!current.active) return const ActionResult('DEV: hobby já pausado.');
    return toggle(ActivityKind.hobby, id);
  }

  Future<ActionResult> debugActivateHobbyBoost(String id) =>
      purchaseHobbyBoost(id, free: true);

  Future<ActionResult> debugRemoveHobbyBoost(String id) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    _state = _state.copyWith(
      hobbies: {
        ..._state.hobbies,
        id: current.copyWith(
          remainingBoostActiveTimeMs: 0,
          boostReferenceTimestampUtc: 0,
        ),
      },
    );
    _hobbyBoostWarnings.remove(id);
    await _save();
    notifyListeners();
    return const ActionResult('DEV: impulso de Hobby removido.');
  }

  Future<ActionResult> debugSetHobbyBoostRemaining(
    String id,
    Duration remaining,
  ) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    final hobby = IdleBalance.hobby(id);
    if (current.level >= hobby.maximumLevel) {
      return const ActionResult('DEV: Hobby dominado não aceita impulso.');
    }
    final safeMs = remaining.inMilliseconds.clamp(
      0,
      IdleBalance.hobbyBoostActiveDuration.inMilliseconds,
    );
    _state = _state.copyWith(
      hobbies: {
        ..._state.hobbies,
        id: current.copyWith(
          remainingBoostActiveTimeMs: safeMs,
          boostReferenceTimestampUtc: safeMs > 0
              ? DateTime.now().toUtc().millisecondsSinceEpoch
              : 0,
        ),
      },
    );
    _hobbyBoostWarnings.remove(id);
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: impulso de Hobby definido em ${remaining.inSeconds}s.',
    );
  }

  Future<ActionResult> debugExpireHobbyBoost(String id) =>
      debugSetHobbyBoostRemaining(id, Duration.zero);

  Future<ActionResult> debugProcessHobbyUntilBoostExpires(String id) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    if (!current.active) return const ActionResult('DEV: hobby pausado.');
    if (current.remainingBoostActiveTimeMs <= 0) {
      return const ActionResult('DEV: hobby sem impulso ativo.');
    }
    return debugProcessHobbyTime(
      id,
      Duration(milliseconds: current.remainingBoostActiveTimeMs),
    );
  }

  Future<ActionResult> debugProcessHobbyTime(
    String id,
    Duration elapsed,
  ) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    if (!current.active) return const ActionResult('DEV: hobby pausado.');
    final now = DateTime.now().toUtc();
    final hobbies = {..._state.hobbies};
    hobbies[id] = current.copyWith(
      lastProcessedAtUtc: now.subtract(elapsed).millisecondsSinceEpoch,
    );
    final result = _simulation.advance(_state.copyWith(hobbies: hobbies), now);
    _state = result.state;
    _recordHobbyFeedbacks(result.summary);
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${elapsed.inSeconds}s de treino processados. +${result.summary.hobbyExperience} XP.',
      summary: result.summary,
    );
  }

  Future<ActionResult> debugCompleteHobbyCycle(String id) async {
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    final hobby = IdleBalance.hobby(id);
    if (current.level >= hobby.maximumLevel) {
      return const ActionResult('DEV: hobby já está dominado.');
    }
    final activeProgress = current.active
        ? current
        : current.copyWith(
            active: true,
            lastProcessedAtUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
          );
    final remaining = ActivityRuntimeService.timeUntilNextHobbyCycle(
      hobby: hobby,
      progress: activeProgress,
      state: _state,
      now: DateTime.now().toUtc(),
    );
    if (!current.active) await toggle(ActivityKind.hobby, id);
    return debugProcessHobbyTime(
      id,
      remaining == Duration.zero
          ? hobby.trainingDurationAtLevel(current.level)
          : remaining,
    );
  }

  Future<ActionResult> debugAddHobbyXp(String id, int amount) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    if (amount <= 0) return const ActionResult('DEV: informe um XP positivo.');
    final hobby = IdleBalance.hobby(id);
    var level = current.level.clamp(1, hobby.maximumLevel);
    if (level >= hobby.maximumLevel) {
      return const ActionResult('DEV: hobby já está dominado.');
    }
    var xp = current.experience + amount;
    while (level < hobby.maximumLevel) {
      final needed = IdleBalance.hobbyXpNeeded(hobby, level);
      if (needed <= 0 || xp < needed) break;
      xp -= needed;
      level++;
      if (level >= hobby.maximumLevel) {
        xp = 0;
        break;
      }
    }
    _state = _state.copyWith(
      hobbies: {
        ..._state.hobbies,
        id: current.copyWith(
          level: level,
          experience: xp,
          active: level >= hobby.maximumLevel ? false : current.active,
          accumulatedCycleProgressMs: level >= hobby.maximumLevel
              ? 0
              : current.accumulatedCycleProgressMs,
          cycleStartedAt: level >= hobby.maximumLevel
              ? 0
              : current.cycleStartedAt,
          remainingBoostActiveTimeMs: level >= hobby.maximumLevel
              ? 0
              : current.remainingBoostActiveTimeMs,
          boostReferenceTimestampUtc: level >= hobby.maximumLevel
              ? 0
              : current.boostReferenceTimestampUtc,
          isUnlocked: true,
        ),
      },
    );
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult('DEV: XP aplicado em ${hobby.displayName}.');
  }

  Future<ActionResult> debugCompleteHobbyLevel(String id) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    final hobby = IdleBalance.hobby(id);
    if (current.level >= hobby.maximumLevel) {
      return const ActionResult('DEV: hobby já está dominado.');
    }
    final needed = IdleBalance.hobbyXpNeeded(hobby, current.level);
    final missing = (needed - current.experience).clamp(0, needed);
    return debugAddHobbyXp(id, missing);
  }

  Future<ActionResult> debugZeroHobbyXp(String id) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    _state = _state.copyWith(
      hobbies: {..._state.hobbies, id: current.copyWith(experience: 0)},
    );
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: XP de ${IdleBalance.hobby(id).displayName} zerado.',
    );
  }

  Future<ActionResult> debugSetHobbyLevel(String id, int level) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    final hobby = IdleBalance.hobby(id);
    final safeLevel = level.clamp(1, hobby.maximumLevel);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final cycleMs = ActivityRuntimeService.baseHobbyCycleMillis(
      hobby: hobby,
      level: safeLevel,
    );
    _state = _state.copyWith(
      hobbies: {
        ..._state.hobbies,
        id: current.copyWith(
          level: safeLevel,
          experience: 0,
          active: safeLevel >= hobby.maximumLevel ? false : current.active,
          accumulatedCycleProgressMs: safeLevel >= hobby.maximumLevel
              ? 0
              : current.accumulatedCycleProgressMs.clamp(0, cycleMs - 1),
          lastProcessedAtUtc: current.active ? now : current.lastProcessedAtUtc,
          remainingBoostActiveTimeMs: safeLevel >= hobby.maximumLevel
              ? 0
              : current.remainingBoostActiveTimeMs,
          boostReferenceTimestampUtc: safeLevel >= hobby.maximumLevel
              ? 0
              : current.boostReferenceTimestampUtc,
          isUnlocked: true,
        ),
      },
    );
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${hobby.displayName} definido no nível $safeLevel.',
    );
  }

  Future<ActionResult> debugSetHobbyCycleFraction(
    String id,
    double fraction,
  ) async {
    await tick();
    final current = _state.hobbies[id];
    if (current == null) return const ActionResult('DEV: hobby inexistente.');
    final hobby = IdleBalance.hobby(id);
    if (current.level >= hobby.maximumLevel) {
      return const ActionResult('DEV: Hobby dominado não possui ciclo ativo.');
    }
    final cycleMs = ActivityRuntimeService.baseHobbyCycleMillis(
      hobby: hobby,
      level: current.level,
    );
    final safeFraction = fraction.clamp(0.0, .999);
    final progressMs = (cycleMs * safeFraction).floor().clamp(0, cycleMs - 1);
    _state = _state.copyWith(
      hobbies: {
        ..._state.hobbies,
        id: current.copyWith(accumulatedCycleProgressMs: progressMs),
      },
    );
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: progresso de ${hobby.displayName} definido em ${(safeFraction * 100).round()}%.',
    );
  }

  Future<ActionResult> debugResetHobby(String id) async {
    if (!_state.hobbies.containsKey(id)) {
      return const ActionResult('DEV: hobby inexistente.');
    }
    final hobby = IdleBalance.hobby(id);
    _state = _state.copyWith(
      hobbies: {
        ..._state.hobbies,
        id: ActivityProgress(isUnlocked: hobby.initialAvailability),
      },
    );
    _recentlyUnlockedHobbyIds.remove(id);
    _hobbyFeedbacks.remove(id);
    _hobbyTimeWarnings.remove(id);
    _hobbyBoostWarnings.remove(id);
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations(force: true);
    await _save();
    notifyListeners();
    return ActionResult('DEV: ${hobby.displayName} resetado.');
  }

  Future<ActionResult> debugStartAllHobbies() async {
    await tick();
    final started = <String>[];
    var blockedByTime = 0;
    var state = _state;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final hobby in IdleBalance.hobbies) {
      final current = state.hobbies[hobby.id] ?? const ActivityProgress();
      final unlocked =
          current.isUnlocked || IdleRules.hobbyUnlocked(state, hobby.id);
      if (!unlocked || current.active || current.level >= hobby.maximumLevel) {
        continue;
      }
      if (!_rootTimeInfinite) {
        final reservation = TimeReservationService.canReserveHobby(
          state,
          hobby.id,
        );
        if (!reservation.isSuccess) {
          blockedByTime++;
          continue;
        }
      }
      state = state.copyWith(
        hobbies: {
          ...state.hobbies,
          hobby.id: current.copyWith(
            active: true,
            cycleStartedAt: now,
            lastProcessedAtUtc: now,
            firstStartedAtUtc: current.firstStartedAtUtc == 0
                ? now
                : current.firstStartedAtUtc,
            hasBeenStarted: true,
            isUnlocked: true,
          ),
        },
      );
      started.add(hobby.id);
    }
    _state = state;
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    return ActionResult(
      'DEV: ${started.length} hobby(s) iniciados.'
      '${blockedByTime > 0 ? ' $blockedByTime bloqueado(s) por Tempo.' : ''}',
    );
  }

  Future<ActionResult> debugPauseAllHobbies() async {
    await tick();
    final hobbies = {..._state.hobbies};
    var paused = 0;
    for (final entry in hobbies.entries.toList()) {
      if (!entry.value.active) continue;
      hobbies[entry.key] = entry.value.copyWith(
        active: false,
        cycleStartedAt: 0,
      );
      paused++;
    }
    _state = _state.copyWith(hobbies: hobbies);
    _hobbyTimeWarnings.clear();
    _reconcileTimeReservations(force: true);
    await _save();
    notifyListeners();
    return ActionResult('DEV: $paused hobby(s) pausados; Tempo liberado.');
  }

  Future<ActionResult> debugProcessHobbiesNow() async {
    final beforeXp = _state.hobbies.values.fold<int>(
      0,
      (total, item) => total + item.experience,
    );
    final result = _simulation.advance(_state, DateTime.now().toUtc());
    _state = result.state;
    _recordHobbyFeedbacks(result.summary);
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations();
    await _save();
    notifyListeners();
    final afterXp = _state.hobbies.values.fold<int>(
      0,
      (total, item) => total + item.experience,
    );
    return ActionResult(
      'DEV: pendências de Hobbies processadas. '
      '+${result.summary.hobbyExperience} XP bruto; '
      'saldo XP visível ${afterXp - beforeXp}.',
      summary: result.summary,
    );
  }

  Future<ActionResult> debugResetAllHobbies() async {
    await tick();
    _state = _state.copyWith(
      hobbies: {
        for (final id in hobbyIds)
          id: ActivityProgress(
            isUnlocked: IdleBalance.hobby(id).initialAvailability,
          ),
      },
    );
    _recentlyUnlockedHobbyIds.clear();
    _hobbyFeedbacks.clear();
    _hobbyTimeWarnings.clear();
    _hobbyBoostWarnings.clear();
    _reconcileHobbyUnlocks();
    _reconcileJobUnlocks();
    _reconcileTimeReservations(force: true);
    await _save();
    notifyListeners();
    return const ActionResult('DEV: todos os Hobbies foram resetados.');
  }

  Future<ActionResult> debugForceSave() async {
    await _save();
    notifyListeners();
    return const ActionResult('DEV: salvamento solicitado.');
  }

  Future<void> debugAdvance(String id) async {
    id = _canonicalCharacterId(id);
    final current = _characterProgress(id);
    final stageDefinition = CharacterRouteCatalog.byCharacterId(
      id,
    ).stageFor(current.stage);
    final jobs = {..._state.jobs};
    final hobbies = {..._state.hobbies};
    final deliveries = <String, int>{...current.giftDeliveries};
    final scenes = {...current.scenes};
    for (final requirement in stageDefinition.requirements) {
      final target = requirement.requiredValue;
      if (target == null || target <= 0) continue;
      switch (requirement.type) {
        case CharacterRouteRequirementType.hobbyLevel:
          final progress =
              hobbies[requirement.targetId] ?? const ActivityProgress();
          hobbies[requirement.targetId] = progress.copyWith(
            level: target,
            isUnlocked: true,
          );
        case CharacterRouteRequirementType.jobLevel:
          final progress =
              jobs[requirement.targetId] ?? const ActivityProgress();
          jobs[requirement.targetId] = progress.copyWith(
            level: target,
            isUnlocked: true,
          );
        case CharacterRouteRequirementType.giftDelivered:
          deliveries[requirement.targetId] = target;
        case CharacterRouteRequirementType.eventCompleted:
          scenes.add(requirement.targetId);
        case CharacterRouteRequirementType.money:
          break;
      }
    }
    _state = _state.copyWith(
      characters: _charactersWithProgress(
        id,
        current.copyWith(
          affection: IdleRules.affectionNeededFor(id, current.stage),
          gifts: 99,
          encounters: 99,
          giftDeliveries: deliveries,
          scenes: scenes,
        ),
      ),
      jobs: jobs,
      hobbies: hobbies,
      money:
          stageDefinition.requirements.any(
            (item) => item.type == CharacterRouteRequirementType.money,
          )
          ? 999999999
          : _state.money,
      totalMoneyEarned: 999999999,
    );
    _applyAutomaticStageAdvancements();
    _reconcileJobUnlocks();
    await _save();
    notifyListeners();
  }

  bool _reconcileJobUnlocks() {
    final jobs = {..._state.jobs};
    var changed = false;
    for (final definition in IdleBalance.jobs) {
      final current = jobs[definition.id] ?? const ActivityProgress();
      final evaluation = JobRequirementEvaluator.evaluate(
        _state.copyWith(jobs: jobs),
        definition,
      );
      final shouldUnlock =
          definition.id == 'neighborhood_deliveries' ||
          current.isUnlocked ||
          evaluation.requirementsMet;
      if (!current.isUnlocked && shouldUnlock) {
        jobs[definition.id] = current.copyWith(isUnlocked: true);
        changed = true;
        if (definition.id != 'neighborhood_deliveries') {
          _recentlyUnlockedJobIds.add(definition.id);
        }
      }
    }
    if (changed) {
      _state = _state.copyWith(jobs: jobs);
    }
    return changed;
  }

  bool _reconcileHobbyUnlocks() {
    final hobbies = {..._state.hobbies};
    var changed = false;
    for (final definition in IdleBalance.hobbies) {
      final current = hobbies[definition.id] ?? const ActivityProgress();
      final shouldUnlock =
          definition.initialAvailability ||
          current.isUnlocked ||
          IdleRules.requirementsMet(
            _state.copyWith(hobbies: hobbies),
            definition.requires,
          );
      final shouldStop = current.level >= definition.maximumLevel;
      final updated = current.copyWith(
        isUnlocked: shouldUnlock,
        active: shouldStop ? false : current.active,
        experience: shouldStop ? 0 : current.experience,
        accumulatedCycleProgressMs: shouldStop
            ? 0
            : current.accumulatedCycleProgressMs,
        cycleStartedAt: shouldStop ? 0 : current.cycleStartedAt,
        remainingBoostActiveTimeMs: shouldStop
            ? 0
            : current.remainingBoostActiveTimeMs,
        boostReferenceTimestampUtc: shouldStop
            ? 0
            : current.boostReferenceTimestampUtc,
      );
      if (updated.toJson().toString() != current.toJson().toString()) {
        hobbies[definition.id] = updated;
        changed = true;
        if (!current.isUnlocked &&
            shouldUnlock &&
            !definition.initialAvailability) {
          _recentlyUnlockedHobbyIds.add(definition.id);
        }
      }
    }
    if (changed) {
      _state = _state.copyWith(hobbies: hobbies);
    }
    return changed;
  }

  Set<String> _unlockedJobIds(IdleState state) => {
    for (final entry in state.jobs.entries)
      if (entry.value.isUnlocked) entry.key,
  };

  Set<String> _unlockedHobbyIds(IdleState state) => {
    for (final entry in state.hobbies.entries)
      if (entry.value.isUnlocked) entry.key,
  };

  bool _reconcileTimeReservations({bool force = false}) {
    if (_rootTimeInfinite && !force) return false;
    final result = TimeReservationService.reconcile(_state);
    if (identical(result.state, _state) &&
        result.pausedJobIds.isEmpty &&
        result.pausedHobbyIds.isEmpty) {
      return false;
    }
    _state = result.state;
    for (final id in result.pausedJobIds) {
      _jobTimeWarnings[id] =
          'Pausado automaticamente para ajustar o Tempo disponível.';
    }
    for (final id in result.pausedHobbyIds) {
      _hobbyTimeWarnings[id] =
          'Pausado automaticamente para ajustar o Tempo disponível.';
    }
    return result.pausedJobIds.isNotEmpty || result.pausedHobbyIds.isNotEmpty;
  }

  String? _validateJobBoostPurchase(String id, {required bool free}) {
    if (!jobIds.contains(id)) return 'Emprego desconhecido.';
    final current = _state.jobs[id] ?? const ActivityProgress();
    if (!IdleRules.jobUnlocked(_state, id) || !current.isUnlocked) {
      return 'Emprego bloqueado.';
    }
    if (!current.active) return 'Inicie o trabalho para acelerar.';
    if (current.remainingBoostActiveTimeMs > 0) {
      return 'IMPULSO ATIVO — não acumula.';
    }
    if (!free && _state.diamonds < IdleBalance.jobBoostCherryCost) {
      final missing = IdleBalance.jobBoostCherryCost - _state.diamonds;
      return 'Faltam $missing Cerejas.';
    }
    return null;
  }

  String? _validateHobbyBoostPurchase(String id, {required bool free}) {
    if (!hobbyIds.contains(id)) return 'Hobby desconhecido.';
    final current = _state.hobbies[id] ?? const ActivityProgress();
    final hobby = IdleBalance.hobby(id);
    if (!IdleRules.hobbyUnlocked(_state, id) || !current.isUnlocked) {
      return 'Hobby bloqueado.';
    }
    if (current.level >= hobby.maximumLevel) return 'Hobby dominado.';
    if (!current.active) {
      return current.hasBeenStarted
          ? 'Retome o treino para acelerar.'
          : 'Inicie o treino para acelerar.';
    }
    if (current.remainingBoostActiveTimeMs > 0) {
      return 'IMPULSO ATIVO — não acumula.';
    }
    if (!free && _state.diamonds < IdleBalance.hobbyBoostCherryCost) {
      final missing = IdleBalance.hobbyBoostCherryCost - _state.diamonds;
      return 'Faltam $missing Cerejas.';
    }
    return null;
  }

  void _recordJobFeedbacks(SimulationSummary summary) {
    if (summary.jobEvents.isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final entry in summary.jobEvents.entries) {
      _jobFeedbacks[entry.key] = JobFeedbackRecord(
        jobId: entry.key,
        moneyEarned: entry.value.moneyEarned,
        cyclesCompleted: entry.value.cyclesCompleted,
        levelsGained: entry.value.levelsGained,
        resultingLevel: entry.value.progress.level,
        createdAtUtc: now,
      );
      _jobTimeWarnings.remove(entry.key);
      if (entry.value.boostExpired) {
        _jobBoostWarnings[entry.key] = 'Impulso x2 expirou.';
      }
    }
  }

  void _recordHobbyFeedbacks(SimulationSummary summary) {
    if (summary.hobbyEvents.isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final entry in summary.hobbyEvents.entries) {
      _hobbyFeedbacks[entry.key] = HobbyFeedbackRecord(
        hobbyId: entry.key,
        xpEarned: entry.value.xpEarned,
        cyclesCompleted: entry.value.cyclesCompleted,
        levelsGained: entry.value.levelsGained,
        resultingLevel: entry.value.progress.level,
        reachedMaximumLevel: entry.value.reachedMaximumLevel,
        createdAtUtc: now,
      );
      _hobbyTimeWarnings.remove(entry.key);
      if (entry.value.boostEndedByMastery) {
        _hobbyBoostWarnings[entry.key] = 'Impulso encerrado pelo domínio.';
      } else if (entry.value.boostExpired) {
        _hobbyBoostWarnings[entry.key] = 'Impulso x2 expirou.';
      }
    }
  }

  _AutomaticStageAdvanceSummary _applyAutomaticStageAdvancements() {
    final advanced = <_StageAdvanceOutcome>[];
    for (final route in CharacterRouteCatalog.all) {
      if (!_characterIsUnlocked(route.characterId)) continue;
      var safety = IdleRules.totalRelationshipStages;
      while (safety > 0 && IdleRules.canAdvance(_state, route.characterId)) {
        advanced.add(_advanceStageInMemory(route.characterId));
        safety--;
      }
    }
    return _AutomaticStageAdvanceSummary(advanced);
  }

  _StageAdvanceOutcome _advanceStageInMemory(String id) {
    id = _canonicalCharacterId(id);
    final current = _characterProgress(id);
    final nextStage = current.stage + 1;
    final now = DateTime.now().millisecondsSinceEpoch;
    final scenes = {...current.scenes};
    if ((current.stage + 1) % 3 == 0) {
      scenes.add('${id}_stage_${current.stage + 1}');
    }
    const ryomiScenes = {
      3: 'primeiro_encontro',
      5: 'vozes_madrugada',
      7: 'cidade_meia_noite',
      9: 'sem_esconder',
    };
    final galleryScene = ryomiScenes[nextStage];
    if (id == PlayableCharacterIds.roxanne && galleryScene != null) {
      scenes.add(galleryScene);
    }
    final episodeId = IdleBalance.storyEpisodeForStage(id, nextStage);
    final narrative = episodeId == null
        ? _state.narrative
        : _narrative.unlockEpisode(_state.narrative, episodeId);
    _state = _state.copyWith(
      characters: _charactersWithProgress(
        id,
        current.copyWith(
          stage: nextStage,
          affection: 0,
          lastPassiveAffectionAt: _passiveAffectionClockStartFor(
            nextStage,
            now,
          ),
          scenes: scenes,
        ),
      ),
      narrative: narrative,
    );
    _awardOfficialProgression(id, nextStage);
    return _StageAdvanceOutcome(stage: nextStage, storyEpisodeId: episodeId);
  }

  void _awardOfficialProgression(String characterId, int reachedStage) {
    final highest = _state.rewardedHighestStageByCharacter[characterId] ?? 0;
    if (reachedStage > highest) {
      _state = _state.copyWith(
        totalBlocks: _state.totalBlocks + 1,
        diamonds: _state.diamonds + 1 + (reachedStage == 9 ? 3 : 0),
        rewardedHighestStageByCharacter: {
          ..._state.rewardedHighestStageByCharacter,
          characterId: reachedStage,
        },
        trueLoveRewardClaimed: reachedStage == 9
            ? {..._state.trueLoveRewardClaimed, characterId}
            : _state.trueLoveRewardClaimed,
      );
    }
    _evaluateCharacterUnlocks();
  }

  void _evaluateCharacterUnlocks() {
    final stages = <String, int>{
      for (final definition in CharacterUnlockCatalog.definitions)
        definition.characterId: _characterProgress(
          definition.characterId,
        ).stage,
    };
    var characters = {..._state.characters};
    var diamonds = _state.diamonds;
    final claimed = {..._state.characterUnlockRewardClaimed};
    var changed = false;
    for (final definition in CharacterUnlockCatalog.definitions) {
      final current = characters[definition.characterId]!;
      if (current.unlocked ||
          !CharacterUnlockCatalog.isSatisfiedBy(definition, stages)) {
        continue;
      }
      characters = _charactersWithProgress(
        definition.characterId,
        current.copyWith(unlocked: true),
      );
      if (!definition.initiallyUnlocked &&
          claimed.add(definition.characterId)) {
        diamonds += 2;
      }
      changed = true;
    }
    if (changed) {
      _state = _state.copyWith(
        characters: characters,
        diamonds: diamonds,
        characterUnlockRewardClaimed: claimed,
      );
    }
  }

  void _applyRetroactiveProgressionRewards() {
    var blocks = _state.totalBlocks;
    var diamonds = _state.diamonds;
    final highest = {..._state.rewardedHighestStageByCharacter};
    final trueLove = {..._state.trueLoveRewardClaimed};
    final claimed = {..._state.characterUnlockRewardClaimed};
    var characters = {..._state.characters};
    for (final definition in CharacterUnlockCatalog.definitions) {
      final current = characters[definition.characterId]!;
      final stage = current.stage;
      final rewarded = highest[definition.characterId] ?? 0;
      if (stage > rewarded) {
        blocks += stage - rewarded;
        diamonds += stage - rewarded;
        highest[definition.characterId] = stage;
      }
      if (stage >= 9 && trueLove.add(definition.characterId)) diamonds += 3;
      if (!current.unlocked && (stage > 0 || definition.initiallyUnlocked)) {
        characters[definition.characterId] = current.copyWith(unlocked: true);
        if (!definition.initiallyUnlocked &&
            claimed.add(definition.characterId)) {
          diamonds += 2;
        }
      }
    }
    _state = _state.copyWith(
      totalBlocks: blocks,
      diamonds: diamonds,
      rewardedHighestStageByCharacter: highest,
      trueLoveRewardClaimed: trueLove,
      characterUnlockRewardClaimed: claimed,
      characters: characters,
    );
    _evaluateCharacterUnlocks();
  }

  int _passiveAffectionClockStartFor(int stage, int now) =>
      stage >= IdleBalance.passiveAffectionUnlockStage ? now : 0;

  Future<void> _save({bool quiet = false}) async {
    _directClickSaveTimer?.cancel();
    _directClickSavePending = false;
    if (!quiet) {
      _savePhase = SaveIndicatorPhase.saving;
      _saveError = null;
      _saveSequence++;
      notifyListeners();
    }
    try {
      await _storage.write(_state.encode());
      if (!quiet) {
        _savePhase = SaveIndicatorPhase.saved;
        _saveError = null;
        _saveSequence++;
        notifyListeners();
      }
    } catch (error) {
      if (!quiet) {
        _savePhase = SaveIndicatorPhase.error;
        _saveError = 'Falha ao salvar progresso.';
        _saveSequence++;
        notifyListeners();
      }
      rethrow;
    }
  }

  void _scheduleDirectClickSave() {
    _directClickSaveTimer?.cancel();
    if (!_directClickSavePending) {
      _directClickSavePending = true;
      _savePhase = SaveIndicatorPhase.saving;
      _saveError = null;
      _saveSequence++;
    }
    _directClickSaveTimer = Timer(
      const Duration(milliseconds: 350),
      _commitDirectClickSave,
    );
  }

  Future<void> _commitDirectClickSave() async {
    _directClickSaveTimer = null;
    _directClickSavePending = false;
    try {
      await _storage.write(_state.encode());
      _savePhase = SaveIndicatorPhase.saved;
      _saveError = null;
      _saveSequence++;
      notifyListeners();
    } catch (error) {
      _savePhase = SaveIndicatorPhase.error;
      _saveError = 'Falha ao salvar progresso.';
      _saveSequence++;
      notifyListeners();
    }
  }
}

class _AutomaticStageAdvanceSummary {
  const _AutomaticStageAdvanceSummary(this.advanced);

  final List<_StageAdvanceOutcome> advanced;
  bool get changed => advanced.isNotEmpty;
}

class _StageAdvanceOutcome {
  const _StageAdvanceOutcome({required this.stage, this.storyEpisodeId});

  final int stage;
  final String? storyEpisodeId;
}
