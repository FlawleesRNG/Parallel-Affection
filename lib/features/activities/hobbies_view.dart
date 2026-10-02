import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/idle_rules.dart';
import '../../core/player_skill_service.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../../models/idle_models.dart';
import '../../services/activity_runtime_service.dart';
import '../../services/game_audio_hooks.dart';
import '../../services/time_reservation_service.dart';

enum _HobbiesFilter { all, active, available, locked, mastered }

const _hobbyBlue = Color(0xFF679CC0);
const _timeTeal = Color(0xFF4FA49D);
const _screenBackground = Color(0xFFF7EEDC);
const _paper = Color(0xFFFFF9EF);
const _elevated = Color(0xFFFFFCF6);
const _ink = Color(0xFF3E303B);
const _secondaryText = Color(0xFF75656E);
const _outline = Color(0xFF5B4351);
const _softOutline = Color(0xFFA88991);

class HobbiesView extends StatefulWidget {
  const HobbiesView({super.key, required this.controller});

  final GameController controller;

  @override
  State<HobbiesView> createState() => _HobbiesViewState();
}

class _HobbiesViewState extends State<HobbiesView> {
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();
  _HobbiesFilter _filter = _HobbiesFilter.all;
  final Set<String> _confirmingBoostHobbyIds = {};

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
    final hobbies = [...IdleBalance.hobbies]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final visibleHobbies = hobbies
        .where((hobby) {
          final progress = state.hobbies[hobby.id] ?? const ActivityProgress();
          final unlocked = IdleRules.hobbyUnlocked(state, hobby.id);
          final mastered = progress.level >= hobby.maximumLevel;
          return switch (_filter) {
            _HobbiesFilter.all => true,
            _HobbiesFilter.active => progress.active,
            _HobbiesFilter.available =>
              unlocked && !progress.active && !mastered,
            _HobbiesFilter.locked => !unlocked,
            _HobbiesFilter.mastered => mastered,
          };
        })
        .toList(growable: false);

