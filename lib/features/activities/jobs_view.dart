import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/idle_rules.dart';
import '../../core/job_requirement_evaluator.dart';
import '../../core/number_formatter.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../../models/idle_models.dart';
import '../../services/activity_runtime_service.dart';
import '../../services/game_audio_hooks.dart';
import '../../services/time_reservation_service.dart';
import 'activity_upgrade_button.dart';

enum _JobsFilter { all, active, available, locked, maximumLevel }

class JobsView extends StatefulWidget {
  const JobsView({super.key, required this.controller});

  final GameController controller;

  @override
  State<JobsView> createState() => _JobsViewState();
}

class _JobsViewState extends State<JobsView> {
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();
  _JobsFilter _filter = _JobsFilter.all;
  final Set<String> _confirmingBoostJobIds = {};

  GameController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final time = TimeReservationService.snapshot(state);
    final visibleJobs = IdleBalance.jobs.where((job) {
      final progress = state.jobs[job.id] ?? const ActivityProgress();
      final unlocked = IdleRules.jobUnlocked(state, job.id);
      return switch (_filter) {
        _JobsFilter.all => true,
        _JobsFilter.active => progress.active,
        _JobsFilter.available => unlocked && !progress.active,
        _JobsFilter.locked => !unlocked,
        _JobsFilter.maximumLevel => progress.level >= job.maximumLevel,
      };
    }).toList();

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF7EEDC)),
      child: Padding(
        padding: const EdgeInsets.all(GameSpacing.md),
        child: Column(
          children: [
            const _JobsHeader(),
            const SizedBox(height: 12),
            _JobsSummary(
              state: state,
              time: time,
              incomePerSecond: _currentIncomePerSecond(state),
            ),
            const SizedBox(height: 10),
            _JobsFilters(
              selected: _filter,
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visibleJobs.isEmpty
                  ? _EmptyJobsFilterMessage(filter: _filter)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 980;
                        final spacing = twoColumns ? 14.0 : 0.0;
                        final cardWidth = twoColumns
                            ? (constraints.maxWidth - spacing) / 2
                            : constraints.maxWidth;
                        return SingleChildScrollView(
                          key: const ValueKey('jobs_grid'),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: 14,
                            children: [
                              for (final job in visibleJobs)
                                SizedBox(
                                  width: cardWidth,
                                  child: _JobCard(
                                    key: ValueKey('job_card_${job.id}'),
                                    job: job,
                                    progress:
                                        state.jobs[job.id] ??
                                        const ActivityProgress(),
                                    state: state,
                                    time: time,
                                    now: _now,
                                    unlocked: IdleRules.jobUnlocked(
                                      state,
                                      job.id,
                                    ),
                                    recentlyUnlocked: controller
                                        .recentlyUnlockedJobIds
                                        .contains(job.id),
                                    feedback: controller.jobFeedbacks[job.id],
                                    timeWarning:
                                        controller.jobTimeWarnings[job.id],
                                    boostWarning:
                                        controller.jobBoostWarnings[job.id],
                                    confirmingBoost: _confirmingBoostJobIds
                                        .contains(job.id),
                                    onToggle: () async {
                                      await controller.toggle(
                                        ActivityKind.job,
                                        job.id,
                                      );
                                      GameAudioHooks.emit(GameAudioCue.menu);
                                    },
                                    onBoostPrompt: () => setState(
                                      () => _confirmingBoostJobIds.add(job.id),
                                    ),
                                    onBoostCancel: () => setState(
                                      () =>
                                          _confirmingBoostJobIds.remove(job.id),
                                    ),
                                    onBoostConfirm: () async {
                                      await controller.purchaseActivityUpgrade(
                                        ActivityKind.job,
                                        job.id,
                                      );
                                      if (mounted) {
                                        setState(
                                          () => _confirmingBoostJobIds.remove(
                                            job.id,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsHeader extends StatelessWidget {
  const _JobsHeader();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'Empregos. Trabalhe, evolua e construa sua independência.',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EF),
        borderRadius: BorderRadius.circular(GameRadii.large),
        border: Border.all(color: const Color(0xFF5B4351), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x405B4351),
            blurRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF70A77C),
              borderRadius: BorderRadius.circular(GameRadii.medium),
              border: Border.all(color: const Color(0xFF5B4351), width: 1.4),
            ),
            child: const Icon(
              Icons.work_rounded,
              color: Color(0xFFFFFCF6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMPREGOS',
                  style: TextStyle(
                    color: Color(0xFF3E303B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trabalhe, evolua e construa sua independência.',
                  style: TextStyle(
                    color: Color(0xFF75656E),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const _HeaderSparkles(),
        ],
      ),
    ),
  );
}

class _HeaderSparkles extends StatelessWidget {
  const _HeaderSparkles();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _sparkle(10, const Color(0xFFCF963A)),
      const SizedBox(width: 6),
      _sparkle(7, const Color(0xFF70A77C)),
    ],
  );

  Widget _sparkle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size),
    ),
  );
}

class _JobsSummary extends StatelessWidget {
  const _JobsSummary({
    required this.state,
    required this.time,
    required this.incomePerSecond,
  });

  final IdleState state;
  final TimeBudgetSnapshot time;
  final double incomePerSecond;

  @override
  Widget build(BuildContext context) {
    final active = IdleBalance.jobs
        .where((job) => state.jobs[job.id]?.active ?? false)
        .length;
    final mastered = IdleBalance.jobs
        .where(
          (job) =>
              (state.jobs[job.id]?.level ?? 1) >= IdleBalance.maximumJobLevel,
        )
        .length;
    final boosted = IdleBalance.jobs
        .where(
          (job) => (state.jobs[job.id]?.remainingBoostActiveTimeMs ?? 0) > 0,
        )
        .length;
    return Container(
      key: const ValueKey('jobs_overview_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(GameRadii.large),
        border: Border.all(color: const Color(0xFFA88991)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final width = compact
              ? (constraints.maxWidth - 8) / 2
              : (constraints.maxWidth - 32) / 5;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryTile(
                width: width,
                label: 'Renda atual',
                value: '${NumberFormatter.moneyDecimal(incomePerSecond)}/s',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFCF963A),
              ),
              _SummaryTile(
                width: width,
                label: 'Ativos',
                value: '$active',
                icon: Icons.play_circle_rounded,
                color: const Color(0xFF70A77C),
              ),
              _SummaryTile(
                width: width,
                label: 'Tempo livre',
                value: '${time.available} / ${time.capacity}',
                icon: Icons.schedule_rounded,
                color: const Color(0xFF4FA49D),
              ),
              _SummaryTile(
                width: width,
                label: 'Domínios',
                value: '$mastered / ${IdleBalance.jobs.length}',
                icon: Icons.military_tech_rounded,
                color: GameColors.purple,
              ),
              _SummaryTile(
                width: width,
                label: 'Impulsos',
                value: '$boosted',
                icon: Icons.flash_on_rounded,
                color: const Color(0xFFCF963A),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(GameRadii.medium),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF75656E),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3E303B),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _JobsFilters extends StatelessWidget {
  const _JobsFilters({required this.selected, required this.onSelected});

  final _JobsFilter selected;
  final ValueChanged<_JobsFilter> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final filter in _JobsFilter.values) ...[
          _FilterChipButton(
            filter: filter,
            selected: selected == filter,
            onTap: () => onSelected(filter),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _JobsFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Filtro ${_filterLabel(filter)}',
    child: InkWell(
      borderRadius: BorderRadius.circular(GameRadii.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF70A77C) : const Color(0xFFFFFCF6),
          borderRadius: BorderRadius.circular(GameRadii.pill),
          border: Border.all(color: const Color(0xFF5B4351), width: 1.2),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x405B4351),
                    blurRadius: 0,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          _filterLabel(filter),
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF3E303B),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

class _EmptyJobsFilterMessage extends StatelessWidget {
  const _EmptyJobsFilterMessage({required this.filter});

  final _JobsFilter filter;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(GameRadii.large),
        border: Border.all(color: const Color(0xFFA88991)),
      ),
      child: Text(
        switch (filter) {
          _JobsFilter.active => 'Nenhum trabalho ativo no momento.',
          _JobsFilter.locked => 'Nenhum trabalho bloqueado.',
          _JobsFilter.maximumLevel =>
            'Nenhum emprego alcançou o nível máximo ainda.',
          _JobsFilter.available => 'Nenhum emprego disponível no momento.',
          _JobsFilter.all => 'Nenhum emprego encontrado.',
        },
        style: const TextStyle(
          color: Color(0xFF75656E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    super.key,
    required this.job,
    required this.progress,
    required this.state,
    required this.time,
    required this.now,
    required this.unlocked,
    required this.recentlyUnlocked,
    required this.feedback,
    required this.timeWarning,
    required this.boostWarning,
    required this.confirmingBoost,
    required this.onToggle,
    required this.onBoostPrompt,
    required this.onBoostCancel,
    required this.onBoostConfirm,
  });

  final JobDefinition job;
  final ActivityProgress progress;
  final IdleState state;
  final TimeBudgetSnapshot time;
  final DateTime now;
  final bool unlocked;
  final bool recentlyUnlocked;
  final JobFeedbackRecord? feedback;
  final String? timeWarning;
  final String? boostWarning;
  final bool confirmingBoost;
  final VoidCallback onToggle;
  final VoidCallback onBoostPrompt;
  final VoidCallback onBoostCancel;
  final VoidCallback onBoostConfirm;

  @override
  Widget build(BuildContext context) {
    final active = progress.active;
    final maximumLevel = progress.level >= job.maximumLevel;
    final paused = !active && progress.hasBeenStarted;
    final hasTime =
        active || time.available >= job.timeCostAtLevel(progress.level);
    final status = _jobStatus(
      active: active,
      unlocked: unlocked,
      hasTime: hasTime,
      paused: paused,
      maximumLevel: maximumLevel,
    );
    final accent = _jobAccent(job.id);
    final currentRole = job.rankAtLevel(progress.level);
    final nextRole = IdleBalance.nextJobRoleTitle(job.id, progress.level);
    final income = ActivityRuntimeService.jobIncomePerCycle(
      job: job,
      progress: progress,
      state: state,
    );
    final incomePerSecond = ActivityRuntimeService.jobIncomePerSecond(
      job: job,
      progress: progress,
      state: state,
    );
    final cycleDuration = job.cycleDurationAtLevel(progress.level);
    final timeCost = job.timeCostAtLevel(progress.level);
    final reserved = TimeReservationService.reservedByJob(state, job.id);
    final requirementEvaluation = JobRequirementEvaluator.evaluate(state, job);
    final boostRemaining = ActivityRuntimeService.remainingJobBoostTime(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    final hasBoost = boostRemaining > Duration.zero;

    return Semantics(
      label:
          '${job.displayName}, $status, nível ${progress.level}, cargo $currentRole',
      child: GestureDetector(
        onTap: unlocked ? onToggle : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasBoost
                  ? const Color(0xFFCF963A)
                  : const Color(0xFF5B4351),
              width: hasBoost ? 1.9 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x405B4351),
                blurRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JobIcon(id: job.id, accent: accent, active: active),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _JobTitle(job: job, progress: progress),
                  ),
                  _StatusBadge(label: status, color: _statusColor(status)),
                  if (unlocked)
                    ActivityUpgradeButton(
                      activityName: job.displayName,
                      activityKindLabel: 'Emprego',
                      upgraded: progress.upgraded,
                      canAfford:
                          state.diamonds >=
                          IdleBalance.activityUpgradeCherryCost,
                      onConfirm: () async => onBoostConfirm(),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF75656E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _RolePanel(
                current:
                    'NÍVEL ${progress.level} — ${currentRole.toUpperCase()}',
                next: maximumLevel ? null : nextRole,
                maximumLevel: maximumLevel,
                accent: accent,
              ),
              if (recentlyUnlocked) ...[
                const SizedBox(height: 9),
                _UnlockedBanner(jobName: job.displayName, color: accent),
              ],
              if (feedback != null) ...[
                const SizedBox(height: 9),
                _JobFeedbackPanel(
                  feedback: feedback!,
                  job: job,
                  color: feedback!.hasLevelUp
                      ? accent
                      : const Color(0xFFCF963A),
                ),
              ],
              const SizedBox(height: 10),
              if (!unlocked)
                _LockedJobSection(
                  job: job,
                  requirements: requirementEvaluation.requirements,
                )
              else ...[
                _JobCycleSection(
                  job: job,
                  progress: progress,
                  state: state,
                  now: now,
                ),
                const SizedBox(height: 9),
                _JobXpSection(job: job, progress: progress, accent: accent),
                const SizedBox(height: 10),
                _StatsGrid(
                  items: [
                    ('Recompensa', NumberFormatter.money(income.round())),
                    ('XP', maximumLevel ? 'Máximo' : '${job.xpPerCycle}/ciclo'),
                    ('Duração', '${cycleDuration.inSeconds}s'),
                    ('Tempo', active ? 'Reservado $reserved' : '$timeCost'),
                    (
                      'Renda',
                      '${NumberFormatter.moneyDecimal(incomePerSecond)}/s',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _EfficiencyPanel(job: job, progress: progress, state: state),
              ],
              if (timeWarning != null) ...[
                const SizedBox(height: 9),
                _InlineWarning(text: timeWarning!),
              ] else if (unlocked && !active && !hasTime) ...[
                const SizedBox(height: 9),
                _InlineWarning(
                  text:
                      'Precisa de $timeCost Tempo\nDisponível: ${time.available}',
                ),
              ],
              const SizedBox(height: 4),
              Text(
                unlocked
                    ? (active
                          ? 'Toque no card para pausar'
                          : 'Toque no card para iniciar')
                    : 'Atividade bloqueada',
                style: const TextStyle(
                  color: Color(0xFF75656E),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobTitle extends StatelessWidget {
  const _JobTitle({required this.job, required this.progress});

  final JobDefinition job;
  final ActivityProgress progress;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        job.displayName.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF3E303B),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _TinyTag(label: _difficultyLabel(job.difficulty)),
          _TinyTag(label: 'NÍVEL ${progress.level}'),
        ],
      ),
    ],
  );
}

class _RolePanel extends StatelessWidget {
  const _RolePanel({
    required this.current,
    required this.next,
    required this.maximumLevel,
    required this.accent,
  });

  final String current;
  final String? next;
  final bool maximumLevel;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(GameRadii.medium),
      border: Border.all(color: accent.withValues(alpha: .28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          current,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          maximumLevel ? 'Domínio Máximo' : 'Próximo cargo: $next',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF75656E),
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
          ),
        ),
      ],
    ),
  );
}

class _LockedJobSection extends StatelessWidget {
  const _LockedJobSection({required this.job, required this.requirements});

  final JobDefinition job;
  final List<JobRequirementEvaluation> requirements;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StatsGrid(
        items: [
          ('Recompensa', NumberFormatter.money(job.rewardAtLevel(1))),
          ('Duração', '${job.cycleDurationAtLevel(1).inSeconds}s'),
          ('Tempo', '${job.timeCostAtLevel(1)}'),
        ],
      ),
      if (requirements.isNotEmpty) ...[
        const SizedBox(height: 9),
        _RequirementList(requirements: requirements),
      ],
    ],
  );
}

class _JobCycleSection extends StatelessWidget {
  const _JobCycleSection({
    required this.job,
    required this.progress,
    required this.state,
    required this.now,
  });

  final JobDefinition job;
  final ActivityProgress progress;
  final IdleState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final maximum = progress.level >= job.maximumLevel;
    final value = ActivityRuntimeService.jobCycleProgress(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    final remaining = ActivityRuntimeService.timeUntilNextJobCycle(
      job: job,
      progress: progress,
      state: state,
      now: now,
    );
    if (maximum) {
      final incomePerSecond = ActivityRuntimeService.jobIncomePerSecond(
        job: job,
        progress: progress,
        state: state,
      );
      return _ProgressBlock(
        semanticLabel: 'Barra de renda contínua de ${job.displayName}',
        label:
            'Produção contínua — ${NumberFormatter.moneyDecimal(incomePerSecond)}/s',
        valueLabel: progress.active
            ? 'Próximo pagamento — ${_formatSeconds(remaining)}'
            : 'Pausado',
        value: progress.active || progress.accumulatedCycleProgressMs > 0
            ? value
            : 0,
        color: const Color(0xFFCF963A),
      );
    }
    final label = progress.active
        ? 'Trabalho atual — ${_formatSeconds(remaining)} restantes'
        : progress.accumulatedCycleProgressMs > 0
        ? 'Pausado em ${(value * 100).round()}%'
        : 'Aguardando início';
    return _ProgressBlock(
      semanticLabel: 'Barra de ciclo de ${job.displayName}',
      label: label,
      valueLabel: progress.active ? _formatSeconds(remaining) : '',
      value: progress.active || progress.accumulatedCycleProgressMs > 0
          ? value
          : 0,
      color: const Color(0xFFCF963A),
    );
  }
}

class _JobXpSection extends StatelessWidget {
  const _JobXpSection({
    required this.job,
    required this.progress,
    required this.accent,
  });

  final JobDefinition job;
  final ActivityProgress progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final maximum = progress.level >= job.maximumLevel;
    final needed = IdleBalance.jobXpNeeded(job, progress.level);
    return _ProgressBlock(
      semanticLabel: 'Barra de XP de ${job.displayName}',
      label: maximum ? 'DOMÍNIO MÁXIMO' : 'XP ${progress.experience} / $needed',
      valueLabel: maximum ? 'Completo' : '${progress.experience} / $needed',
      value: maximum || needed <= 0 ? 1 : progress.experience / needed,
      color: accent,
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.semanticLabel,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.color,
  });

  final String semanticLabel;
  final String label;
  final String valueLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    value: label,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3E303B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (valueLabel.isNotEmpty)
              Text(
                valueLabel,
                style: const TextStyle(
                  color: Color(0xFF75656E),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(GameRadii.pill),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFF0DDC5),
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      for (final item in items)
        Container(
          constraints: const BoxConstraints(minWidth: 86),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EF),
            borderRadius: BorderRadius.circular(GameRadii.small),
            border: Border.all(color: const Color(0xFFE1CDB8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$1,
                style: const TextStyle(
                  color: Color(0xFF75656E),
                  fontSize: 9.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                item.$2,
                style: const TextStyle(
                  color: Color(0xFF3E303B),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _EfficiencyPanel extends StatelessWidget {
  const _EfficiencyPanel({
    required this.job,
    required this.progress,
    required this.state,
  });

  final JobDefinition job;
  final ActivityProgress progress;
  final IdleState state;

  @override
  Widget build(BuildContext context) {
    if (progress.level >= job.maximumLevel) {
      return const _InlineInfo(
        icon: Icons.all_inclusive_rounded,
        text: 'Produção Contínua ativa: pagamentos a cada 1 segundo.',
      );
    }
    final nextLevel = progress.level + 1;
    final currentDuration = job.cycleDurationAtLevel(progress.level).inSeconds;
    final nextDuration = job.cycleDurationAtLevel(nextLevel).inSeconds;
    final currentReward = job.rewardAtLevel(progress.level);
    final nextReward = job.rewardAtLevel(nextLevel);
    final currentTime = job.timeCostAtLevel(progress.level);
    final nextTime = job.timeCostAtLevel(nextLevel);
    final parts = <String>[
      if (currentDuration != nextDuration)
        'duração: ${currentDuration}s → ${nextDuration}s',
      'recompensa: ${NumberFormatter.money(currentReward)} → ${NumberFormatter.money(nextReward)}',
      if (currentTime != nextTime) 'Tempo: $currentTime → $nextTime',
    ];
    return _InlineInfo(
      icon: Icons.upgrade_rounded,
      text: 'Próximo nível: ${parts.join(' • ')}',
    );
  }
}

class _JobFeedbackPanel extends StatelessWidget {
  const _JobFeedbackPanel({
    required this.feedback,
    required this.job,
    required this.color,
  });

  final JobFeedbackRecord feedback;
  final JobDefinition job;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if (feedback.hasMoney) {
      lines.add('+${NumberFormatter.money(feedback.moneyEarned)}');
      lines.add(
        feedback.resultingLevel >= job.maximumLevel
            ? '${feedback.cyclesCompleted} pagamentos'
            : '${feedback.cyclesCompleted} ciclos',
      );
    }
    if (feedback.hasLevelUp) {
      lines.add(
        feedback.reachedMaximumLevel
            ? 'DOMÍNIO ALCANÇADO!'
            : 'NÍVEL ALCANÇADO!',
      );
      lines.add(
        feedback.reachedMaximumLevel
            ? 'Produção Contínua disponível'
            : job.rankAtLevel(feedback.resultingLevel),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(GameRadii.medium),
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Text(
        lines.join('\n'),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _JobActionButton extends StatelessWidget {
  const _JobActionButton({
    required this.job,
    required this.active,
    required this.unlocked,
    required this.hasTime,
    required this.paused,
    required this.timeCost,
    required this.onPressed,
  });

  final JobDefinition job;
  final bool active;
  final bool unlocked;
  final bool hasTime;
  final bool paused;
  final int timeCost;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = active
        ? 'PAUSAR'
        : !unlocked
        ? 'BLOQUEADO'
        : !hasTime
        ? 'SEM TEMPO'
        : paused
        ? 'RETOMAR — $timeCost TEMPO'
        : 'COMEÇAR — $timeCost TEMPO';
    return Semantics(
      button: true,
      label: 'Botão principal de ${job.displayName}: $label',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: ValueKey('job_toggle_${job.id}'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: active ? Colors.white : const Color(0xFF70A77C),
            foregroundColor: active ? const Color(0xFF70A77C) : Colors.white,
            disabledBackgroundColor: GameColors.locked.withValues(alpha: .18),
            disabledForegroundColor: GameColors.locked,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GameRadii.pill),
              side: const BorderSide(color: Color(0xFF5B4351), width: 1.2),
            ),
          ),
          icon: Icon(
            active
                ? Icons.pause_rounded
                : !unlocked || !hasTime
                ? Icons.lock_rounded
                : Icons.play_arrow_rounded,
            size: 18,
          ),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _JobBoostPanel extends StatelessWidget {
  const _JobBoostPanel({
    required this.job,
    required this.progress,
    required this.state,
    required this.now,
    required this.remaining,
    required this.confirming,
    required this.warning,
    required this.onPrompt,
    required this.onCancel,
    required this.onConfirm,
  });

  final JobDefinition job;
  final ActivityProgress progress;
  final IdleState state;
  final DateTime now;
  final Duration remaining;
  final bool confirming;
  final String? warning;
  final VoidCallback onPrompt;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final hasBoost = remaining > Duration.zero;
    final active = progress.active;
    final hasEnoughCherries = state.diamonds >= IdleBalance.jobBoostCherryCost;
    final missing = IdleBalance.jobBoostCherryCost - state.diamonds;
    final disabledReason = !active
        ? progress.hasBeenStarted
              ? 'Retome o trabalho para acelerar.'
              : 'Inicie o trabalho para acelerar.'
        : null;

    return Container(
      key: ValueKey('job_boost_panel_${job.id}'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFCF963A).withValues(alpha: hasBoost ? .16 : .08),
        borderRadius: BorderRadius.circular(GameRadii.medium),
        border: Border.all(
          color: const Color(
            0xFFCF963A,
          ).withValues(alpha: hasBoost ? .58 : .28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: Color(0xFFB8791D),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasBoost
                      ? progress.active
                            ? 'IMPULSO x2'
                            : 'IMPULSO PAUSADO'
                      : 'IMPULSO x2',
                  style: const TextStyle(
                    color: Color(0xFF3E303B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const _TinyTag(label: 'x2'),
            ],
          ),
          const SizedBox(height: 6),
          if (hasBoost)
            Text(
              '${_formatBoostDuration(remaining)} restantes',
              key: ValueKey('job_boost_timer_${job.id}'),
              style: const TextStyle(
                color: Color(0xFF75656E),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            )
          else if (confirming) ...[
            const Text(
              'Confirmar impulso x2 por 5 Cerejas?',
              style: TextStyle(
                color: Color(0xFF3E303B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (!hasEnoughCherries) ...[
              const SizedBox(height: 4),
              Text(
                'Faltam $missing Cerejas',
                style: const TextStyle(
                  color: GameColors.danger,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                FilledButton(
                  key: ValueKey('job_boost_confirm_${job.id}'),
                  onPressed: active && hasEnoughCherries ? onConfirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFCF963A),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('CONFIRMAR'),
                ),
                OutlinedButton(
                  key: ValueKey('job_boost_cancel_${job.id}'),
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('CANCELAR'),
                ),
              ],
            ),
          ] else ...[
            if (disabledReason != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  disabledReason,
                  style: const TextStyle(
                    color: Color(0xFF75656E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: ValueKey('job_boost_${job.id}'),
                onPressed: active ? onPrompt : null,
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text('ACELERAR — 5 CEREJAS'),
              ),
            ),
          ],
          if (warning != null && !hasBoost) ...[
            const SizedBox(height: 5),
            Text(
              warning!,
              style: const TextStyle(
                color: GameColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnlockedBanner extends StatelessWidget {
  const _UnlockedBanner({required this.jobName, required this.color});

  final String jobName;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(GameRadii.small),
      border: Border.all(color: color.withValues(alpha: .38)),
    ),
    child: Row(
      children: [
        Icon(Icons.lock_open_rounded, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'NOVO TRABALHO DISPONÍVEL\n$jobName',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RequirementList extends StatelessWidget {
  const _RequirementList({required this.requirements});

  final List<JobRequirementEvaluation> requirements;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Lista de requisitos do emprego',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: GameColors.amber.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(GameRadii.small),
        border: Border.all(color: GameColors.amber.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final requirement in requirements) ...[
            _RequirementRow(requirement: requirement),
            if (requirement != requirements.last) const SizedBox(height: 4),
          ],
          if (requirements.any(
            (item) =>
                item.type == JobRequirementType.money && !item.consumesResource,
          )) ...[
            const SizedBox(height: 5),
            const Text(
              'O saldo não será consumido.',
              style: TextStyle(
                color: Color(0xFF75656E),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.requirement});

  final JobRequirementEvaluation requirement;

  @override
  Widget build(BuildContext context) {
    final color = requirement.isMet ? GameColors.success : GameColors.softInk;
    return Row(
      children: [
        Icon(
          requirement.isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 13,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '${requirement.displayLabel} — ${requirement.progressLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => _InlineInfo(
    icon: Icons.warning_rounded,
    text: text,
    color: GameColors.warning,
  );
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({
    required this.icon,
    required this.text,
    this.color = const Color(0xFF75656E),
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(GameRadii.small),
      border: Border.all(color: color.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF7EEDC),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: const Color(0xFFA88991)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF75656E),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: color.withValues(alpha: .48)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 8.5,
      ),
    ),
  );
}

class _JobIcon extends StatelessWidget {
  const _JobIcon({
    required this.id,
    required this.accent,
    required this.active,
  });

  final String id;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          accent.withValues(alpha: active ? .95 : .78),
          Color.lerp(accent, Colors.white, .34)!,
        ],
      ),
      borderRadius: BorderRadius.circular(GameRadii.medium),
      border: Border.all(color: const Color(0xFF5B4351), width: 1.2),
    ),
    child: Icon(_jobIcon(id), color: Colors.white, size: 23),
  );
}

double _currentIncomePerSecond(IdleState state) {
  return IdleBalance.jobs.fold<double>(0, (total, job) {
    final progress = state.jobs[job.id] ?? const ActivityProgress();
    if (!progress.active) return total;
    return total +
        ActivityRuntimeService.jobIncomePerSecond(
          job: job,
          progress: progress,
          state: state,
        );
  });
}

String _filterLabel(_JobsFilter filter) => switch (filter) {
  _JobsFilter.all => 'Todos',
  _JobsFilter.active => 'Ativos',
  _JobsFilter.available => 'Disponíveis',
  _JobsFilter.locked => 'Bloqueados',
  _JobsFilter.maximumLevel => 'Nível máximo',
};

String _difficultyLabel(JobDifficulty difficulty) => switch (difficulty) {
  JobDifficulty.basic => 'Básico',
  JobDifficulty.intermediate => 'Intermediário',
  JobDifficulty.advanced => 'Avançado',
  JobDifficulty.special => 'Especial',
};

String _jobStatus({
  required bool active,
  required bool unlocked,
  required bool hasTime,
  required bool paused,
  required bool maximumLevel,
}) {
  if (active && maximumLevel) return 'PRODUÇÃO CONTÍNUA';
  if (active) return 'EM ANDAMENTO';
  if (!unlocked) return 'BLOQUEADO';
  if (!hasTime) return 'SEM TEMPO';
  if (paused) return 'PAUSADO';
  return 'DISPONÍVEL';
}

Color _statusColor(String status) => switch (status) {
  'EM ANDAMENTO' || 'PRODUÇÃO CONTÍNUA' => GameColors.jobsDark,
  'BLOQUEADO' || 'SEM TEMPO' => GameColors.locked,
  'PAUSADO' => GameColors.warning,
  _ => GameColors.success,
};

IconData _jobIcon(String id) => switch (id) {
  'neighborhood_deliveries' => Icons.delivery_dining_rounded,
  'local_flyering' => Icons.campaign_rounded,
  'cafe_assistant' => Icons.local_cafe_rounded,
  'game_store' => Icons.sports_esports_rounded,
  'gym_reception' => Icons.fitness_center_rounded,
  'freelance_photography' => Icons.photo_camera_rounded,
  'radio_assistant' => Icons.radio_rounded,
  'freelance_programmer' => Icons.code_rounded,
  'event_producer' => Icons.event_rounded,
  _ => Icons.work_rounded,
};

Color _jobAccent(String id) => switch (id) {
  'neighborhood_deliveries' => const Color(0xFF70A77C),
  'local_flyering' => const Color(0xFF87A75D),
  'cafe_assistant' => const Color(0xFFCF963A),
  'game_store' => GameColors.hobbiesDark,
  'gym_reception' => const Color(0xFF7BAE73),
  'freelance_photography' => GameColors.achievements,
  'radio_assistant' => const Color(0xFF3C8D93),
  'freelance_programmer' => const Color(0xFF497659),
  'event_producer' => GameColors.shopDark,
  _ => GameColors.jobsDark,
};

String _formatSeconds(Duration duration) {
  final milliseconds = duration.inMilliseconds.clamp(0, 999999);
  if (milliseconds == 0) return '0s';
  final seconds = milliseconds / 1000;
  if (seconds >= 10) return '${seconds.ceil()}s';
  return '${seconds.toStringAsFixed(1).replaceAll('.', ',')}s';
}

String _formatBoostDuration(Duration duration) {
  final totalSeconds = (duration.inMilliseconds / 1000).ceil().clamp(0, 5999);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
