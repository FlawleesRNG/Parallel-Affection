import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_formatter.dart';
import '../core/theme/game_tokens.dart';
import '../core/theme/visual_themes.dart';
import '../data/narrative_catalog.dart';
import '../models/idle_models.dart';
import '../services/game_audio_hooks.dart';

class CutePanel extends StatelessWidget {
  const CutePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GameSpacing.md),
    this.color,
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: gradient == null ? color ?? GameColors.paper : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(GameRadii.large),
      border: Border.all(color: borderColor ?? GameColors.cuteStroke),
      boxShadow: const [
        BoxShadow(
          color: GameColors.brownShadow,
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GameSpacing.md),
    this.color,
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => CutePanel(
    padding: padding,
    color: color,
    borderColor: borderColor,
    gradient: gradient,
    child: child,
  );
}

typedef CuteResourceBadge = ResourcePill;
typedef CuteBottomMenu = GameBottomDock;
typedef NavigationStickerButton = GameBottomDock;
typedef GameNavButton = GameBottomDock;
typedef CuteCharacterActionButton = GameActionButton;
typedef IllustratedGameButton = GameActionButton;
typedef StickerButton = GameActionButton;
typedef CharacterActionButton = GameActionButton;
typedef IllustratedResourceBadge = ResourcePill;
typedef GameResourceChip = ResourcePill;

abstract final class ArcadeRebuildMetrics {
  static const hudHeight = 72.0;
  static const hudModuleBorder = 3.0;
  static const hudIconSize = 31.0;
  static const hudShadowOffset = 7.0;
  static const dockHeight = 104.0;
  static const dockButtonHeight = 86.0;
  static const dockIconSize = 40.0;
  static const dockBorderWidth = 4.0;
  static const dockShadowOffset = 8.0;
  static const dockSelectedLift = 8.0;
  static const actionButtonHeight = 94.0;
  static const actionIconSize = 38.0;
  static const actionBorderWidth = 4.0;
  static const actionShadowOffset = 8.0;
  static const affectionBarHeight = 30.0;
  static const dialogueMinHeight = 142.0;
  static const dialogueBorderWidth = 3.0;
}

class ArcadePieceClipper extends CustomClipper<Path> {
  const ArcadePieceClipper({this.skew = 10});

  final double skew;

  @override
  Path getClip(Size size) {
    final s = skew.clamp(4.0, size.width * .12).toDouble();
    return Path()
      ..moveTo(18 + s, 0)
      ..lineTo(size.width - 22, 0)
      ..quadraticBezierTo(size.width - 5, 0, size.width - 3, 17)
      ..lineTo(size.width - 11, size.height - 16)
      ..quadraticBezierTo(
        size.width - 13,
        size.height,
        size.width - 31,
        size.height,
      )
      ..lineTo(18, size.height)
      ..quadraticBezierTo(2, size.height, 1, size.height - 17)
      ..lineTo(8, 22)
      ..quadraticBezierTo(10, 5, 18 + s, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant ArcadePieceClipper oldClipper) =>
      oldClipper.skew != skew;
}

class ArcadePanelClipper extends CustomClipper<Path> {
  const ArcadePanelClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(18, 0)
    ..lineTo(size.width - 20, 0)
    ..quadraticBezierTo(size.width, 0, size.width, 20)
    ..lineTo(size.width - 8, size.height - 18)
    ..quadraticBezierTo(
      size.width - 10,
      size.height,
      size.width - 28,
      size.height,
    )
    ..lineTo(18, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - 18)
    ..lineTo(8, 20)
    ..quadraticBezierTo(9, 0, 18, 0)
    ..close();

  @override
  bool shouldReclip(covariant ArcadePanelClipper oldClipper) => false;
}

class CuteBackdropPattern extends StatelessWidget {
  const CuteBackdropPattern({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CuteBackdropPainter(),
    child: const SizedBox.expand(),
  );
}

class _CuteBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withValues(alpha: .30);
    final peach = Paint()..color = GameColors.money.withValues(alpha: .10);
    final pink = Paint()..color = GameColors.relation.withValues(alpha: .08);
    for (var x = 24.0; x < size.width; x += 96) {
      for (var y = 28.0; y < size.height; y += 88) {
        canvas.drawCircle(Offset(x, y), 2.4, dot);
      }
    }
    for (var i = 0; i < 9; i++) {
      final x = (i * 137.0 + 52) % size.width;
      final y = (i * 83.0 + 44) % size.height;
      _drawHeart(canvas, Offset(x, y), 8 + (i % 3) * 2.0, pink);
    }
    for (var i = 0; i < 8; i++) {
      final center = Offset(
        (i * 151.0 + 120) % size.width,
        (i * 71.0 + 95) % size.height,
      );
      final path = Path()
        ..moveTo(center.dx, center.dy - 7)
        ..lineTo(center.dx + 3, center.dy - 2)
        ..lineTo(center.dx + 8, center.dy)
        ..lineTo(center.dx + 3, center.dy + 2)
        ..lineTo(center.dx, center.dy + 7)
        ..lineTo(center.dx - 3, center.dy + 2)
        ..lineTo(center.dx - 8, center.dy)
        ..lineTo(center.dx - 3, center.dy - 2)
        ..close();
      canvas.drawPath(path, peach);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * .42)
      ..cubicTo(
        center.dx - size * 1.3,
        center.dy - size * .2,
        center.dx - size * .45,
        center.dy - size * 1.05,
        center.dx,
        center.dy - size * .42,
      )
      ..cubicTo(
        center.dx + size * .45,
        center.dy - size * 1.05,
        center.dx + size * 1.3,
        center.dy - size * .2,
        center.dx,
        center.dy + size * .42,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.accent = GameColors.amber,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final copy = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, Color.lerp(accent, Colors.white, .35)!],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
      if (trailing != null && constraints.maxWidth < 700) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [copy, const SizedBox(height: 9), trailing!],
        );
      }
      return Row(
        children: [
          Expanded(child: copy),
          ?trailing,
        ],
      );
    },
  );
}

