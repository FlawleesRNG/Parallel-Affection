import 'package:flutter/material.dart';

import '../design/connections_design.dart';
import 'pop_journal_shapes.dart';

class PopJournalButton extends StatefulWidget {
  const PopJournalButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.darkColor,
    required this.onPressed,
    this.subtitle,
    this.height = 78,
    this.iconSize = 34,
    this.enabled = true,
    this.locked = false,
    this.lockReason,
    this.cooldownRemaining,
    this.cooldownTotal,
    this.cooldownKey,
    this.selected = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color darkColor;
  final VoidCallback? onPressed;
  final double height;
  final double iconSize;
  final bool enabled;
  final bool locked;
  final String? lockReason;
  final Duration? cooldownRemaining;
  final Duration? cooldownTotal;
  final Key? cooldownKey;
  final bool selected;

  bool get coolingDown =>
      cooldownRemaining != null && cooldownRemaining! > Duration.zero;
  bool get available => enabled && !locked && !coolingDown;

  @override
  State<PopJournalButton> createState() => _PopJournalButtonState();
}

class _PopJournalButtonState extends State<PopJournalButton> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = hovered || widget.selected;
    final color = widget.locked
        ? Color.lerp(widget.color, ConnectionsColors.disabled, .46)!
        : widget.color;
    final dark = widget.locked
        ? Color.lerp(widget.darkColor, ConnectionsColors.disabled, .42)!
        : widget.darkColor;
    final progress = _cooldownProgress();
    final enabledTap = widget.available && widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabledTap,
      selected: widget.selected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: GestureDetector(
          onTapDown: enabledTap ? (_) => setState(() => pressed = true) : null,
          onTapCancel: enabledTap
              ? () => setState(() => pressed = false)
              : null,
          onTapUp: enabledTap ? (_) => setState(() => pressed = false) : null,
          onTap: enabledTap ? widget.onPressed : null,
          child: AnimatedSlide(
            duration: ConnectionsMotion.hover,
            offset: Offset(
              0,
              pressed
                  ? .035
                  : active
                  ? -.025
                  : 0,
            ),
            child: AnimatedScale(
              duration: ConnectionsMotion.press,
              scale: pressed ? .98 : 1,
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  children: [
                    Positioned(
                      left: 3,
                      right: 3,
                      bottom: 0,
                      height: widget.height - 6,
                      child: ClipPath(
                        clipper: const PopJournalButtonClipper(),
                        child: ColoredBox(color: dark),
                      ),
                    ),
                    Positioned.fill(
                      bottom: 6,
                      child: PhysicalShape(
                        clipper: const PopJournalButtonClipper(),
                        color: color,
                        elevation: 0,
                        child: ClipPath(
                          clipper: const PopJournalButtonClipper(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.lerp(color, Colors.white, .28)!,
                                  color,
                                  Color.lerp(color, dark, .55)!,
                                ],
                              ),
                              border: Border.all(
                                color: widget.selected
                                    ? Colors.white
                                    : ConnectionsColors.outline,
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 14,
                                  right: 14,
                                  top: 7,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .34,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        ConnectionsRadius.pill,
                                      ),
                                    ),
                                  ),
                                ),
                                if (progress != null)
                                  Positioned.fill(
                                    key: widget.cooldownKey,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: progress,
                                        alignment: Alignment.bottomCenter,
                                        child: ColoredBox(
                                          color: Colors.white.withValues(
                                            alpha: .22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final compact = constraints.maxWidth < 86;
                                      final iconBox = compact
                                          ? widget.iconSize + 5
                                          : widget.iconSize + 12;
                                      final iconSize = compact
                                          ? widget.iconSize * .78
                                          : widget.iconSize;
                                      final labelSize = compact ? 10.5 : 14.5;
                                      final content = compact
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _IconMedallion(
                                                  icon: widget.locked
                                                      ? Icons.lock_rounded
                                                      : widget.icon,
                                                  color: color,
                                                  dark: dark,
                                                  size: iconBox,
                                                  iconSize: iconSize,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  widget.label,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.fade,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: labelSize,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1,
                                                    shadows: const [
                                                      Shadow(
                                                        color: Color(
                                                          0x66000000,
                                                        ),
                                                        blurRadius: 3,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                _IconMedallion(
                                                  icon: widget.locked
                                                      ? Icons.lock_rounded
                                                      : widget.icon,
                                                  color: color,
                                                  dark: dark,
                                                  size: iconBox,
                                                  iconSize: iconSize,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        widget.label
                                                            .toUpperCase(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .visible,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: labelSize,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          height: 1,
                                                          shadows: const [
                                                            Shadow(
                                                              color: Color(
                                                                0x66000000,
                                                              ),
                                                              blurRadius: 3,
                                                              offset: Offset(
                                                                0,
                                                                1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _subtitle(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: .92,
                                                              ),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                      return Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          compact ? 7 : 11,
                                          compact ? 12 : 13,
                                          compact ? 7 : 11,
                                          compact ? 10 : 10,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: constraints.maxWidth,
                                              maxHeight: constraints.maxHeight,
                                            ),
                                            child: content,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.selected)
                      const Positioned(
                        key: ValueKey('pop_journal_button_selected_indicator'),
                        left: 8,
                        top: 8,
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (widget.locked) return widget.lockReason ?? 'Bloqueado';
    if (widget.coolingDown) {
      return '${widget.cooldownRemaining!.inSeconds.ceil()}s restantes';
    }
    return widget.subtitle ?? '';
  }

  double? _cooldownProgress() {
    if (!widget.coolingDown || widget.cooldownTotal == null) return null;
    final total = widget.cooldownTotal!.inMilliseconds;
    if (total <= 0) return null;
    return (widget.cooldownRemaining!.inMilliseconds / total).clamp(0.0, 1.0);
  }
}

class _IconMedallion extends StatelessWidget {
  const _IconMedallion({
    required this.icon,
    required this.color,
    required this.dark,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final Color color;
  final Color dark;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .90),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: dark.withValues(alpha: .45), width: 2),
    ),
    child: Icon(icon, color: color, size: iconSize),
  );
}
