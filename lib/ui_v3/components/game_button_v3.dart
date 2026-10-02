import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_motion_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';

class GameButtonV3 extends StatefulWidget {
  const GameButtonV3({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = ConnectionsColorsV3.relationship,
    this.compact = false,
    this.selected = false,
    this.locked = false,
    this.cooldown = false,
    this.tooltip,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final bool compact;
  final bool selected;
  final bool locked;
  final bool cooldown;
  final String? tooltip;
  final String? semanticLabel;

  @override
  State<GameButtonV3> createState() => _GameButtonV3State();
}

class _GameButtonV3State extends State<GameButtonV3> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.locked;
  Color get _baseColor {
    if (!_enabled) return ConnectionsColorsV3.disabledSurface;
    if (widget.cooldown) return Color.lerp(widget.color, Colors.white, .18)!;
    if (widget.selected) return widget.color;
    return Color.lerp(widget.color, Colors.white, .08)!;
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor;
    final dark = ConnectionsColorsV3.darkFor(color);
    final lift = !_enabled
        ? 0.0
        : _pressed
        ? 3.0
        : _hovered
        ? -2.0
        : 0.0;
    final bottomShadow = !_enabled
        ? 2.0
        : _pressed
        ? 1.0
        : 5.0;
    final textColor = _enabled
        ? ConnectionsColorsV3.onColor
        : ConnectionsColorsV3.inkSoft;

    Widget button = FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedSlide(
          duration: ConnectionsMotionV3.fast,
          curve: ConnectionsMotionV3.press,
          offset: Offset(0, lift / 40),
          child: AnimatedContainer(
            duration: ConnectionsMotionV3.fast,
            curve: ConnectionsMotionV3.press,
            decoration: BoxDecoration(
              color: dark,
              borderRadius: BorderRadius.circular(ConnectionsRadiusV3.button),
            ),
            padding: EdgeInsets.only(bottom: bottomShadow),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(color, Colors.white, _hovered ? .24 : .14)!,
                    color,
                  ],
                ),
                border: Border.all(
                  color: _focused
                      ? ConnectionsColorsV3.info
                      : ConnectionsColorsV3.outline,
                  width: _focused
                      ? ConnectionsShadowsV3.outlineStrong
                      : ConnectionsShadowsV3.outlineThin,
                ),
                borderRadius: BorderRadius.circular(ConnectionsRadiusV3.button),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 4,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Center(
                    child: DefaultTextStyle.merge(
                      style: ConnectionsTypographyV3.button(
                        size: widget.compact ? 12.5 : 14,
                      ).copyWith(color: textColor),
                      child: IconTheme.merge(
                        data: IconThemeData(color: textColor),
                        child: widget.child,
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

    if (widget.semanticLabel != null) {
      button = Semantics(
        button: true,
        enabled: _enabled,
        label: widget.semanticLabel,
        child: button,
      );
    }
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