class ResourcePill extends StatefulWidget {
  const ResourcePill({
    super.key,
    required this.icon,
    required this.value,
    required this.tooltip,
    this.tint = GameColors.amber,
  });

  final IconData icon;
  final String value;
  final String tooltip;
  final Color tint;

  @override
  State<ResourcePill> createState() => _ResourcePillState();
}

class _ResourcePillState extends State<ResourcePill> {
  bool flash = false;

  @override
  void didUpdateWidget(covariant ResourcePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    flash = true;
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => flash = false);
    });
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tooltip,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 42,
      padding: const EdgeInsets.fromLTRB(6, 4, 11, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            flash
                ? Color.lerp(widget.tint, Colors.white, .48)!
                : Color.lerp(widget.tint, Colors.white, .72)!,
            Colors.white.withValues(alpha: .92),
            Color.lerp(
              widget.tint,
              GameColors.ink,
              .08,
            )!.withValues(alpha: .42),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: flash
              ? Colors.white
              : Color.lerp(widget.tint, GameColors.ink, .18)!,
          width: flash ? 2.2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(
              widget.tint,
              GameColors.ink,
              .28,
            )!.withValues(alpha: .28),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .78),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(widget.tint, Colors.white, .12)!,
                  Color.lerp(widget.tint, GameColors.ink, .12)!,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.tint.withValues(alpha: .34),
                  blurRadius: 9,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(widget.icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              widget.value,
              key: ValueKey(widget.value),
              style: const TextStyle(
                color: GameColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class GameResourceBar extends StatelessWidget {
  const GameResourceBar({
    super.key,
    required this.state,
    required this.onSettings,
  });

  final IdleState state;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    const visual = GameVisualTheme.current;
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        gradient: visual.hudGradient,
        border: Border(
          bottom: BorderSide(
            color: GameColors.outlineSoft.withValues(alpha: .38),
            width: 1.5,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: GameColors.brownShadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: visual.brandAccent.withValues(alpha: .35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    visual.brandIcon,
                    color: visual.brandAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CONEXÕES',
                  style: TextStyle(
                    color: GameColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  ResourcePill(
                    key: const ValueKey('resource_money'),
                    icon: Icons.account_balance_wallet_outlined,
                    value: NumberFormatter.money(state.money),
                    tooltip: 'Dinheiro disponível',
                    tint: GameColors.money,
                  ),
                  const SizedBox(width: 8),
                  ResourcePill(
                    key: const ValueKey('resource_diamonds'),
                    icon: Icons.diamond_outlined,
                    value: '${state.diamonds}',
                    tooltip: 'Cerejas',
                    tint: GameColors.diamonds,
                  ),
                  const SizedBox(width: 8),
                  ResourcePill(
                    key: const ValueKey('resource_time_blocks'),
                    icon: Icons.schedule_rounded,
                    value: '${state.availableBlocks}/${state.totalBlocks}',
                    tooltip: 'Blocos de tempo livres',
                    tint: GameColors.timeBlocks,
                  ),
                  const SizedBox(width: 8),
                  ResourcePill(
                    key: const ValueKey('resource_speed'),
                    icon: Icons.bolt_rounded,
                    value: 'x${state.speedMultiplier.toStringAsFixed(1)}',
                    tooltip: 'Velocidade da simulação',
                    tint: GameColors.warning,
                  ),
                  const SizedBox(width: 8),
                  ResourcePill(
                    key: const ValueKey('resource_prestige'),
                    icon: Icons.auto_awesome_rounded,
                    value: '+${((state.prestigeBonus - 1) * 100).round()}%',
                    tooltip: 'Bônus permanente de prestígio',
                    tint: GameColors.prestige,
                  ),
                ],
              ),
            ),
          ),
          Tooltip(
            message: 'Progresso salvo automaticamente',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GameColors.success.withValues(alpha: .36),
                  ),
                ),
                child: Icon(
                  Icons.cloud_done_outlined,
                  size: 20,
                  color: GameColors.success.withValues(alpha: .95),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Configurações',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            color: GameColors.ink,
          ),
          const SizedBox(width: 7),
        ],
      ),
    );
  }
}

class ArcadeResourceBar extends StatelessWidget {
  const ArcadeResourceBar({
    super.key,
    required this.state,
    required this.onSettings,
  });