    return DecoratedBox(
      decoration: const BoxDecoration(color: _screenBackground),
      child: Padding(
        padding: const EdgeInsets.all(GameSpacing.md),
        child: Column(
          children: [
            const _HobbiesHeader(),
            const SizedBox(height: 12),
            _HobbiesSummary(state: state, time: time),
            const SizedBox(height: 10),
            _HobbiesFilters(
              selected: _filter,
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visibleHobbies.isEmpty
                  ? _EmptyHobbiesFilterMessage(filter: _filter)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 980;
                        final spacing = twoColumns ? 14.0 : 0.0;
                        final rawCardWidth = twoColumns
                            ? (constraints.maxWidth - spacing) / 2
                            : constraints.maxWidth;
                        final cardWidth = twoColumns
                            ? rawCardWidth.clamp(420.0, 620.0)
                            : rawCardWidth;
                        return SingleChildScrollView(
                          key: const ValueKey('hobbies_grid'),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: spacing,
                            runSpacing: 14,
                            children: [
                              for (final hobby in visibleHobbies)
                                SizedBox(
                                  width: cardWidth,
                                  child: _HobbyCard(
                                    key: ValueKey('hobby_card_${hobby.id}'),
                                    hobby: hobby,
                                    progress:
                                        state.hobbies[hobby.id] ??
                                        const ActivityProgress(),
                                    state: state,
                                    time: time,
                                    now: _now,
                                    unlocked: IdleRules.hobbyUnlocked(
                                      state,
                                      hobby.id,
                                    ),
                                    recentlyUnlocked: controller
                                        .recentlyUnlockedHobbyIds
                                        .contains(hobby.id),
                                    feedback:
                                        controller.hobbyFeedbacks[hobby.id],
                                    timeWarning:
                                        controller.hobbyTimeWarnings[hobby.id],
                                    boostWarning:
                                        controller.hobbyBoostWarnings[hobby.id],
                                    rootCherriesInfinite:
                                        controller.rootCherriesInfinite,
                                    confirmingBoost: _confirmingBoostHobbyIds
                                        .contains(hobby.id),
                                    onToggle: () async {
                                      await controller.toggle(
                                        ActivityKind.hobby,
                                        hobby.id,
                                      );
                                      GameAudioHooks.emit(GameAudioCue.menu);
                                    },
                                    onBoostPrompt: () => setState(
                                      () => _confirmingBoostHobbyIds.add(
                                        hobby.id,
                                      ),
                                    ),
                                    onBoostCancel: () => setState(
                                      () => _confirmingBoostHobbyIds.remove(
                                        hobby.id,
                                      ),
                                    ),
                                    onBoostConfirm: () async {
                                      await controller.purchaseHobbyBoost(
                                        hobby.id,
                                      );
                                      if (mounted) {
                                        setState(
                                          () => _confirmingBoostHobbyIds.remove(
                                            hobby.id,
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

class _HobbiesHeader extends StatelessWidget {
  const _HobbiesHeader();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label:
        'Hobbies. Treine habilidades, descubra interesses e desenvolva seu potencial.',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(GameRadii.large),
        border: Border.all(color: _outline, width: 1.6),
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
              color: _hobbyBlue,
              borderRadius: BorderRadius.circular(GameRadii.medium),
              border: Border.all(color: _outline, width: 1.4),
            ),
            child: const Icon(
              Icons.palette_rounded,
              color: _elevated,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOBBIES',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Treine habilidades, descubra interesses e desenvolva seu potencial.',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const _HeaderBubbles(),
        ],
      ),
    ),
  );
}

class _HeaderBubbles extends StatelessWidget {
  const _HeaderBubbles();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _bubble(10, _hobbyBlue),
      const SizedBox(width: 6),
      _bubble(7, _timeTeal),
    ],
  );

  Widget _bubble(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size),
    ),
  );
}

class _HobbiesSummary extends StatelessWidget {
  const _HobbiesSummary({required this.state, required this.time});

  final IdleState state;
  final TimeBudgetSnapshot time;

  @override
  Widget build(BuildContext context) {
    final active = IdleBalance.hobbies
        .where((hobby) => state.hobbies[hobby.id]?.active ?? false)
        .length;
    final mastered = IdleBalance.hobbies
        .where(
          (hobby) =>
              (state.hobbies[hobby.id]?.level ?? 1) >= hobby.maximumLevel,
        )
        .length;
    final totalLevel = IdleBalance.hobbies.fold<int>(
      0,
      (total, hobby) => total + (state.hobbies[hobby.id]?.level ?? 1),
    );
    final boosted = IdleBalance.hobbies
        .where(
          (hobby) =>
              (state.hobbies[hobby.id]?.remainingBoostActiveTimeMs ?? 0) > 0,
        )
        .length;
    return Container(
      key: const ValueKey('hobbies_overview_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _elevated,
        borderRadius: BorderRadius.circular(GameRadii.large),
        border: Border.all(color: _softOutline),
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
                label: 'Ativos',
                value: '$active',
                icon: Icons.play_circle_rounded,
                color: _hobbyBlue,
              ),
              _SummaryTile(
                width: width,
                label: 'Tempo livre',
                value: '${time.available} / ${time.capacity}',
                icon: Icons.schedule_rounded,
                color: _timeTeal,
              ),
              _SummaryTile(
                width: width,
                label: 'Dominados',
                value: '$mastered / ${IdleBalance.hobbies.length}',
                icon: Icons.military_tech_rounded,
                color: GameColors.purple,
              ),
              _SummaryTile(
                width: width,
                label: 'Nível total',
                value: '$totalLevel',
                icon: Icons.auto_graph_rounded,
                color: GameColors.coral,
              ),
              _SummaryTile(
                width: width,
                label: 'Impulsos',
                value: '$boosted',
                icon: Icons.flash_on_rounded,
                color: GameColors.shop,
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
                      color: _secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
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

class _HobbiesFilters extends StatelessWidget {
  const _HobbiesFilters({required this.selected, required this.onSelected});

  final _HobbiesFilter selected;
  final ValueChanged<_HobbiesFilter> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final filter in _HobbiesFilter.values) ...[
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

  final _HobbiesFilter filter;
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
          color: selected ? _hobbyBlue : _elevated,
          borderRadius: BorderRadius.circular(GameRadii.pill),
          border: Border.all(color: _outline, width: 1.2),
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
            color: selected ? Colors.white : _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

class _EmptyHobbiesFilterMessage extends StatelessWidget {
  const _EmptyHobbiesFilterMessage({required this.filter});

  final _HobbiesFilter filter;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _elevated,
        borderRadius: BorderRadius.circular(GameRadii.large),
        border: Border.all(color: _softOutline),
      ),
      child: Text(
        switch (filter) {
          _HobbiesFilter.active =>
            'Nenhum Hobby está sendo treinado no momento.',
          _HobbiesFilter.available =>
            'Nenhum Hobby disponível para retomar ou iniciar.',
          _HobbiesFilter.locked => 'Nenhum Hobby bloqueado no momento.',
          _HobbiesFilter.mastered => 'Nenhum Hobby dominado ainda.',
          _HobbiesFilter.all => 'Nenhum Hobby encontrado.',
        },
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _secondaryText,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _HobbyCard extends StatelessWidget {
  const _HobbyCard({
    super.key,
    required this.hobby,
    required this.progress,
    required this.state,
    required this.time,
    required this.now,
    required this.unlocked,
    required this.recentlyUnlocked,
    required this.feedback,
    required this.timeWarning,
    required this.boostWarning,
    required this.rootCherriesInfinite,
    required this.confirmingBoost,
    required this.onToggle,
    required this.onBoostPrompt,
    required this.onBoostCancel,
    required this.onBoostConfirm,
  });

  final HobbyDefinition hobby;
  final ActivityProgress progress;
  final IdleState state;
  final TimeBudgetSnapshot time;
  final DateTime now;
  final bool unlocked;
  final bool recentlyUnlocked;
  final HobbyFeedbackRecord? feedback;
  final String? timeWarning;
  final String? boostWarning;
  final bool rootCherriesInfinite;
  final bool confirmingBoost;
  final VoidCallback onToggle;
  final VoidCallback onBoostPrompt;
  final VoidCallback onBoostCancel;
  final VoidCallback onBoostConfirm;

  @override
  Widget build(BuildContext context) {
    final mastered = progress.level >= hobby.maximumLevel;
    final active = progress.active && !mastered;
    final paused = !active && progress.hasBeenStarted && !mastered && unlocked;
    final timeCost = hobby.timeCostAtLevel(progress.level);
    final hasTime = active || time.available >= timeCost;
    final status = _hobbyStatus(
      active: active,
      unlocked: unlocked,
      mastered: mastered,
      paused: paused,
      hasTime: hasTime,
    );
    final trainingProgress = _trainingProgress(
      hobby: hobby,
      progress: progress,
      state: state,
      now: now,
    );
    final cycleDuration = hobby.trainingDurationAtLevel(progress.level);
    final xpNeeded = IdleBalance.hobbyXpNeeded(hobby, progress.level);
    final skill = PlayerSkillService.skillForHobby(hobby.id);
    final boostRemaining = ActivityRuntimeService.remainingHobbyBoostTime(
      hobby: hobby,
      progress: progress,
      state: state,
      now: now,
    );

    return Semantics(
      label:
          '${hobby.displayName}, $status, nível ${progress.level}, desenvolve ${skill.displayName}',
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _elevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? _hobbyBlue : _outline,
            width: active ? 1.9 : 1.5,
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
                _HobbyIcon(id: hobby.id, active: active, mastered: mastered),
                const SizedBox(width: 10),
                Expanded(
                  child: _HobbyTitle(
                    hobby: hobby,
                    skill: skill,
                    progress: progress,
                  ),
                ),
                _StatusBadge(label: status, color: _statusColor(status)),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              hobby.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.22,
              ),
            ),
            const SizedBox(height: 10),
            _SkillPanel(skill: skill, level: progress.level),
            if (recentlyUnlocked) ...[
              const SizedBox(height: 9),
              _LocalBanner(
                icon: Icons.auto_awesome_rounded,
                title: 'NOVO HOBBY DISPONÍVEL',
                message: hobby.displayName,
                color: _hobbyBlue,
              ),
            ],
            if (feedback != null) ...[
              const SizedBox(height: 9),
              _HobbyFeedbackPanel(
                feedback: feedback!,
                hobby: hobby,
                color: feedback!.reachedMaximumLevel
                    ? GameColors.purple
                    : _hobbyBlue,
              ),
            ],
            if (timeWarning != null) ...[
              const SizedBox(height: 9),
              _TimeWarningPanel(message: timeWarning!),
            ],
            const SizedBox(height: 10),
            if (!unlocked)
              _HobbyRequirementSection(hobby: hobby, state: state)
            else ...[
              _HobbyTrainingSection(
                hobby: hobby,
                progress: progress,
                state: state,
                now: now,
                trainingProgress: trainingProgress,
                status: status,
              ),
              const SizedBox(height: 9),
              _HobbyXpSection(
                progress: progress,
                xpNeeded: xpNeeded,
                mastered: mastered,
              ),
              const SizedBox(height: 10),
              _StatsGrid(
                items: [
                  (
                    'Treino',
                    mastered ? 'Dominado' : '${cycleDuration.inSeconds}s',
                  ),
                  ('XP', mastered ? 'Máximo' : '+${hobby.xpPerTrainingCycle}'),
                  ('Tempo', '$timeCost'),
                  ('Ciclos', '${progress.cycles}'),
                ],
              ),
              const SizedBox(height: 10),
              _NextLevelSection(hobby: hobby, progress: progress),
              const SizedBox(height: 10),
              _HobbyBoostPanel(
                hobby: hobby,
                progress: progress,
                state: state,
                remaining: boostRemaining,
                confirming: confirmingBoost,
                warning: boostWarning,
                rootCherriesInfinite: rootCherriesInfinite,
                onPrompt: onBoostPrompt,
                onCancel: onBoostCancel,
                onConfirm: onBoostConfirm,
              ),
            ],
            const SizedBox(height: 11),
            _HobbyActionSection(
              unlocked: unlocked,
              active: active,
              paused: paused,
              mastered: mastered,
              timeCost: timeCost,
              hasTime: hasTime,
              onToggle: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _HobbyIcon extends StatelessWidget {
  const _HobbyIcon({
    required this.id,
    required this.active,
    required this.mastered,
  });

  final String id;
  final bool active;
  final bool mastered;

  @override
  Widget build(BuildContext context) {
    final color = mastered
        ? GameColors.purple
        : active
        ? _timeTeal
        : _hobbyBlue;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(GameRadii.medium),
        border: Border.all(color: _outline, width: 1.3),
      ),
      child: Icon(_hobbyIcon(id), color: color, size: 23),
    );
  }
}

class _HobbyTitle extends StatelessWidget {
  const _HobbyTitle({
    required this.hobby,
    required this.skill,
    required this.progress,
  });

  final HobbyDefinition hobby;
  final PlayerSkillDefinition skill;
  final ActivityProgress progress;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        hobby.displayName.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: .45,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        skill.displayName.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _hobbyBlue,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        'NÍVEL ${progress.level}',
        style: const TextStyle(
          color: _secondaryText,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _SkillPanel extends StatelessWidget {
  const _SkillPanel({required this.skill, required this.level});

  final PlayerSkillDefinition skill;
  final int level;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: _hobbyBlue.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(GameRadii.medium),
      border: Border.all(color: _hobbyBlue.withValues(alpha: .28)),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        children: [
          const TextSpan(text: 'Desenvolve: '),
          TextSpan(
            text: '${skill.displayName} — Nível $level',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

class _HobbyTrainingSection extends StatelessWidget {
  const _HobbyTrainingSection({
    required this.hobby,
    required this.progress,
    required this.state,
    required this.now,
    required this.trainingProgress,
    required this.status,
  });

  final HobbyDefinition hobby;
  final ActivityProgress progress;
  final IdleState state;
  final DateTime now;
  final double trainingProgress;
  final String status;

  @override
  Widget build(BuildContext context) {
    final mastered = progress.level >= hobby.maximumLevel;
    final remaining = ActivityRuntimeService.timeUntilNextHobbyCycle(
      hobby: hobby,
      progress: progress,
      state: state,
      now: now,
    );
    final label = mastered
        ? 'HABILIDADE DOMINADA'
        : progress.active
        ? '${_formatSeconds(remaining)} restantes'
        : progress.hasBeenStarted
        ? 'PAUSADO EM ${(trainingProgress * 100).round()}%'
        : 'Pronto para treinar.';
    return _ProgressBlock(
      title: progress.active ? 'TREINO ATUAL' : status,
      label: label,
      value: mastered ? 1 : trainingProgress,
      color: _timeTeal,
    );
  }
}

class _HobbyXpSection extends StatelessWidget {
  const _HobbyXpSection({
    required this.progress,
    required this.xpNeeded,
    required this.mastered,
  });

  final ActivityProgress progress;
  final int xpNeeded;
  final bool mastered;

  @override
  Widget build(BuildContext context) => _ProgressBlock(
    title: 'XP',
    label: mastered
        ? 'HABILIDADE DOMINADA'
        : '${progress.experience} / $xpNeeded',
    value: mastered
        ? 1
        : xpNeeded <= 0
        ? 0
        : (progress.experience / xpNeeded).clamp(0, 1),
    color: mastered ? GameColors.purple : _hobbyBlue,
  );
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.title,
    required this.label,
    required this.value,
    required this.color,
  });

  final String title;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(GameRadii.pill),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 8,
          backgroundColor: _screenBackground,
          color: color,
        ),
      ),
    ],
  );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(
                  color: _screenBackground.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(GameRadii.medium),
                  border: Border.all(
                    color: _softOutline.withValues(alpha: .55),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _NextLevelSection extends StatelessWidget {
  const _NextLevelSection({required this.hobby, required this.progress});

  final HobbyDefinition hobby;
  final ActivityProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.level >= hobby.maximumLevel) {
      return const _InfoStrip(
        icon: Icons.workspace_premium_rounded,
        text: 'Domínio completo desta habilidade.',
        color: GameColors.purple,
      );
    }
    final currentDuration = hobby.trainingDurationAtLevel(progress.level);
    final nextDuration = hobby.trainingDurationAtLevel(progress.level + 1);
    final currentTime = hobby.timeCostAtLevel(progress.level);
    final nextTime = hobby.timeCostAtLevel(progress.level + 1);
    final timeChanges = currentTime != nextTime;
    final text = timeChanges
        ? 'Próximo nível: treino ${currentDuration.inSeconds}s → ${nextDuration.inSeconds}s • Tempo $currentTime → $nextTime'
        : 'Próximo nível: treino ${currentDuration.inSeconds}s → ${nextDuration.inSeconds}s';
    return _InfoStrip(
      icon: Icons.trending_up_rounded,
      text: text,
      color: _hobbyBlue,
    );
  }
}

class _HobbyRequirementSection extends StatelessWidget {
  const _HobbyRequirementSection({required this.hobby, required this.state});

  final HobbyDefinition hobby;
  final IdleState state;

  @override
  Widget build(BuildContext context) {
    final entries = hobby.requires.entries.toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GameColors.locked.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(GameRadii.medium),
        border: Border.all(color: _softOutline.withValues(alpha: .65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REQUER',
            style: TextStyle(
              color: _ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Text(
              hobby.unlockHint,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            for (final entry in entries) ...[
              _RequirementLine(entry: entry, state: state),
              if (entry != entries.last) const SizedBox(height: 5),
            ],
          const SizedBox(height: 8),
          const Text(
            'Nível inicial: 1',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.entry, required this.state});

  final MapEntry<String, int> entry;
  final IdleState state;

  @override
  Widget build(BuildContext context) {
    final targetId = entry.key.split(':').last;
    final target = IdleBalance.hobby(targetId);
    final current = state.hobbies[targetId]?.level ?? 0;
    final met = current >= entry.value;
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: met ? GameColors.success : _secondaryText,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${target.displayName} — Nível $current / ${entry.value}',
            style: TextStyle(
              color: met ? GameColors.success : _secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HobbyFeedbackPanel extends StatelessWidget {
  const _HobbyFeedbackPanel({
    required this.feedback,
    required this.hobby,
    required this.color,
  });

  final HobbyFeedbackRecord feedback;
  final HobbyDefinition hobby;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final skill = PlayerSkillService.skillForHobby(hobby.id);
    if (feedback.reachedMaximumLevel) {
      return _LocalBanner(
        icon: Icons.workspace_premium_rounded,
        title: 'HOBBY DOMINADO!',
        message: '${hobby.displayName} — ${skill.displayName} dominada.',
        color: color,
      );
    }
    if (feedback.hasLevelUp) {
      return _LocalBanner(
        icon: Icons.arrow_upward_rounded,
        title: 'NÍVEL ALCANÇADO!',
        message: '${hobby.displayName} — Nível ${feedback.resultingLevel}',
        color: color,
      );
    }
    if (feedback.hasXp) {
      return _LocalBanner(
        icon: Icons.add_rounded,
        title: '+${feedback.xpEarned} XP',
        message: '${feedback.cyclesCompleted} ciclo(s) concluído(s)',
        color: color,
      );
    }
    return const SizedBox.shrink();
  }
}

class _LocalBanner extends StatelessWidget {
  const _LocalBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(GameRadii.medium),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TimeWarningPanel extends StatelessWidget {
  const _TimeWarningPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(
      r'Precisa de (\d+) Tempo\. Disponível: (\d+)\.',
    ).firstMatch(message);
    final label = match == null
        ? message
        : 'Precisa de ${match.group(1)} Tempo\nDisponível: ${match.group(2)}';
    return _LocalBanner(
      icon: Icons.schedule_rounded,
      title: 'TEMPO INSUFICIENTE',
      message: label,
      color: GameColors.warning,
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(GameRadii.medium),
      border: Border.all(color: color.withValues(alpha: .24)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HobbyBoostPanel extends StatelessWidget {
  const _HobbyBoostPanel({
    required this.hobby,
    required this.progress,
    required this.state,
    required this.remaining,
    required this.confirming,
    required this.warning,
    required this.rootCherriesInfinite,
    required this.onPrompt,
    required this.onCancel,
    required this.onConfirm,
  });

  final HobbyDefinition hobby;
  final ActivityProgress progress;
  final IdleState state;
  final Duration remaining;
  final bool confirming;
  final String? warning;
  final bool rootCherriesInfinite;
  final VoidCallback onPrompt;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final hasBoost = remaining > Duration.zero;
    final active = progress.active;
    final mastered = progress.level >= hobby.maximumLevel;
    final hasEnoughCherries =
        rootCherriesInfinite ||
        state.diamonds >= IdleBalance.hobbyBoostCherryCost;
    final missing = IdleBalance.hobbyBoostCherryCost - state.diamonds;
    final disabledReason = mastered
        ? null
        : !active
        ? progress.hasBeenStarted
              ? 'Retome o treino para acelerar.'
              : 'Inicie o treino para acelerar.'
        : null;
    if (mastered && !hasBoost && !confirming && warning == null) {
      return const SizedBox.shrink();
    }

    return Container(
      key: ValueKey('hobby_boost_panel_${hobby.id}'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: GameColors.shop.withValues(alpha: hasBoost ? .15 : .08),
        borderRadius: BorderRadius.circular(GameRadii.medium),
        border: Border.all(
          color: GameColors.shop.withValues(alpha: hasBoost ? .58 : .28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: GameColors.shopDark,
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
                    color: _ink,
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
              key: ValueKey('hobby_boost_timer_${hobby.id}'),
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            )
          else if (confirming) ...[
            Text(
              'Acelerar este Hobby por ${IdleBalance.hobbyBoostActiveDuration.inMinutes} minutos?',
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Custo: ${IdleBalance.hobbyBoostCherryCost} Cerejas • Velocidade: x2',
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'O impulso termina se este Hobby for dominado.',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!hasEnoughCherries) ...[
              const SizedBox(height: 4),
              Text(
                'Faltam ${missing.clamp(0, 999999)} Cerejas',
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
                  key: ValueKey('hobby_boost_confirm_${hobby.id}'),
                  onPressed: active && hasEnoughCherries ? onConfirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: GameColors.shop,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('CONFIRMAR'),
                ),
                OutlinedButton(
                  key: ValueKey('hobby_boost_cancel_${hobby.id}'),
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
                    color: _secondaryText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: ValueKey('hobby_boost_${hobby.id}'),
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

class _HobbyActionSection extends StatelessWidget {
  const _HobbyActionSection({
    required this.unlocked,
    required this.active,
    required this.paused,
    required this.mastered,
    required this.timeCost,
    required this.hasTime,
    required this.onToggle,
  });

  final bool unlocked;
  final bool active;
  final bool paused;
  final bool mastered;
  final int timeCost;
  final bool hasTime;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (mastered) {
      return const SizedBox(
        width: double.infinity,
        child: _DisabledActionLabel(label: 'DOMINADO'),
      );
    }
    final enabled = unlocked;
    final label = !unlocked
        ? 'BLOQUEADO'
        : active
        ? 'PAUSAR'
        : paused
        ? 'RETOMAR — $timeCost TEMPO'
        : 'TREINAR — $timeCost TEMPO';
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: enabled
            ? () {
                GameAudioHooks.emit(GameAudioCue.click);
                onToggle();
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: active
              ? _elevated
              : hasTime
              ? _hobbyBlue
              : _timeTeal,
          foregroundColor: active ? _hobbyBlue : Colors.white,
          disabledBackgroundColor: _softOutline.withValues(alpha: .28),
          disabledForegroundColor: _secondaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameRadii.pill),
            side: BorderSide(color: active ? _hobbyBlue : _outline, width: 1.2),
          ),
        ),
        icon: Icon(
          !unlocked
              ? Icons.lock_rounded
              : active
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 18,
        ),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }
}

class _DisabledActionLabel extends StatelessWidget {
  const _DisabledActionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: GameColors.purple.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: GameColors.purple.withValues(alpha: .35)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: GameColors.purple,
        fontSize: 12,
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
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: color.withValues(alpha: .5)),
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

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: _softOutline.withValues(alpha: .7)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

String _filterLabel(_HobbiesFilter filter) => switch (filter) {
  _HobbiesFilter.all => 'Todos',
  _HobbiesFilter.active => 'Ativos',
  _HobbiesFilter.available => 'Disponíveis',
  _HobbiesFilter.locked => 'Bloqueados',
  _HobbiesFilter.mastered => 'Dominados',
};

String _hobbyStatus({
  required bool active,
  required bool unlocked,
  required bool mastered,
  required bool paused,
  required bool hasTime,
}) {
  if (mastered) return 'DOMINADO';
  if (!unlocked) return 'BLOQUEADO';
  if (active) return 'TREINANDO';
  if (paused) return 'PAUSADO';
  if (!hasTime) return 'SEM TEMPO';
  return 'DISPONÍVEL';
}

Color _statusColor(String status) => switch (status) {
  'TREINANDO' => _timeTeal,
  'DISPONÍVEL' => _hobbyBlue,
  'PAUSADO' => GameColors.warning,
  'BLOQUEADO' => GameColors.locked,
  'DOMINADO' => GameColors.purple,
  'SEM TEMPO' => GameColors.warning,
  _ => _hobbyBlue,
};

IconData _hobbyIcon(String id) => switch (id) {
  'leitura' => Icons.menu_book_rounded,
  'academia' => Icons.fitness_center_rounded,
  'teatro' => Icons.theater_comedy_rounded,
  'meditacao' => Icons.self_improvement_rounded,
  'videogames' => Icons.sports_esports_rounded,
  'musica' => Icons.music_note_rounded,
  'culinaria' => Icons.soup_kitchen_rounded,
  'fotografia' => Icons.photo_camera_rounded,
  'oratoria' => Icons.record_voice_over_rounded,
  _ => Icons.code_rounded,
};

double _trainingProgress({
  required HobbyDefinition hobby,
  required ActivityProgress progress,
  required IdleState state,
  required DateTime now,
}) {
  if (progress.level >= hobby.maximumLevel) return 1;
  if (progress.active) {
    return ActivityRuntimeService.hobbyCycleProgress(
      hobby: hobby,
      progress: progress,
      state: state,
      now: now,
    );
  }
  final cycleMs = ActivityRuntimeService.baseHobbyCycleMillis(
    hobby: hobby,
    level: progress.level,
  );
  if (cycleMs <= 0) return 0;
  return (progress.accumulatedCycleProgressMs / cycleMs).clamp(0, 1);
}

String _formatSeconds(Duration value) {
  final seconds = value.inSeconds.clamp(0, 999);
  final tenths = (value.inMilliseconds / 100).ceil() / 10;
  if (seconds <= 0 && value.inMilliseconds > 0) {
    return '${tenths.toStringAsFixed(1).replaceAll('.', ',')}s';
  }
  return '${seconds}s';
}

String _formatBoostDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 24 * 60 * 60);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return '$mm:$ss';
}
