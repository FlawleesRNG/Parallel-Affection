import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/character_catalog.dart';
import '../../core/idle_rules.dart';
import '../../data/character_unlocks.dart';
import '../../models/idle_models.dart';
import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';
import 'debug_region_label_v3.dart';

class CharacterSelectorV3 extends StatelessWidget {
  const CharacterSelectorV3({
    super.key,
    required this.characters,
    required this.selectedCharacterId,
    this.compact = false,
    this.desktopCompact = false,
    this.wideDesktop = false,
    this.onSelected,
  });

  final Map<String, CharacterProgress> characters;
  final String selectedCharacterId;
  final bool compact;
  final bool desktopCompact;
  final bool wideDesktop;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) => compact
      ? _CompactCharacterSelectorV3(
          characters: characters,
          selectedCharacterId: selectedCharacterId,
          onSelected: onSelected,
        )
      : SizedBox.expand(
          key: const ValueKey('character_selector_v3'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ConnectionsColorsV3.backgroundSecondary,
              border: Border(
                right: BorderSide(
                  color: ConnectionsColorsV3.outline.withValues(alpha: .32),
                  width: ConnectionsShadowsV3.outlineThin,
                ),
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _SelectorColumnDecorationV3()),
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    key: const ValueKey('character_selector_scroll_v3'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _characterCards(
                        height: desktopCompact
                            ? 92
                            : wideDesktop
                            ? 106
                            : 98,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 8,
                  bottom: 8,
                  child: DebugRegionLabelV3('Seletor V3'),
                ),
              ],
            ),
          ),
        );

  List<Widget> _characterCards({required double height}) {
    final cards = <Widget>[];
    for (final character in PlayableCharacterCatalog.all) {
      final progress =
          characters[character.id] ?? const CharacterProgress(unlocked: true);
      final selected =
          PlayableCharacterCatalog.canonicalId(selectedCharacterId) ==
          character.id;
      cards.add(
        CharacterSelectorCardV3(
          key: ValueKey('character_selector_${character.id}_v3'),
          characterId: character.id,
          name: character.visibleName,
          stageLabel: character.routeReady
              ? IdleRules.stageName(progress.stage)
              : 'Rota em preparação',
          routePercent: character.routeReady
              ? IdleRules.routeProgressPercent(
                  progress,
                  characterId: character.id,
                )
              : 0,
          selected: selected,
          locked: !progress.unlocked,
          assetPath: character.effectiveSelectorAsset,
          assetKey: ValueKey('character_selector_${character.id}_asset_v3'),
          height: height,
          accent: character.accent,
          onTap: progress.unlocked
              ? () => onSelected?.call(character.id)
              : null,
        ),
      );
      if (character != PlayableCharacterCatalog.all.last) {
        cards.add(const SizedBox(height: 8));
      }
    }
    return cards;
  }
}

class _CompactCharacterSelectorV3 extends StatelessWidget {
  const _CompactCharacterSelectorV3({
    required this.characters,
    required this.selectedCharacterId,
    this.onSelected,
  });

  final Map<String, CharacterProgress> characters;
  final String selectedCharacterId;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: const ValueKey('character_selector_v3'),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ConnectionsColorsV3.backgroundSecondary,
        border: Border.all(
          color: ConnectionsColorsV3.outline.withValues(alpha: .26),
          width: ConnectionsShadowsV3.outlineThin,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _SelectorColumnDecorationV3()),
          Padding(
            padding: const EdgeInsets.all(6),
            child: ListView.separated(
              key: const ValueKey('character_selector_compact_scroll_v3'),
              scrollDirection: Axis.horizontal,
              itemCount: PlayableCharacterCatalog.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final character = PlayableCharacterCatalog.all[index];
                final progress =
                    characters[character.id] ??
                    const CharacterProgress(unlocked: true);
                return SizedBox(
                  width: 158,
                  child: CharacterSelectorCardV3(
                    key: ValueKey('character_selector_${character.id}_v3'),
                    characterId: character.id,
                    name: character.visibleName,
                    stageLabel: character.routeReady
                        ? IdleRules.stageName(progress.stage)
                        : 'Rota em preparação',
                    routePercent: character.routeReady
                        ? IdleRules.routeProgressPercent(
                            progress,
                            characterId: character.id,
                          )
                        : 0,
                    selected:
                        PlayableCharacterCatalog.canonicalId(
                          selectedCharacterId,
                        ) ==
                        character.id,
                    locked: !progress.unlocked,
                    assetPath: character.effectiveSelectorAsset,
                    assetKey: ValueKey(
                      'character_selector_${character.id}_asset_v3',
                    ),
                    compact: true,
                    height: 68,
                    accent: character.accent,
                    onTap: progress.unlocked
                        ? () => onSelected?.call(character.id)
                        : null,
                  ),
                );
              },
            ),
          ),
          const Positioned(
            left: 8,
            bottom: 4,
            child: DebugRegionLabelV3('Seletor V3'),
          ),
        ],
      ),
    ),
  );
}

