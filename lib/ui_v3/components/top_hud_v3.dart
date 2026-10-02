import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/number_formatter.dart';
import '../../models/idle_models.dart';
import '../../services/time_reservation_service.dart';
import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';
import '../layout/ryomi_breakpoints_v3.dart';
import 'game_button_v3.dart';
import 'game_icon_medallion_v3.dart';
import 'phone_button_v3.dart';
import 'resource_module_v3.dart';

class TopHudV3 extends StatelessWidget {
  const TopHudV3({
    super.key,
    required this.state,
    required this.spec,
    required this.onSettings,
    this.savePhase = SaveIndicatorPhase.idle,
    this.saveError,
    this.saveSequence = 0,
  });

  final IdleState state;
  final RyomiLayoutSpec spec;
  final VoidCallback onSettings;
  final SaveIndicatorPhase savePhase;
  final String? saveError;
  final int saveSequence;

  @override
  Widget build(BuildContext context) {
    final metrics = _HudMetricsV3.fromSpec(spec);
    return SizedBox(
      key: const ValueKey('top_hud_v3'),
      height: spec.hudHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ConnectionsColorsV3.warmSurface,
          border: const Border(
            bottom: BorderSide(
              color: ConnectionsColorsV3.outlineSoft,
              width: ConnectionsShadowsV3.outlineThin,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: ConnectionsColorsV3.outline.withValues(alpha: .10),
              offset: const Offset(0, 4),
              blurRadius: 14,
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding,
                vertical: metrics.verticalPadding,
              ),
              child: Row(
                key: const ValueKey('top_hud_v3_single_line'),
                children: [
                  SizedBox(
                    width: metrics.identityWidth,
                    child: const _HudIdentityV3(),
                  ),
                  SizedBox(width: metrics.gap),
                  if (spec.usesDesktopFrame) ...[
                    _HudResourcesV3(state: state, metrics: metrics),
                    SizedBox(width: metrics.gap),
                    const Spacer(),
                  ] else
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('top_hud_v3_resource_scroll'),
                        scrollDirection: Axis.horizontal,
                        child: _HudResourcesV3(state: state, metrics: metrics),
                      ),
                    ),
                  PhoneButtonV3(compact: metrics.compactIconButtons),
                  SizedBox(width: metrics.iconGap),
                  _HudIconButtonV3(
                    key: const ValueKey('settings_v3'),
                    tooltip: 'Configurações',
                    semanticLabel: 'Configurações',
                    icon: Icons.settings_rounded,
                    color: ConnectionsColorsV3.prestige,
                    size: metrics.iconButtonSize,
                    onPressed: onSettings,
                  ),
                ],
              ),
            ),
            Positioned(
              right: metrics.saveIndicatorRight,
              top: 6,
              child: _HudSaveIndicatorV3(
                phase: savePhase,
                message: saveError,
                sequence: saveSequence,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudResourcesV3 extends StatelessWidget {
  const _HudResourcesV3({required this.state, required this.metrics});

  final IdleState state;
  final _HudMetricsV3 metrics;

  @override
  Widget build(BuildContext context) {
    final time = TimeReservationService.snapshot(state);
    return Row(
      children: [
        _HudResourceSlotV3(
          width: metrics.moneyWidth,
          child: ResourceModuleV3(
            key: const ValueKey('resource_money'),
            iconWidget: const _MoneyNoteIconV3(),
            label: 'Dinheiro',
            value: NumberFormatter.money(state.money),
            color: ConnectionsColorsV3.money,
            compact: metrics.compactResources,
            emphasized: true,
            tooltip: 'Dinheiro disponível',
            semanticLabel: 'Dinheiro: ${NumberFormatter.money(state.money)}',
          ),
        ),
        SizedBox(width: metrics.gap),
        _HudResourceSlotV3(
          width: metrics.cherriesWidth,
          child: ResourceModuleV3(
            key: const ValueKey('resource_cherries'),
            iconWidget: const _CherryCurrencyIconV3(),
            label: 'Cerejas',
            value: state.diamonds.toString(),
            color: ConnectionsColorsV3.cherries,
            compact: metrics.compactResources,
            tooltip: 'Cerejas',
            semanticLabel: 'Cerejas: ${state.diamonds}',
          ),
        ),
        SizedBox(width: metrics.gap),
        _HudResourceSlotV3(
          width: metrics.blocksWidth,
          child: ResourceModuleV3(
            key: const ValueKey('resource_time_blocks'),
            icon: Icons.watch_later_rounded,
            label: 'Tempo',
            value: '${time.available} / ${time.capacity}',
            color: ConnectionsColorsV3.timeBlocks,
            compact: metrics.compactResources,
            tooltip: 'Tempo disponível',
            semanticLabel:
                'Tempo disponível: ${time.available} de ${time.capacity}',
          ),
        ),
        SizedBox(width: metrics.gap),
        _HudResourceSlotV3(
          width: metrics.speedWidth,
          child: ResourceModuleV3(
            key: const ValueKey('resource_speed'),
            icon: Icons.bolt_rounded,
            label: 'Velocidade',
            value: 'x${state.speedMultiplier.toStringAsFixed(1)}',
            color: ConnectionsColorsV3.speed,
            compact: metrics.compactResources,
            tooltip: 'Multiplicador de velocidade',
            semanticLabel:
                'Multiplicador de velocidade: x${state.speedMultiplier.toStringAsFixed(1)}',
          ),
        ),
        SizedBox(width: metrics.gap),
        _HudResourceSlotV3(
          width: metrics.prestigeWidth,
          child: ResourceModuleV3(
            key: const ValueKey('resource_prestige'),
            icon: Icons.auto_awesome_rounded,
            label: 'Prestígio',
            value: '+${((state.prestigeBonus - 1) * 100).round()}%',
            color: ConnectionsColorsV3.prestige,
            compact: metrics.compactResources,
            tooltip: 'Bônus permanente de prestígio',
            semanticLabel:
                'Bônus permanente de prestígio: +${((state.prestigeBonus - 1) * 100).round()}%',
          ),
        ),
        SizedBox(width: metrics.gap),
      ],
    );
  }
}

class _HudMetricsV3 {
  const _HudMetricsV3({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.gap,
    required this.iconGap,
    required this.identityWidth,
    required this.moneyWidth,
    required this.cherriesWidth,
    required this.blocksWidth,
    required this.speedWidth,
    required this.prestigeWidth,
    required this.iconButtonSize,
    required this.compactResources,
    required this.compactIconButtons,
    required this.saveIndicatorRight,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double gap;
  final double iconGap;
  final double identityWidth;
  final double moneyWidth;
  final double cherriesWidth;
  final double blocksWidth;
  final double speedWidth;
  final double prestigeWidth;
  final double iconButtonSize;
  final bool compactResources;
  final bool compactIconButtons;
  final double saveIndicatorRight;

  factory _HudMetricsV3.fromSpec(RyomiLayoutSpec spec) {
    if (spec.isWideDesktop) {
      return const _HudMetricsV3(
        horizontalPadding: 16,
        verticalPadding: 8,
        gap: 8,
        iconGap: 8,
        identityWidth: 184,
        moneyWidth: 198,
        cherriesWidth: 120,
        blocksWidth: 122,
        speedWidth: 118,
        prestigeWidth: 118,
        iconButtonSize: 44,
        compactResources: false,
        compactIconButtons: false,
        saveIndicatorRight: 104,
      );
    }
    if (spec.isCompactDesktop || spec.isMobile || spec.isTablet) {
      return _HudMetricsV3(
        horizontalPadding: spec.isMobile ? 6 : 10,
        verticalPadding: spec.isMobile ? 6 : 7,
        gap: 4,
        iconGap: 4,
        identityWidth: spec.isMobile ? 116 : 132,
        moneyWidth: spec.isMobile ? 132 : 150,
        cherriesWidth: spec.isMobile ? 88 : 98,
        blocksWidth: spec.isMobile ? 92 : 98,
        speedWidth: spec.isMobile ? 88 : 94,
        prestigeWidth: spec.isMobile ? 88 : 92,
        iconButtonSize: spec.isMobile ? 34 : 38,
        compactResources: spec.isMobile || spec.shortHeight,
        compactIconButtons: true,
        saveIndicatorRight: spec.isMobile ? 84 : 92,
      );
    }
    return const _HudMetricsV3(
      horizontalPadding: 14,
      verticalPadding: 8,
      gap: 7,
      iconGap: 8,
      identityWidth: 170,
      moneyWidth: 180,
      cherriesWidth: 114,
      blocksWidth: 116,
      speedWidth: 112,
      prestigeWidth: 112,
      iconButtonSize: 44,
      compactResources: false,
      compactIconButtons: false,
      saveIndicatorRight: 104,
    );
  }
}

class _HudResourceSlotV3 extends StatelessWidget {
  const _HudResourceSlotV3({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}

class _HudIdentityV3 extends StatelessWidget {
  const _HudIdentityV3();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Conexões',
    child: ExcludeSemantics(
      child: DecoratedBox(
        key: const ValueKey('game_identity_v3'),
        decoration: BoxDecoration(
          color: ConnectionsColorsV3.paperElevated,
          border: Border.all(
            color: ConnectionsColorsV3.outline,
            width: ConnectionsShadowsV3.outlineThin,
          ),
          borderRadius: BorderRadius.circular(ConnectionsRadiusV3.large),
          boxShadow: [
            BoxShadow(
              color: ConnectionsColorsV3.relationshipDark.withValues(
                alpha: .18,
              ),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              const GameIconMedallionV3(
                icon: Icons.favorite_rounded,
                size: 28,
                color: ConnectionsColorsV3.relationship,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conexões',
                  overflow: TextOverflow.ellipsis,
                  style: ConnectionsTypographyV3.gameTitle(size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HudIconButtonV3 extends StatelessWidget {
  const _HudIconButtonV3({
    super.key,
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: GameButtonV3(
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      color: color,
      compact: size < 40,
      child: Icon(icon, size: size < 40 ? 18 : 21),
    ),
  );
}

class _HudSaveIndicatorV3 extends StatefulWidget {
  const _HudSaveIndicatorV3({
    required this.phase,
    required this.sequence,
    this.message,
  });

  final SaveIndicatorPhase phase;
  final int sequence;
  final String? message;

  @override
  State<_HudSaveIndicatorV3> createState() => _HudSaveIndicatorV3State();
}

class _HudSaveIndicatorV3State extends State<_HudSaveIndicatorV3> {
  Timer? _hideTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _syncVisibility();
  }

  @override
  void didUpdateWidget(covariant _HudSaveIndicatorV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sequence != widget.sequence ||
        oldWidget.phase != widget.phase) {
      _syncVisibility();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _syncVisibility() {
    _hideTimer?.cancel();
    if (widget.phase == SaveIndicatorPhase.idle) {
      _visible = false;
      return;
    }
    _visible = true;
    if (widget.phase == SaveIndicatorPhase.saved) {
      _hideTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _visible = false);
      });
    } else if (widget.phase == SaveIndicatorPhase.error) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final label = switch (phase) {
      SaveIndicatorPhase.saving => 'Salvando…',
      SaveIndicatorPhase.saved => 'Salvo',
      SaveIndicatorPhase.error => 'Falha ao salvar',
      SaveIndicatorPhase.idle => '',
    };
    final color = phase == SaveIndicatorPhase.error
        ? ConnectionsColorsV3.error
        : phase == SaveIndicatorPhase.saving
        ? ConnectionsColorsV3.info
        : ConnectionsColorsV3.success;
    final tooltip = phase == SaveIndicatorPhase.error
        ? widget.message ?? 'Falha ao salvar progresso.'
        : label;

    if (!_visible || phase == SaveIndicatorPhase.idle) {
      return const SizedBox.shrink(key: ValueKey('save_indicator_v3'));
    }
    return IgnorePointer(
      ignoring: phase != SaveIndicatorPhase.error,
      child: Tooltip(
        message: tooltip,
        child: AnimatedOpacity(
          key: const ValueKey('save_indicator_v3'),
          opacity: 1,
          duration: const Duration(milliseconds: 180),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ConnectionsColorsV3.paperElevated,
              border: Border.all(
                color: color,
                width: ConnectionsShadowsV3.outlineThin,
              ),
              borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
              boxShadow: [
                BoxShadow(
                  color: ConnectionsColorsV3.outline.withValues(alpha: .12),
                  offset: const Offset(0, 3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                label,
                style: ConnectionsTypographyV3.badge(
                  size: 10.5,
                ).copyWith(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyNoteIconV3 extends StatelessWidget {
  const _MoneyNoteIconV3();

  @override
  Widget build(BuildContext context) => const SizedBox(
    key: ValueKey('money_note_icon_v3'),
    width: 18,
    height: 14,
    child: CustomPaint(painter: _MoneyNotePainterV3()),
  );
}

class _MoneyNotePainterV3 extends CustomPainter {
  const _MoneyNotePainterV3();

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = ConnectionsColorsV3.onColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = ConnectionsColorsV3.onColor.withValues(alpha: .24)
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);
    canvas.drawCircle(size.center(Offset.zero), size.height * .25, border);
    canvas.drawLine(
      Offset(size.width * .12, size.height * .28),
      Offset(size.width * .28, size.height * .28),
      border,
    );
    canvas.drawLine(
      Offset(size.width * .72, size.height * .72),
      Offset(size.width * .88, size.height * .72),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CherryCurrencyIconV3 extends StatelessWidget {
  const _CherryCurrencyIconV3();

  @override
  Widget build(BuildContext context) => const SizedBox(
    key: ValueKey('cherries_icon_v3'),
    width: 20,
    height: 20,
    child: CustomPaint(painter: _CherryPainterV3()),
  );
}

class _CherryPainterV3 extends CustomPainter {
  const _CherryPainterV3();

  @override
  void paint(Canvas canvas, Size size) {
    final cherry = Paint()..color = const Color(0xFFFFF9F2);
    final leaf = Paint()..color = const Color(0xFFCFE8B6);
    final stem = Paint()
      ..color = ConnectionsColorsV3.onColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final left = Offset(size.width * .36, size.height * .66);
    final right = Offset(size.width * .66, size.height * .68);
    final top = Offset(size.width * .52, size.height * .20);
    canvas.drawLine(left.translate(1, -4), top, stem);
    canvas.drawLine(right.translate(-1, -4), top, stem);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .66, size.height * .22),
        width: size.width * .28,
        height: size.height * .16,
      ),
      leaf,
    );
    canvas.drawCircle(left, size.width * .22, cherry);
    canvas.drawCircle(right, size.width * .22, cherry);
    canvas.drawCircle(
      left.translate(-2, -2),
      size.width * .055,
      Paint()..color = Colors.white.withValues(alpha: .72),
    );
    canvas.drawCircle(
      right.translate(-2, -2),
      size.width * .055,
      Paint()..color = Colors.white.withValues(alpha: .72),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
