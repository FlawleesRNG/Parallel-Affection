import '../data/idle_balance.dart';
import '../models/idle_models.dart';

enum TimeReservationOwnerType { job, hobby, futureActivity }

enum TimeReservationStatus {
  success,
  insufficientCapacity,
  alreadyReserved,
  notReserved,
  invalidAmount,
  unknownOwner,
  reconciled,
  pausedByReconciliation,
}

class TimeReservation {
  const TimeReservation({
    required this.ownerId,
    required this.ownerType,
    required this.amount,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.priorityOrder,
  });

  final String ownerId;
  final TimeReservationOwnerType ownerType;
  final int amount;
  final int createdAtUtc;
  final int updatedAtUtc;
  final int priorityOrder;

  String get key => '${ownerType.name}:$ownerId';
}

class TimeBudgetSnapshot {
  const TimeBudgetSnapshot({
    required this.capacity,
    required this.reserved,
    required this.available,
    required this.reservations,
  });

  final int capacity;
  final int reserved;
  final int available;
  final List<TimeReservation> reservations;
}

class TimeReservationResult {
  const TimeReservationResult({
    required this.status,
    required this.snapshot,
    this.message = '',
  });

  final TimeReservationStatus status;
  final TimeBudgetSnapshot snapshot;
  final String message;

  bool get isSuccess =>
      status == TimeReservationStatus.success ||
      status == TimeReservationStatus.alreadyReserved ||
      status == TimeReservationStatus.reconciled;
}

class TimeReconciliationResult {
  const TimeReconciliationResult({
    required this.state,
    required this.snapshot,
    this.pausedJobIds = const [],
    this.pausedHobbyIds = const [],
  });

  final IdleState state;
  final TimeBudgetSnapshot snapshot;
  final List<String> pausedJobIds;
  final List<String> pausedHobbyIds;
}

abstract final class TimeReservationService {
  static String ownerKey(TimeReservationOwnerType type, String id) =>
      '${type.name}:$id';

  static TimeBudgetSnapshot snapshot(IdleState state) {
    final reservations = reservationsFor(state);
    final reserved = reservations.fold<int>(
      0,
      (total, item) => total + item.amount,
    );
    final available = state.totalBlocks - reserved;
    return TimeBudgetSnapshot(
      capacity: state.totalBlocks,
      reserved: reserved,
      available: available < 0 ? 0 : available,
      reservations: reservations,
    );
  }

  static List<TimeReservation> reservationsFor(IdleState state) {
    final reservations = <TimeReservation>[];
    for (final item in IdleBalance.jobs.indexed) {
      final job = item.$2;
      final progress = state.jobs[job.id] ?? const ActivityProgress();
      if (!progress.active) continue;
      final amount = job.timeCostAtLevel(progress.level);
      if (amount <= 0) continue;
      reservations.add(
        TimeReservation(
          ownerId: job.id,
          ownerType: TimeReservationOwnerType.job,
          amount: amount,
          createdAtUtc: _createdAt(progress),
          updatedAtUtc: progress.lastProcessedAtUtc,
          priorityOrder: item.$1,
        ),
      );
    }
    for (final item in IdleBalance.hobbies.indexed) {
      final hobby = item.$2;
      final id = hobby.id;
      final progress = state.hobbies[id] ?? const ActivityProgress();
      if (!progress.active) continue;
      final amount = hobby.timeCostAtLevel(progress.level);
      if (amount <= 0) continue;
      reservations.add(
        TimeReservation(
          ownerId: id,
          ownerType: TimeReservationOwnerType.hobby,
          amount: amount,
          createdAtUtc: _createdAt(progress),
          updatedAtUtc: progress.cycleStartedAt,
          priorityOrder: 1000 + item.$1,
        ),
      );
    }
    if (state.activeEncounter case final encounter?) {
      final amount = encounterBlockCost[encounter.encounterId] ?? 0;
      if (amount > 0) {
        reservations.add(
          TimeReservation(
            ownerId: encounter.encounterId,
            ownerType: TimeReservationOwnerType.futureActivity,
            amount: amount,
            createdAtUtc: encounter.startedAt,
            updatedAtUtc: encounter.startedAt,
            priorityOrder: 2000,
          ),
        );
      }
    }
    reservations.sort(_compareReservationPriority);
    return reservations;
  }

  static TimeReservationResult canReserveJob(IdleState state, String jobId) {
    if (!jobIds.contains(jobId)) {
      return TimeReservationResult(
        status: TimeReservationStatus.unknownOwner,
        snapshot: snapshot(state),
        message: 'Trabalho desconhecido.',
      );
    }
    final progress = state.jobs[jobId] ?? const ActivityProgress();
    if (progress.active) {
      return TimeReservationResult(
        status: TimeReservationStatus.alreadyReserved,
        snapshot: snapshot(state),
        message: 'Reserva já existe.',
      );
    }
    final amount = IdleBalance.jobTimeCost(jobId, progress.level);
    if (amount < 0) {
      return TimeReservationResult(
        status: TimeReservationStatus.invalidAmount,
        snapshot: snapshot(state),
        message: 'Custo de Tempo inválido.',
      );
    }
    final current = snapshot(state);
    if (amount > current.available) {
      return TimeReservationResult(
        status: TimeReservationStatus.insufficientCapacity,
        snapshot: current,
        message:
            'Blocos de tempo insuficientes. Precisa de $amount Tempo. Disponível: ${current.available}.',
      );
    }
    return TimeReservationResult(
      status: TimeReservationStatus.success,
      snapshot: current,
    );
  }