  final IdleState state;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    const visual = GameVisualTheme.current;
    return Container(
      key: const ValueKey('game_resource_bar'),
      height: ArcadeRebuildMetrics.hudHeight,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB5CB), Color(0xFFFFD77E), Color(0xFFFFF1BC)],
          stops: [0, .55, 1],
        ),
        border: Border(
          bottom: BorderSide(
            color: GameColors.outline.withValues(alpha: .48),
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.outline.withValues(alpha: .24),
            blurRadius: 20,
            offset: const Offset(0, ArcadeRebuildMetrics.hudShadowOffset),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: const ArcadePanelClipper(),
              child: ColoredBox(color: Colors.white.withValues(alpha: .27)),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 10),
                child: Row(
                  children: [
                    PhysicalShape(
                      clipper: const ArcadePieceClipper(skew: 6),
                      color: visual.brandAccent,
                      elevation: 6,
                      shadowColor: visual.brandAccent.withValues(alpha: .45),
                      child: SizedBox(
                        width: 52,
                        height: 48,
                        child: Center(
                          child: Icon(
                            visual.brandIcon,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'CONEXÕES',
                      style: TextStyle(
                        color: GameColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _ArcadeHudDivider(color: GameColors.relation),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Row(
                    children: [
                      _ArcadeHudModule(
                        key: const ValueKey('resource_money'),
                        icon: Icons.account_balance_wallet_rounded,
                        value: NumberFormatter.money(state.money),
                        tooltip: 'Dinheiro disponível',
                        color: GameColors.money,
                        wide: true,
                      ),
                      const SizedBox(width: 7),
                      _ArcadeHudModule(
                        key: const ValueKey('resource_diamonds'),
                        icon: Icons.diamond_rounded,
                        value: '${state.diamonds}',
                        tooltip: 'Cerejas',
                        color: GameColors.diamonds,
                      ),
                      const SizedBox(width: 7),
                      _ArcadeHudModule(
                        key: const ValueKey('resource_time_blocks'),
                        icon: Icons.schedule_rounded,
                        value: '${state.availableBlocks}/${state.totalBlocks}',
                        tooltip: 'Blocos de tempo livres',
                        color: GameColors.timeBlocks,
                      ),
                      const SizedBox(width: 7),
                      _ArcadeHudModule(
                        key: const ValueKey('resource_speed'),
                        icon: Icons.bolt_rounded,
                        value: 'x${state.speedMultiplier.toStringAsFixed(1)}',
                        tooltip: 'Velocidade da simulação',
                        color: GameColors.warning,
                      ),
                      const SizedBox(width: 7),
                      _ArcadeHudModule(
                        key: const ValueKey('resource_prestige'),
                        icon: Icons.auto_awesome_rounded,
                        value: '+${((state.prestigeBonus - 1) * 100).round()}%',
                        tooltip: 'Bônus permanente de prestígio',
                        color: GameColors.prestige,
                      ),
                    ],
                  ),
                ),
              ),
              _ArcadeHudDivider(color: GameColors.shop),
              Tooltip(
                message: 'Progresso salvo automaticamente',
                child: PhysicalShape(
                  clipper: const ArcadePieceClipper(skew: 5),
                  color: GameColors.success,
                  elevation: 5,
                  child: const SizedBox(
                    width: 48,
                    height: 44,
                    child: Icon(
                      Icons.cloud_done_rounded,
                      size: 27,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: 'Configurações',
                onPressed: onSettings,
                icon: const Icon(Icons.settings_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: GameColors.more,
                  fixedSize: const Size(44, 44),
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcadeHudModule extends StatelessWidget {
  const _ArcadeHudModule({
    super.key,
    required this.icon,
    required this.value,
    required this.tooltip,
    required this.color,
    this.wide = false,
  });

  final IconData icon;
  final String value;
  final String tooltip;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: PhysicalShape(
      clipper: const ArcadePieceClipper(skew: 7),
      color: color,
      elevation: 6,
      shadowColor: Color.lerp(color, GameColors.ink, .28)!,
      child: ClipPath(
        clipper: const ArcadePieceClipper(skew: 7),
        child: Container(
          height: 52,
          width: wide ? 184 : 122,
          padding: const EdgeInsets.fromLTRB(8, 6, 13, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, Colors.white, .36)!,
                color,
                Color.lerp(color, GameColors.ink, .27)!,
              ],
            ),
            border: Border.all(
              color: Color.lerp(color, GameColors.ink, .42)!,
              width: ArcadeRebuildMetrics.hudModuleBorder,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 8,
                right: 8,
                top: 1,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .48),
                    borderRadius: BorderRadius.circular(GameRadii.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: ArcadeRebuildMetrics.hudIconSize + 6,
                    height: ArcadeRebuildMetrics.hudIconSize + 6,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Color.lerp(color, GameColors.ink, .25)!,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameColors.ink.withValues(alpha: .22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: ArcadeRebuildMetrics.hudIconSize,
                      color: Color.lerp(color, GameColors.ink, .12),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        fontFeatures: [FontFeature.tabularFigures()],
                        shadows: [
                          Shadow(
                            color: Color(0x88000000),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ArcadeHudDivider extends StatelessWidget {
  const _ArcadeHudDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: Colors.white.withValues(alpha: .7), width: 2),
      boxShadow: [
        BoxShadow(
          color: GameColors.ink.withValues(alpha: .16),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
  );
}

class GameDockItem {
  const GameDockItem(
    this.id,
    this.label,
    this.icon,
    this.color, {
    this.hasNew = false,
  });
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool hasNew;
}

class GameBottomDock extends StatelessWidget {
  const GameBottomDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const items = [
    GameDockItem(
      'paixoes',
      'Paixões',
      Icons.favorite_rounded,
      GameColors.relation,
      hasNew: true,
    ),
    GameDockItem('empregos', 'Empregos', Icons.work_rounded, GameColors.jobs),
    GameDockItem(
      'hobbies',
      'Hobbies',
      Icons.auto_awesome_rounded,
      GameColors.hobbies,
    ),
    GameDockItem(
      'estatisticas',
      'Estatísticas',
      Icons.query_stats_rounded,
      GameColors.blue,
    ),
    GameDockItem(
      'conquistas',
      'Conquistas',
      Icons.emoji_events_rounded,
      GameColors.achievements,
    ),
    GameDockItem('loja', 'Loja', Icons.shopping_bag_rounded, GameColors.shop),
    GameDockItem(
      'extras',
      'Extras',
      Icons.auto_awesome_motion_rounded,
      GameColors.more,
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('game_bottom_dock_bar'),
    height: 90,
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      gradient: GameVisualTheme.current.dockGradient,
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: .76), width: 2),
      ),
      boxShadow: const [
        BoxShadow(
          color: GameColors.brownShadow,
          blurRadius: 20,
          offset: Offset(0, -5),
        ),
      ],
    ),
    child: Row(
      children: List.generate(
        items.length,
        (index) => Expanded(
          child: _DockControl(
            key: ValueKey('dock_${items[index].id}'),
            item: items[index],
            selected: selectedIndex == index,
            compact: MediaQuery.sizeOf(context).width < 600,
            onTap: () => onSelected(index),
          ),
        ),
      ),
    ),
  );
}

class _DockControl extends StatefulWidget {
  const _DockControl({
    super.key,
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final GameDockItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_DockControl> createState() => _DockControlState();
}

class _DockControlState extends State<_DockControl> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || hovered;
    final topLight = Color.lerp(widget.item.color, Colors.white, .36)!;
    final base = Color.lerp(widget.item.color, Colors.white, .14)!;
    final bottom = Color.lerp(widget.item.color, GameColors.ink, .20)!;
    final inactiveText = Color.lerp(widget.item.color, GameColors.ink, .68)!;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onHover: (value) => setState(() => hovered = value),
        onHighlightChanged: (value) => setState(() => pressed = value),
        onTap: () {
          GameAudioHooks.emit(GameAudioCue.menu);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(
            0,
            pressed
                ? 4
                : widget.selected
                ? -6
                : 0,
            0,
          ),
          margin: EdgeInsets.symmetric(horizontal: widget.compact ? 2 : 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: active
                  ? [topLight, widget.item.color, bottom]
                  : [topLight.withValues(alpha: .94), base, bottom],
              stops: const [0, .55, 1],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(19),
              bottomRight: Radius.circular(26),
            ),
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: .90)
                  : Color.lerp(widget.item.color, GameColors.ink, .24)!,
              width: widget.selected ? 2.6 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: bottom.withValues(alpha: active ? .48 : .36),
                blurRadius: active ? 18 : 10,
                offset: Offset(0, active ? 8 : 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: active ? .80 : .48),
                blurRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 12,
                right: 12,
                top: 7,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: active ? .26 : .18),
                    borderRadius: BorderRadius.circular(GameRadii.pill),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: widget.compact ? 28 : 34,
                      height: widget.compact ? 28 : 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: active ? .25 : .18,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .72),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        widget.item.icon,
                        size: widget.compact ? 18 : 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        color: active ? Colors.white : inactiveText,
                        fontWeight: FontWeight.w900,
                        fontSize: widget.compact ? 9 : 11.5,
                        letterSpacing: .15,
                        shadows: active
                            ? const [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selected)
                Positioned(
                  left: 8,
                  top: 7,
                  child: Container(
                    key: ValueKey('dock_${widget.item.id}_selected'),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.item.color.withValues(alpha: .42),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: widget.item.color,
                      size: 13,
                    ),
                  ),
                ),
              if (widget.item.hasNew)
                Positioned(
                  right: widget.compact ? 5 : 12,
                  top: 6,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: widget.item.color, width: 2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: widget.item.color, blurRadius: 7),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArcadeBottomDock extends StatelessWidget {
  const ArcadeBottomDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const items = GameBottomDock.items;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Container(
      key: const ValueKey('game_bottom_dock_bar'),
      height: ArcadeRebuildMetrics.dockHeight,
      padding: EdgeInsets.fromLTRB(compact ? 6 : 10, 10, compact ? 6 : 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3C7), Color(0xFFFFB3C8), Color(0xFFFF8FB0)],
        ),
        border: Border(
          top: BorderSide(
            color: GameColors.outline.withValues(alpha: .45),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.outline.withValues(alpha: .25),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: _ArcadeDockButton(
                key: ValueKey('dock_${items[index].label.toLowerCase()}'),
                item: items[index],
                selected: selectedIndex == index,
                compact: compact,
                onTap: () => onSelected(index),
              ),
            ),
            if (index < items.length - 1) SizedBox(width: compact ? 4 : 7),
          ],
        ],
      ),
    );
  }
}

class _ArcadeDockButton extends StatefulWidget {
  const _ArcadeDockButton({
    super.key,
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final GameDockItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_ArcadeDockButton> createState() => _ArcadeDockButtonState();
}

class _ArcadeDockButtonState extends State<_ArcadeDockButton> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || hovered;
    final color = widget.item.color;
    final deep = Color.lerp(color, GameColors.ink, .30)!;
    final top = Color.lerp(color, Colors.white, active ? .28 : .38)!;
    final scale = widget.selected ? 1.04 : 1.0;
    final lift = widget.selected ? -ArcadeRebuildMetrics.dockSelectedLift : 0.0;
    final iconSize = widget.compact
        ? ArcadeRebuildMetrics.dockIconSize - 11
        : ArcadeRebuildMetrics.dockIconSize + (widget.selected ? 3 : 0);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) => setState(() => pressed = false),
        onTap: () {
          GameAudioHooks.emit(GameAudioCue.menu);
          widget.onTap();
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: pressed ? .98 : scale,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 150),
              offset: Offset(0, pressed ? .04 : lift / 90),
              child: SizedBox(
                height: ArcadeRebuildMetrics.dockButtonHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 3,
                      right: 3,
                      bottom: 0,
                      height: ArcadeRebuildMetrics.dockButtonHeight - 5,
                      child: ClipPath(
                        clipper: const ArcadePieceClipper(skew: 12),
                        child: ColoredBox(color: deep.withValues(alpha: .72)),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: ArcadeRebuildMetrics.dockShadowOffset,
                      child: PhysicalShape(
                        clipper: const ArcadePieceClipper(skew: 12),
                        color: color,
                        elevation: active ? 12 : 8,
                        shadowColor: deep.withValues(alpha: .55),
                        child: ClipPath(
                          clipper: const ArcadePieceClipper(skew: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [top, color, deep],
                                stops: const [0, .56, 1],
                              ),
                              border: Border.all(
                                color: widget.selected
                                    ? Colors.white
                                    : Color.lerp(color, GameColors.ink, .35)!,
                                width: ArcadeRebuildMetrics.dockBorderWidth,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 13,
                                  right: 13,
                                  top: 6,
                                  child: Container(
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .50,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        GameRadii.pill,
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.selected)
                                  Positioned(
                                    left: 8,
                                    top: 8,
                                    child: Container(
                                      key: ValueKey(
                                        'dock_${widget.item.label.toLowerCase()}_selected',
                                      ),
                                      width: 21,
                                      height: 21,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: color,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                if (widget.item.hasNew)
                                  Positioned(
                                    right: 9,
                                    top: 8,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: color,
                                          width: 3,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: widget.compact ? 33 : 46,
                                          height: widget.compact ? 30 : 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: active ? .95 : .88,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: deep.withValues(
                                                alpha: .32,
                                              ),
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: deep.withValues(
                                                  alpha: .28,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            widget.item.icon,
                                            size: iconSize,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          widget.item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: widget.compact ? 10 : 15,
                                            letterSpacing: .15,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x88000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}

class RyomiStageArea extends StatelessWidget {
  const RyomiStageArea({
    super.key,
    this.compact = false,
    this.showLabel = true,
  });

  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(GameRadii.large),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCDEFF2), Color(0xFFE6D9FF), Color(0xFFFFEDE4)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StudioPainter()),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: compact ? .88 : .94,
              widthFactor: compact ? .82 : .72,
              child: const _RyomiOfficialPose(
                key: ValueKey('ryomi_stage_area_art'),
              ),
            ),
          ),
          if (showLabel)
            const Positioned(left: 16, top: 14, child: _OnAirBadge()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameRadii.large),
                border: Border.all(color: const Color(0xAA5ED6D4)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RyomiOfficialPose extends StatelessWidget {
  const _RyomiOfficialPose({super.key});

  @override
  Widget build(BuildContext context) => Image.asset(
    GameAssets.ryomiStage01,
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    filterQuality: FilterQuality.high,
    isAntiAlias: true,
    gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  );
}

class _OnAirBadge extends StatelessWidget {
  const _OnAirBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          GameColors.coral.withValues(alpha: .3),
          GameColors.rose.withValues(alpha: .14),
        ],
      ),
      borderRadius: BorderRadius.circular(GameRadii.pill),
      border: Border.all(color: GameColors.coral),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: GameColors.coral),
        SizedBox(width: 6),
        Text(
          'NO AR',
          style: TextStyle(
            color: GameColors.cream,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

class _StudioPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final city = Paint()..color = const Color(0x225ED6D4);
    for (var x = 0.0; x < size.width; x += 34) {
      final height = (40 + ((x ~/ 34) % 5) * 18).toDouble();
      canvas.drawRect(Rect.fromLTWH(x, size.height - height, 24, height), city);
    }
    final grid = Paint()
      ..color = const Color(0x1F62D7DA)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    final wave = Paint()
      ..color = const Color(0xCCFFB85C)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final middle = size.height * .57;
    for (var x = 8.0; x < size.width; x += 12) {
      final height = 8 + ((x ~/ 12) % 7) * 6;
      canvas.drawLine(
        Offset(x, middle - height),
        Offset(x, middle + height),
        wave,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GameActionButton extends StatefulWidget {
  const GameActionButton({
    super.key,
    required this.label,
    required this.detail,
    required this.icon,
    required this.onPressed,
    required this.accent,
    this.secondaryAccent,
    this.badge,
    this.enabled = true,
    this.glow = false,
  });

  final String label;
  final String detail;
  final IconData icon;
  final VoidCallback onPressed;
  final Color accent;
  final Color? secondaryAccent;
  final String? badge;
  final bool enabled;
  final bool glow;

  @override
  State<GameActionButton> createState() => _GameActionButtonState();
}

class _GameActionButtonState extends State<GameActionButton> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final motionOff = MediaQuery.disableAnimationsOf(context);
    final active = widget.enabled && (hovered || widget.glow);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: Radius.circular(widget.badge == null ? 10 : 22),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(18),
    );
    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: InkWell(
        borderRadius: radius,
        onHover: widget.enabled
            ? (value) => setState(() => hovered = value)
            : null,
        onHighlightChanged: widget.enabled
            ? (value) => setState(() => pressed = value)
            : null,
        onTap: widget.enabled
            ? () {
                GameAudioHooks.emit(GameAudioCue.click);
                widget.onPressed();
              }
            : null,
        child: AnimatedContainer(
          duration: motionOff
              ? Duration.zero
              : const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accent.withValues(alpha: active ? .95 : .76),
                      (widget.secondaryAccent ?? widget.accent).withValues(
                        alpha: active ? .78 : .55,
                      ),
                      Color.lerp(widget.accent, Colors.white, .62)!,
                    ],
                  )
                : null,
            color: widget.enabled
                ? null
                : GameColors.roseBeige.withValues(alpha: .78),
            borderRadius: radius,
            border: Border.all(
              color: widget.enabled
                  ? widget.accent.withValues(alpha: active ? 1 : .65)
                  : GameColors.locked.withValues(alpha: .35),
              width: active ? 2 : 1.4,
            ),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: widget.accent.withValues(alpha: .28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              else
                const BoxShadow(
                  color: GameColors.brownShadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .38),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.enabled
                          ? GameColors.cream
                          : GameColors.locked,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.enabled
                                ? GameColors.cream
                                : GameColors.locked,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: .35,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GameColors.cream,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.badge != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: BorderRadius.circular(GameRadii.pill),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CharacterActionSpec {
  const CharacterActionSpec({
    required this.id,
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.badge,
    this.enabled = true,
    this.locked = false,
    this.lockReason,
    this.cooldownRemaining,
    this.cooldownTotal,
  });

  final String id;
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? badge;
  final bool enabled;
  final bool locked;
  final String? lockReason;
  final Duration? cooldownRemaining;
  final Duration? cooldownTotal;

  bool get coolingDown =>
      cooldownRemaining != null && cooldownRemaining! > Duration.zero;

  bool get available => enabled && !locked && !coolingDown;
}

class CharacterActionBar extends StatelessWidget {
  const CharacterActionBar({
    super.key,
    required this.actions,
    this.forceGrid = false,
  });

  final List<CharacterActionSpec> actions;
  final bool forceGrid;

  @override
  Widget build(BuildContext context) {
    assert(actions.length == 4, 'CharacterActionBar expects four actions.');
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = !forceGrid && constraints.maxWidth >= 820;
        final buttonHeight = horizontal ? 78.0 : 76.0;
        final gap = horizontal ? 14.0 : 12.0;
        final content = horizontal
            ? Row(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0) SizedBox(width: gap),
                    Expanded(
                      child: _CharacterActionTile(
                        spec: actions[index],
                        height: buttonHeight,
                      ),
                    ),
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CharacterActionTile(
                          spec: actions[0],
                          height: buttonHeight,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _CharacterActionTile(
                          spec: actions[1],
                          height: buttonHeight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(
                        child: _CharacterActionTile(
                          spec: actions[2],
                          height: buttonHeight,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _CharacterActionTile(
                          spec: actions[3],
                          height: buttonHeight,
                        ),
                      ),
                    ],
                  ),
                ],
              );
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: horizontal ? 1120 : 720),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: .84),
                    GameColors.blush.withValues(alpha: .76),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: GameColors.brownShadow,
                    blurRadius: 20,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(horizontal ? 14 : 12),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CharacterInteractionPanel extends StatelessWidget {
  const CharacterInteractionPanel({super.key, required this.actions});

  final List<CharacterActionSpec> actions;

  @override
  Widget build(BuildContext context) => CharacterActionBar(actions: actions);
}

class CharacterInteractionGrid extends StatelessWidget {
  const CharacterInteractionGrid({super.key, required this.actions});

  final List<CharacterActionSpec> actions;

  @override
  Widget build(BuildContext context) =>
      CharacterActionBar(actions: actions, forceGrid: true);
}

class ArcadeCharacterInteractionGrid extends StatelessWidget {
  const ArcadeCharacterInteractionGrid({super.key, required this.actions});

  final List<CharacterActionSpec> actions;

  @override
  Widget build(BuildContext context) {
    assert(actions.length == 4, 'Arcade grid expects four actions.');
    const gap = 8.0;
    return Column(
      key: const ValueKey('arcade_action_grid'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _ArcadeActionPiece(spec: actions[0])),
            const SizedBox(width: gap),
            Expanded(child: _ArcadeActionPiece(spec: actions[1])),
          ],
        ),
        const SizedBox(height: gap),
        Row(
          children: [
            Expanded(child: _ArcadeActionPiece(spec: actions[2])),
            const SizedBox(width: gap),
            Expanded(child: _ArcadeActionPiece(spec: actions[3])),
          ],
        ),
      ],
    );
  }
}

class _ArcadeActionPiece extends StatefulWidget {
  const _ArcadeActionPiece({required this.spec});

  final CharacterActionSpec spec;

  @override
  State<_ArcadeActionPiece> createState() => _ArcadeActionPieceState();
}

class _ArcadeActionPieceState extends State<_ArcadeActionPiece> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final available = spec.available;
    final locked = spec.locked;
    final cooling = spec.coolingDown;
    final color = locked
        ? Color.lerp(spec.color, GameColors.locked, .22)!
        : spec.color;
    final deep = Color.lerp(color, GameColors.ink, .32)!;
    final active = hovered && !locked;
    final progress = _cooldownFactor(spec);
    return SizedBox(
      key: ValueKey('action_${spec.id}'),
      height: ArcadeRebuildMetrics.actionButtonHeight,
      child: Semantics(
        button: true,
        enabled: available,
        label: spec.label,
        child: GestureDetector(
          onTapDown: available ? (_) => setState(() => pressed = true) : null,
          onTapCancel: available ? () => setState(() => pressed = false) : null,
          onTapUp: available ? (_) => setState(() => pressed = false) : null,
          onTap: available
              ? () {
                  GameAudioHooks.emit(GameAudioCue.click);
                  spec.onPressed();
                }
              : null,
          child: MouseRegion(
            onEnter: locked ? null : (_) => setState(() => hovered = true),
            onExit: locked ? null : (_) => setState(() => hovered = false),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: pressed ? .98 : (active ? 1.025 : 1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 3,
                    right: 3,
                    bottom: 0,
                    height: ArcadeRebuildMetrics.actionButtonHeight - 6,
                    child: ClipPath(
                      clipper: const ArcadePieceClipper(skew: 9),
                      child: ColoredBox(color: deep.withValues(alpha: .74)),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: ArcadeRebuildMetrics.actionShadowOffset,
                    child: PhysicalShape(
                      clipper: const ArcadePieceClipper(skew: 9),
                      color: color,
                      elevation: active ? 12 : 8,
                      shadowColor: deep.withValues(alpha: .55),
                      child: ClipPath(
                        clipper: const ArcadePieceClipper(skew: 9),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.lerp(color, Colors.white, .34)!,
                                color,
                                deep,
                              ],
                            ),
                            border: Border.all(
                              color: locked
                                  ? deep.withValues(alpha: .70)
                                  : Colors.white.withValues(alpha: .92),
                              width: ArcadeRebuildMetrics.actionBorderWidth,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 12,
                                right: 12,
                                top: 7,
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .48),
                                    borderRadius: BorderRadius.circular(
                                      GameRadii.pill,
                                    ),
                                  ),
                                ),
                              ),
                              if (cooling && progress != null)
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      key: ValueKey(
                                        'action_${spec.id}_cooldown',
                                      ),
                                      width: 52,
                                      height: 52,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 6,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: .30),
                                            color: Colors.white,
                                          ),
                                          Text(
                                            '${spec.cooldownRemaining!.inSeconds.ceil()}s',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  9,
                                  12,
                                  10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: .92,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: deep.withValues(alpha: .26),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: deep.withValues(alpha: .24),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        locked ? Icons.lock_rounded : spec.icon,
                                        color: color,
                                        size:
                                            ArcadeRebuildMetrics.actionIconSize,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              spec.label.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.visible,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: .05,
                                                shadows: [
                                                  Shadow(
                                                    color: Color(0x99000000),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _detailText(spec),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: .92,
                                                ),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (spec.badge != null && !cooling)
                                Positioned(
                                  right: 7,
                                  top: 7,
                                  child: Container(
                                    key: ValueKey('action_${spec.id}_badge'),
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        GameRadii.pill,
                                      ),
                                      border: Border.all(
                                        color: deep.withValues(alpha: .42),
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      spec.badge!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _cooldownFactor(CharacterActionSpec spec) {
    if (!spec.coolingDown || spec.cooldownTotal == null) return null;
    final total = spec.cooldownTotal!.inMilliseconds;
    if (total <= 0) return null;
    return (spec.cooldownRemaining!.inMilliseconds / total).clamp(0.0, 1.0);
  }

  String _detailText(CharacterActionSpec spec) {
    if (spec.locked) return spec.lockReason ?? 'Bloqueado';
    if (spec.coolingDown) {
      return '${spec.cooldownRemaining!.inSeconds.ceil()}s restantes';
    }
    return spec.detail;
  }
}

class CharacterDialoguePanel extends StatelessWidget {
  const CharacterDialoguePanel({
    super.key,
    required this.name,
    required this.text,
    required this.theme,
    this.minimized = false,
    this.onToggleMinimized,
  });

  final String name;
  final String text;
  final CharacterVisualTheme theme;
  final bool minimized;
  final VoidCallback? onToggleMinimized;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GameColors.paper.withValues(alpha: .94),
          GameColors.blush.withValues(alpha: .98),
          Color.lerp(
            theme.speechBorder,
            Colors.white,
            .78,
          )!.withValues(alpha: .74),
        ],
      ),
      borderRadius: radius,
      border: Border.all(
        color: theme.speechBorder.withValues(alpha: .70),
        width: 1.8,
      ),
      boxShadow: [
        BoxShadow(
          color: GameColors.brownShadow,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: theme.speechBorder.withValues(alpha: .12),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ],
    );
    if (minimized) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          key: const ValueKey('character_dialogue_restore'),
          borderRadius: radius,
          onTap: onToggleMinimized,
          child: DecoratedBox(
            key: const ValueKey('character_dialogue_panel'),
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    color: theme.speechBorder,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mostrar diálogo',
                    style: TextStyle(
                      color: theme.speechBorder,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      key: const ValueKey('character_dialogue_panel'),
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 13, 13, 16),
        child: Column(
          key: const ValueKey('character_dialogue_panel_content'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      color: theme.speechBorder,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('character_dialogue_minimize'),
                  tooltip: 'Ocultar diálogo',
                  onPressed: onToggleMinimized,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.speechBorder,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: Text(
                text,
                key: ValueKey(text),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GameColors.ink,
                  fontSize: 15.5,
                  height: 1.32,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArcadeDialoguePanel extends StatelessWidget {
  const ArcadeDialoguePanel({
    super.key,
    required this.name,
    required this.text,
    required this.theme,
    this.minimized = false,
    this.onToggleMinimized,
  });

  final String name;
  final String text;
  final CharacterVisualTheme theme;
  final bool minimized;
  final VoidCallback? onToggleMinimized;

  @override
  Widget build(BuildContext context) {
    final accent = theme.speechBorder;
    final deep = Color.lerp(accent, GameColors.ink, .30)!;
    if (minimized) {
      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          key: const ValueKey('character_dialogue_restore'),
          onTap: onToggleMinimized,
          child: PhysicalShape(
            clipper: const ArcadePieceClipper(skew: 8),
            color: accent,
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 20, 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Mostrar diálogo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      key: const ValueKey('character_dialogue_panel'),
      width: double.infinity,
      height: ArcadeRebuildMetrics.dialogueMinHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            right: 4,
            bottom: 0,
            height: ArcadeRebuildMetrics.dialogueMinHeight - 8,
            child: ClipPath(
              clipper: const ArcadePanelClipper(),
              child: ColoredBox(color: deep.withValues(alpha: .55)),
            ),
          ),
          Positioned.fill(
            bottom: 8,
            child: PhysicalShape(
              clipper: const ArcadePanelClipper(),
              color: GameColors.paper,
              elevation: 10,
              shadowColor: deep.withValues(alpha: .55),
              child: ClipPath(
                clipper: const ArcadePanelClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    color: GameColors.paper,
                    border: Border.all(
                      color: deep,
                      width: ArcadeRebuildMetrics.dialogueBorderWidth,
                    ),
                  ),
                  child: Column(
                    key: const ValueKey('character_dialogue_panel_content'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 42,
                        padding: const EdgeInsets.fromLTRB(18, 7, 8, 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(accent, Colors.white, .25)!,
                              accent,
                              deep,
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(color: deep, width: 3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 27,
                              height: 27,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: deep, width: 2),
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: accent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .8,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x77000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey(
                                'character_dialogue_minimize',
                              ),
                              tooltip: 'Ocultar diálogo',
                              onPressed: onToggleMinimized,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                GameColors.blush.withValues(alpha: .92),
                                Color.lerp(accent, Colors.white, .78)!,
                              ],
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            child: Text(
                              text,
                              key: ValueKey(text),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GameColors.ink,
                                fontSize: 15.5,
                                height: 1.32,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RelationshipCheckpointBar extends StatelessWidget {
  const RelationshipCheckpointBar({
    super.key,
    required this.currentStage,
    required this.totalStages,
    required this.stageProgress,
    required this.stageNames,
    this.accent = GameColors.relation,
  });

  final int currentStage;
  final int totalStages;
  final double stageProgress;
  final List<String> stageNames;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final activeStage = currentStage.clamp(0, totalStages - 1);
    final progress = stageProgress.clamp(0.0, 1.0);
    return Column(
      key: const ValueKey('relationship_checkpoint_bar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: Row(
            children: [
              for (var index = 0; index < totalStages; index++) ...[
                _RelationshipCheckpoint(
                  index: index,
                  selected: index == activeStage,
                  complete:
                      index < activeStage ||
                      (index == activeStage && progress >= 1),
                  accent: accent,
                ),
                if (index < totalStages - 1)
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: index < activeStage
                            ? accent
                            : GameColors.outlineSoft.withValues(alpha: .32),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stageNames[activeStage].toUpperCase(),
          key: const ValueKey('relationship_current_stage_name'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: .5,
          ),
        ),
      ],
    );
  }
}

class _RelationshipCheckpoint extends StatelessWidget {
  const _RelationshipCheckpoint({
    required this.index,
    required this.selected,
    required this.complete,
    required this.accent,
  });

  final int index;
  final bool selected;
  final bool complete;
  final Color accent;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: ValueKey('relationship_checkpoint_$index'),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    width: selected ? 24 : 18,
    height: selected ? 24 : 18,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: complete || selected
          ? accent
          : Colors.white.withValues(alpha: .76),
      border: Border.all(
        color: selected
            ? Color.lerp(accent, Colors.white, .18)!
            : accent.withValues(alpha: complete ? .7 : .28),
        width: selected ? 2.4 : 1.4,
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: accent.withValues(alpha: .36),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ]
          : null,
    ),
    child: complete
        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
        : selected
        ? const Icon(Icons.favorite_rounded, size: 11, color: Colors.white)
        : Text(
            '${index + 1}',
            style: TextStyle(
              color: accent.withValues(alpha: .72),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
  );
}

class _CharacterActionTile extends StatefulWidget {
  const _CharacterActionTile({required this.spec, required this.height});

  final CharacterActionSpec spec;
  final double height;

  @override
  State<_CharacterActionTile> createState() => _CharacterActionTileState();
}

class _CharacterActionTileState extends State<_CharacterActionTile> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final motionOff = MediaQuery.disableAnimationsOf(context);
    final available = widget.spec.available;
    final cooling = widget.spec.coolingDown;
    final locked = widget.spec.locked;
    final active = hovered && !locked;
    final color = locked
        ? Color.lerp(widget.spec.color, GameColors.locked, .56)!
        : widget.spec.color;
    final light = Color.lerp(color, Colors.white, active ? .22 : .30)!;
    final deep = Color.lerp(color, GameColors.ink, .18)!;
    final radius = BorderRadius.circular(22);
    final cooldownFactor = _cooldownFactor(widget.spec);
    return SizedBox(
      key: ValueKey('action_${widget.spec.id}'),
      height: widget.height,
      child: Semantics(
        button: true,
        enabled: available,
        label: widget.spec.label,
        child: InkWell(
          borderRadius: radius,
          onHover: locked ? null : (value) => setState(() => hovered = value),
          onHighlightChanged: available
              ? (value) => setState(() => pressed = value)
              : null,
          onTap: available
              ? () {
                  GameAudioHooks.emit(GameAudioCue.click);
                  widget.spec.onPressed();
                }
              : null,
          child: AnimatedContainer(
            duration: motionOff
                ? Duration.zero
                : const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(
              0,
              pressed
                  ? 2
                  : active
                  ? -2
                  : 0,
              0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  light.withValues(alpha: active ? 1 : .96),
                  color.withValues(alpha: active ? 1 : .94),
                  deep.withValues(alpha: active ? .98 : .90),
                ],
                stops: const [0, .55, 1],
              ),
              borderRadius: radius,
              border: Border.all(
                color: locked
                    ? GameColors.locked.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: active ? .98 : .84),
                width: active ? 2.4 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: deep.withValues(alpha: active ? .48 : .36),
                  blurRadius: active ? 18 : 12,
                  offset: Offset(0, active ? 8 : 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: active ? .72 : .42),
                  blurRadius: 0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  top: 8,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(GameRadii.pill),
                    ),
                  ),
                ),
                if (cooling && cooldownFactor != null)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        key: ValueKey('action_${widget.spec.id}_cooldown'),
                        heightFactor: cooldownFactor,
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .23),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .70),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          locked ? Icons.lock_rounded : widget.spec.icon,
                          color: GameColors.cream,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.spec.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GameColors.cream,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _detailText(widget.spec),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GameColors.cream,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.spec.badge != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      key: ValueKey('action_${widget.spec.id}_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(GameRadii.pill),
                        border: Border.all(color: color.withValues(alpha: .42)),
                      ),
                      child: Text(
                        widget.spec.badge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double? _cooldownFactor(CharacterActionSpec spec) {
    if (!spec.coolingDown || spec.cooldownTotal == null) return null;
    final total = spec.cooldownTotal!.inMilliseconds;
    if (total <= 0) return null;
    return (spec.cooldownRemaining!.inMilliseconds / total).clamp(0.0, 1.0);
  }

  String _detailText(CharacterActionSpec spec) {
    if (spec.locked) return spec.lockReason ?? 'Bloqueado';
    if (spec.coolingDown) {
      return '${spec.cooldownRemaining!.inSeconds.ceil()}s restantes';
    }
    return spec.detail;
  }
}

class FloatingRewardText extends StatefulWidget {
  const FloatingRewardText({
    super.key,
    required this.text,
    required this.color,
    this.onFinished,
  });

  final String text;
  final Color color;
  final VoidCallback? onFinished;

  @override
  State<FloatingRewardText> createState() => _FloatingRewardTextState();
}

class _FloatingRewardTextState extends State<FloatingRewardText>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<Offset> slide;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 35),
    ]).animate(controller);
    slide = Tween(
      begin: const Offset(0, .3),
      end: const Offset(0, -.45),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    controller.forward().whenComplete(() => widget.onFinished?.call());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      );
    }
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Text(
          widget.text,
          style: TextStyle(
            color: widget.color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            shadows: [
              Shadow(color: widget.color.withValues(alpha: .8), blurRadius: 12),
              const Shadow(color: Colors.black, blurRadius: 5),
            ],
          ),
        ),
      ),
    );
  }
}

void showGameResult(BuildContext context, ActionResult result) {
  debugPrint('Game result: ${result.message}');
  final episode = NarrativeCatalog.byId(result.storyEpisodeId);
  if (episode == null) return;
  Future<void>.delayed(const Duration(milliseconds: 250), () {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(GameSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  color: GameColors.amber,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'Episódio desbloqueado',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${episode.title}\n\n${episode.placeholder}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}
