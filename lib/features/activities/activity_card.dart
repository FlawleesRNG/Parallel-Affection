import 'package:flutter/material.dart';

import '../../core/theme/game_tokens.dart';
import '../../services/game_audio_hooks.dart';

enum ActivityCardKind { job, hobby }

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.level,
    required this.experience,
    required this.experienceNeeded,
    required this.details,
    required this.status,
    required this.active,
    required this.unlocked,
    required this.onToggle,
    required this.accent,
    required this.kind,
    this.note,
    this.actionLabel,
    this.hideAction = false,
    this.progressValue,
  });

  final IconData icon;
  final String name;
  final String subtitle;
  final int level;
  final int experience;
  final int experienceNeeded;
  final String details;
  final String status;
  final bool active;
  final bool unlocked;
  final VoidCallback onToggle;
  final Color accent;
  final ActivityCardKind kind;
  final String? note;
  final String? actionLabel;
  final bool hideAction;
  final double? progressValue;

  @override
  Widget build(BuildContext context) {
    final isHobby = kind == ActivityCardKind.hobby;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isHobby ? Alignment.topCenter : Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .94),
            Color.lerp(accent, Colors.white, active ? .64 : .82)!,
            isHobby ? GameColors.roseBeige : GameColors.paper,
          ],
        ),
        borderRadius: isHobby
            ? const BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(26),
              )
            : BorderRadius.circular(GameRadii.medium),
        border: Border.all(
          color: active ? accent : accent.withValues(alpha: .32),
          width: active ? 2 : 1.3,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: .24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [
                BoxShadow(
                  color: GameColors.brownShadow,
                  blurRadius: 15,
                  offset: Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isHobby ? 46 : 40,
                height: isHobby ? 46 : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: .86),
                      Color.lerp(accent, Colors.white, .34)!,
                    ],
                  ),
                  shape: isHobby ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isHobby
                      ? null
                      : BorderRadius.circular(GameRadii.small),
                  border: Border.all(color: accent.withValues(alpha: .65)),
                ),
                child: Icon(icon, color: Colors.white, size: isHobby ? 24 : 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isHobby ? accent : GameColors.softInk,
                        fontSize: 11,
                        fontWeight: isHobby
                            ? FontWeight.w800
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: status,
                color: active
                    ? accent
                    : unlocked
                    ? GameColors.amber
                    : GameColors.locked,
              ),
            ],
          ),
          const Spacer(),
          if (note != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(GameRadii.pill),
                border: Border.all(color: accent.withValues(alpha: .35)),
              ),
              child: Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Text(
                'NÍVEL $level',
                style: const TextStyle(
                  color: GameColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                experienceNeeded <= 0
                    ? 'DOMINADO'
                    : '$experience / $experienceNeeded XP',
                style: const TextStyle(color: GameColors.softInk, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(GameRadii.pill),
            child: LinearProgressIndicator(
              value:
                  progressValue ??
                  (experienceNeeded <= 0
                      ? 1
                      : (experience / experienceNeeded).clamp(0, 1)),
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: .75),
              color: accent,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            details,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: GameColors.softInk, fontSize: 10.5),
          ),
          if (!hideAction) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: unlocked
                    ? () {
                        GameAudioHooks.emit(GameAudioCue.click);
                        onToggle();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: active ? Colors.white : accent,
                  foregroundColor: active ? accent : Colors.white,
                  elevation: 4,
                  shadowColor: accent.withValues(alpha: .28),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameRadii.pill),
                  ),
                ),
                icon: Icon(
                  !unlocked
                      ? Icons.lock_rounded
                      : active
                      ? Icons.pause_rounded
                      : isHobby
                      ? Icons.auto_awesome_rounded
                      : Icons.play_arrow_rounded,
                  size: 17,
                ),
                label: Text(
                  actionLabel ??
                      (!unlocked
                          ? 'Bloqueado'
                          : active
                          ? 'Pausar'
                          : isHobby
                          ? 'Praticar'
                          : 'Iniciar turno'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