  static TimeReservationResult canReserveHobby(
    IdleState state,
    String hobbyId,
  ) {
    final exists = IdleBalance.hobbies.any((item) => item.id == hobbyId);
    if (!exists) {
      return TimeReservationResult(
        status: TimeReservationStatus.unknownOwner,
        snapshot: snapshot(state),
        message: 'Hobby desconhecido.',
      );
    }
    final progress = state.hobbies[hobbyId] ?? const ActivityProgress();
    if (progress.active) {
      return TimeReservationResult(
        status: TimeReservationStatus.alreadyReserved,
        snapshot: snapshot(state),
        message: 'Reserva já existe.',
      );
    }
    final amount = IdleBalance.hobbyTimeCost(hobbyId, progress.level);
    if (amount < 0) {
      return TimeReservationResult(
        status: TimeReservationStatus.invalidAmount,
        snapshot: snapshot(state),
        message: 'Custo de Tempo inválido.',
      );
    }
    final current = snapshot(state);
    if (amount > current.available) {
      return TimeReservationResult(
        status: TimeReservationStatus.insufficientCapacity,
        snapshot: current,
        message:
            'Blocos de tempo insuficientes. Precisa de $amount Tempo. Disponível: ${current.available}.',
      );
    }
    return TimeReservationResult(
      status: TimeReservationStatus.success,
      snapshot: current,
    );
  }

  static TimeReservationResult releaseJob(IdleState state, String jobId) {
    if (!jobIds.contains(jobId)) {
      return TimeReservationResult(
        status: TimeReservationStatus.unknownOwner,
        snapshot: snapshot(state),
      );
    }
    final progress = state.jobs[jobId] ?? const ActivityProgress();
    return TimeReservationResult(
      status: progress.active
          ? TimeReservationStatus.success
          : TimeReservationStatus.notReserved,
      snapshot: snapshot(state),
    );
  }

  static TimeReservationResult releaseHobby(IdleState state, String hobbyId) {
    final exists = IdleBalance.hobbies.any((item) => item.id == hobbyId);
    if (!exists) {
      return TimeReservationResult(
        status: TimeReservationStatus.unknownOwner,
        snapshot: snapshot(state),
      );
    }
    final progress = state.hobbies[hobbyId] ?? const ActivityProgress();
    return TimeReservationResult(
      status: progress.active
          ? TimeReservationStatus.success
          : TimeReservationStatus.notReserved,
      snapshot: snapshot(state),
    );
  }

  static TimeReconciliationResult reconcile(IdleState state) {
    var reserved = 0;
    var changed = false;
    final pausedJobs = <String>[];
    final pausedHobbies = <String>[];
    final jobs = {...state.jobs};
    final hobbies = {...state.hobbies};
    final activeReservations = reservationsFor(state);

    for (final reservation in activeReservations) {
      final amount = reservation.amount;
      if (amount <= 0) continue;
      if (reserved + amount <= state.totalBlocks) {
        reserved += amount;
        continue;
      }
      switch (reservation.ownerType) {
        case TimeReservationOwnerType.job:
          final progress = jobs[reservation.ownerId];
          if (progress == null) continue;
          jobs[reservation.ownerId] = progress.copyWith(
            active: false,
            cycleStartedAt: 0,
          );
          pausedJobs.add(reservation.ownerId);
          changed = true;
        case TimeReservationOwnerType.hobby:
          final progress = hobbies[reservation.ownerId];
          if (progress == null) continue;
          hobbies[reservation.ownerId] = progress.copyWith(
            active: false,
            cycleStartedAt: 0,
          );
          pausedHobbies.add(reservation.ownerId);
          changed = true;
        case TimeReservationOwnerType.futureActivity:
          break;
      }
    }

    final reconciledState = changed
        ? state.copyWith(jobs: jobs, hobbies: hobbies)
        : state;
    return TimeReconciliationResult(
      state: reconciledState,
      snapshot: snapshot(reconciledState),
      pausedJobIds: pausedJobs,
      pausedHobbyIds: pausedHobbies,
    );
  }

  static int reservedByJob(IdleState state, String jobId) {
    final progress = state.jobs[jobId] ?? const ActivityProgress();
    if (!progress.active) return 0;
    return IdleBalance.jobTimeCost(jobId, progress.level);
  }

  static int costToStartJob(IdleState state, String jobId) {
    final progress = state.jobs[jobId] ?? const ActivityProgress();
    return IdleBalance.jobTimeCost(jobId, progress.level);
  }

  static int reservedByHobby(IdleState state, String hobbyId) {
    final progress = state.hobbies[hobbyId] ?? const ActivityProgress();
    if (!progress.active) return 0;
    return IdleBalance.hobbyTimeCost(hobbyId, progress.level);
  }

  static int costToStartHobby(IdleState state, String hobbyId) {
    final progress = state.hobbies[hobbyId] ?? const ActivityProgress();
    return IdleBalance.hobbyTimeCost(hobbyId, progress.level);
  }

  static int _createdAt(ActivityProgress progress) {
    if (progress.firstStartedAtUtc > 0) return progress.firstStartedAtUtc;
    if (progress.cycleStartedAt > 0) return progress.cycleStartedAt;
    if (progress.lastProcessedAtUtc > 0) return progress.lastProcessedAtUtc;
    return 1 << 40;
  }

  static int _compareReservationPriority(
    TimeReservation left,
    TimeReservation right,
  ) {
    final byCreated = left.createdAtUtc.compareTo(right.createdAtUtc);
    if (byCreated != 0) return byCreated;
    return left.priorityOrder.compareTo(right.priorityOrder);
  }
}