class CharacterSelectorCardV3 extends StatefulWidget {
  const CharacterSelectorCardV3({
    super.key,
    required this.characterId,
    required this.name,
    required this.stageLabel,
    required this.routePercent,
    required this.assetPath,
    this.assetKey = const ValueKey('character_selector_asset_v3'),
    this.selected = false,
    this.locked = false,
    this.compact = false,
    this.height = 96,
    this.notificationCount = 0,
    this.accent = ConnectionsColorsV3.relationship,
    this.onTap,
  });

  final String name;
  final String characterId;
  final String stageLabel;
  final int routePercent;
  final String assetPath;
  final Key assetKey;
  final bool selected;
  final bool locked;
  final bool compact;
  final double height;
  final int notificationCount;
  final Color accent;
  final VoidCallback? onTap;

  @override
  State<CharacterSelectorCardV3> createState() =>
      _CharacterSelectorCardV3State();
}

class _CharacterSelectorCardV3State extends State<CharacterSelectorCardV3> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'character_selector_card_v3',
  );
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePercent = widget.routePercent.clamp(0, 100);
    final compact = widget.compact;
    final focusColor = ConnectionsColorsV3.info.withValues(alpha: .8);
    final selectedColor = widget.accent;
    final outlineColor = _focused
        ? focusColor
        : widget.selected
        ? selectedColor
        : ConnectionsColorsV3.outlineSoft.withValues(alpha: .44);
    final dx = _hovered ? 1.0 : 0.0;
    final dy = _pressed ? 1.0 : 0.0;
    final semanticLabel = widget.locked
        ? '${widget.name}, bloqueada. ${CharacterUnlockCatalog.requirementText(widget.characterId)}'
        : '${widget.name}, ${widget.stageLabel}, progresso $effectivePercent por cento';

    return Tooltip(
      message: widget.locked
          ? CharacterUnlockCatalog.requirementText(widget.characterId)
          : '${widget.name} • ${widget.stageLabel} • $effectivePercent%',
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: widget.selected,
        child: FocusableActionDetector(
          focusNode: _focusNode,
          mouseCursor: widget.locked
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onShowFocusHighlight: (focused) => setState(() => _focused = focused),
          onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _activate,
            onTapDown: (_) {
              _focusNode.requestFocus();
              setState(() => _pressed = true);
            },
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(dx, dy, 0),
              height: widget.height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ConnectionsRadiusV3.large),
                border: Border.all(
                  color: outlineColor,
                  width: widget.selected || _focused ? 3.4 : 1.1,
                ),
                boxShadow: widget.selected
                    ? [
                        ...ConnectionsShadowsV3.solid(widget.accent, y: 4),
                        BoxShadow(
                          color: widget.accent.withValues(alpha: .10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : ConnectionsShadowsV3.ambient(
                        opacity: _hovered ? .14 : .08,
                      ),
              ),
              child: Stack(
                key: const ValueKey('character_selector_full_bleed_stack_v3'),
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.assetPath,
                    key: widget.assetKey,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) =>
                        _SelectorAssetFallbackV3(
                          name: widget.name,
                          accent: widget.accent,
                        ),
                  ),
                  if (!widget.selected)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .06),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      key: const ValueKey('character_selector_info_area_v3'),
                      widthFactor: compact ? .48 : .45,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: .02),
                              Colors.black.withValues(alpha: .56),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 7 : 9,
                            compact ? 6 : 8,
                            compact ? 8 : 10,
                            compact ? 6 : 8,
                          ),
                          child: _SelectorInfoV3(
                            name: widget.name,
                            stageLabel: widget.stageLabel,
                            routePercent: effectivePercent,
                            accent: widget.accent,
                            compact: compact,
                            overImage: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.locked)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .48),
                      ),
                    ),
                  if (widget.selected)
                    Positioned(
                      key: const ValueKey('character_selector_selected_tab_v3'),
                      left: 7,
                      top: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .22),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const SizedBox.square(
                          dimension: 22,
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  if (widget.locked)
                    const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  if (widget.selected || _focused)
                    Positioned.fill(
                      child: DecoratedBox(
                        key: const ValueKey(
                          'character_selector_selection_border_v3',
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            ConnectionsRadiusV3.large - 3,
                          ),
                          border: Border.all(
                            color: outlineColor,
                            width: widget.selected ? 3.0 : 2.0,
                          ),
                        ),
                      ),
                    ),
                  if (widget.notificationCount > 0)
                    Positioned(
                      key: const ValueKey('character_selector_badge_v3'),
                      right: 5,
                      top: 5,
                      child: _SelectorBadgeV3(
                        count: widget.notificationCount,
                        color: selectedColor,
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
}

class _SelectorAssetFallbackV3 extends StatelessWidget {
  const _SelectorAssetFallbackV3({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Color.lerp(ConnectionsColorsV3.paperElevated, accent, .18),
    ),
    child: Center(
      child: Text(
        (name.isEmpty ? '?' : name.characters.first).toUpperCase(),
        style: ConnectionsTypographyV3.windowTitle(
          size: 24,
        ).copyWith(color: ConnectionsColorsV3.darkFor(accent)),
      ),
    ),
  );
}

class _SelectorInfoV3 extends StatelessWidget {
  const _SelectorInfoV3({
    required this.name,
    required this.stageLabel,
    required this.routePercent,
    required this.accent,
    required this.compact,
    this.overImage = false,
  });

  final String name;
  final String stageLabel;
  final int routePercent;
  final Color accent;
  final bool compact;
  final bool overImage;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!compact) return content;

    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(width: constraints.maxWidth, child: content),
      ),
    );
  }

  Widget _buildContent(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Tooltip(
              message: name,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    ConnectionsTypographyV3.windowTitle(
                      size: compact ? 13 : 14.5,
                    ).copyWith(
                      color: overImage ? Colors.white : null,
                      shadows: overImage ? _textShadow : null,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$routePercent%',
            key: const ValueKey('character_selector_route_percent_v3'),
            maxLines: 1,
            style: ConnectionsTypographyV3.button(size: compact ? 11 : 13)
                .copyWith(
                  color: overImage
                      ? Colors.white
                      : ConnectionsColorsV3.relationshipDark,
                  shadows: overImage ? _textShadow : null,
                ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      Tooltip(
        message: stageLabel,
        child: Text(
          stageLabel,
          key: const ValueKey('character_selector_stage_v3'),
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: ConnectionsTypographyV3.secondary(size: compact ? 11 : 12)
              .copyWith(
                color: overImage ? Colors.white.withValues(alpha: .92) : null,
                shadows: overImage ? _textShadow : null,
              ),
        ),
      ),
      SizedBox(height: compact ? 4 : 5),
      _SelectorMiniProgressBarV3(
        percent: routePercent,
        color: overImage ? Colors.white : accent,
        overImage: overImage,
      ),
    ],
  );

  static const _textShadow = [
    Shadow(color: Color(0x99000000), offset: Offset(0, 1), blurRadius: 2),
  ];
}

class _SelectorMiniProgressBarV3 extends StatelessWidget {
  const _SelectorMiniProgressBarV3({
    required this.percent,
    required this.color,
    this.overImage = false,
  });

  final int percent;
  final Color color;
  final bool overImage;

  @override
  Widget build(BuildContext context) {
    final fill = percent.clamp(0, 100) / 100;
    return ClipRRect(
      key: const ValueKey('character_selector_route_bar_v3'),
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
      child: SizedBox(
        height: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: overImage
                ? Colors.white.withValues(alpha: .28)
                : ConnectionsColorsV3.paper.withValues(alpha: .72),
            border: Border.all(
              color: overImage
                  ? Colors.white.withValues(alpha: .38)
                  : ConnectionsColorsV3.outlineSoft.withValues(alpha: .44),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              key: const ValueKey('character_selector_route_bar_fill_v3'),
              widthFactor: fill,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorBadgeV3 extends StatelessWidget {
  const _SelectorBadgeV3({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: ConnectionsColorsV3.paperElevated, width: 2),
    ),
    child: SizedBox.square(
      dimension: 24,
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: ConnectionsTypographyV3.badge(size: 10),
        ),
      ),
    ),
  );
}

class _SelectorColumnDecorationV3 extends StatelessWidget {
  const _SelectorColumnDecorationV3();

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: const ValueKey('character_selector_empty_decoration_v3'),
    painter: _SelectorColumnPainterV3(),
  );
}

class _SelectorColumnPainterV3 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = ConnectionsColorsV3.relationship.withValues(alpha: .08);
    final shapePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = ConnectionsColorsV3.outline.withValues(alpha: .055);

    for (var i = 0; i < 4; i++) {
      final y = size.height * (.24 + i * .18);
      final path = Path()
        ..moveTo(size.width * .16, y)
        ..quadraticBezierTo(size.width * .46, y - 24, size.width * .84, y + 8);
      canvas.drawPath(path, linePaint);
    }

    for (var i = 0; i < 3; i++) {
      final center = Offset(
        size.width * (.28 + i * .22),
        size.height * (.55 + i * .1),
      );
      _drawHeart(canvas, center, 6 + i.toDouble(), shapePaint);
    }

    final cardWidth = math.min(size.width * .54, 92.0);
    for (var i = 0; i < 2; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .22 + i * 12,
          size.height - 128 + i * 24,
          cardWidth,
          42,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, shapePaint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * .65)
      ..cubicTo(
        center.dx - size * 1.4,
        center.dy - size * .2,
        center.dx - size * .72,
        center.dy - size * 1.1,
        center.dx,
        center.dy - size * .36,
      )
      ..cubicTo(
        center.dx + size * .72,
        center.dy - size * 1.1,
        center.dx + size * 1.4,
        center.dy - size * .2,
        center.dx,
        center.dy + size * .65,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
