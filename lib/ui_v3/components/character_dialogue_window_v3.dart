import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_radius_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';
import 'game_button_v3.dart';
import 'game_icon_medallion_v3.dart';

class CharacterDialogueWindowV3 extends StatefulWidget {
  const CharacterDialogueWindowV3({
    super.key,
    required this.speakerName,
    required this.text,
    required this.queuedCount,
    required this.minimized,
    required this.hasUnread,
    required this.onAdvance,
    required this.onCompleteText,
    required this.onMinimize,
    required this.onRestore,
    this.compact = false,
  });

  final String speakerName;
  final String text;
  final int queuedCount;
  final bool minimized;
  final bool hasUnread;
  final bool compact;
  final VoidCallback onAdvance;
  final VoidCallback onCompleteText;
  final VoidCallback onMinimize;
  final VoidCallback onRestore;

  @override
  State<CharacterDialogueWindowV3> createState() =>
      _CharacterDialogueWindowV3State();
}

class _CharacterDialogueWindowV3State extends State<CharacterDialogueWindowV3> {
  static const _fallbackLine =
      'Você apareceu de novo. Acho que podemos conversar um pouco.';

  Timer? _typeTimer;
  int _visibleCharacters = 0;

  String get _line {
    final value = widget.text.trim();
    return value.isEmpty ? _fallbackLine : value;
  }

  bool get _typing => _visibleCharacters < _line.length;

  @override
  void initState() {
    super.initState();
    _restartTyping();
  }

  @override
  void didUpdateWidget(covariant CharacterDialogueWindowV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _restartTyping();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.minimized) {
      return Tooltip(
        message: 'Abrir diálogo',
        child: Semantics(
          button: true,
          label: 'Abrir diálogo de ${widget.speakerName}',
          child: GameButtonV3(
            key: const ValueKey('dialogue_window_minimized_v3'),
            onPressed: widget.onRestore,
            color: ConnectionsColorsV3.relationship,
            compact: widget.compact,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '💬 ${widget.speakerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.hasUnread) ...[
                  const SizedBox(width: 6),
                  const _UnreadDotV3(key: ValueKey('dialogue_unread_badge_v3')),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleAdvanceIntent();
              return null;
            },
          ),
        },
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleAdvanceIntent,
            child: _DialogueFrameV3(
              compact: widget.compact,
              speakerName: widget.speakerName,
              queuedCount: widget.queuedCount,
              hasUnread: widget.hasUnread,
              typing: _typing,
              onMinimize: widget.onMinimize,
              onAdvance: _handleAdvanceIntent,
              child: _DialogueBodyV3(
                visibleText: _visibleText,
                compact: widget.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _visibleText {
    final end = math.min(_visibleCharacters, _line.length);
    return _line.substring(0, end);
  }

  void _restartTyping() {
    _typeTimer?.cancel();
    _visibleCharacters = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted) return;
      final next = math.min(_visibleCharacters + 2, _line.length);
      if (next == _visibleCharacters) {
        timer.cancel();
        widget.onCompleteText();
        return;
      }
      setState(() => _visibleCharacters = next);
      if (next >= _line.length) {
        timer.cancel();
        widget.onCompleteText();
      }
    });
  }

  void _completeText() {
    _typeTimer?.cancel();
    setState(() => _visibleCharacters = _line.length);
    widget.onCompleteText();
  }

  void _handleAdvanceIntent() {
    if (_typing) {
      _completeText();
      return;
    }
    widget.onAdvance();
  }
}

class _DialogueFrameV3 extends StatelessWidget {
  const _DialogueFrameV3({
    required this.compact,
    required this.speakerName,
    required this.queuedCount,
    required this.hasUnread,
    required this.typing,
    required this.onMinimize,
    required this.onAdvance,
    required this.child,
  });

  final bool compact;
  final String speakerName;
  final int queuedCount;
  final bool hasUnread;
  final bool typing;
  final VoidCallback onMinimize;
  final VoidCallback onAdvance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ConnectionsRadiusV3.window);
    return DecoratedBox(
      key: const ValueKey('dialogue_window_v3'),
      decoration: BoxDecoration(
        color: ConnectionsColorsV3.relationshipDark,
        borderRadius: radius,
        boxShadow: [
          ...ConnectionsShadowsV3.ambient(opacity: .14),
          const BoxShadow(
            color: ConnectionsColorsV3.relationshipDark,
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: compact ? 4 : 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ConnectionsColorsV3.paper,
            border: Border.all(
              color: ConnectionsColorsV3.outline,
              width: ConnectionsShadowsV3.outline,
            ),
            borderRadius: radius,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ConnectionsRadiusV3.window - ConnectionsShadowsV3.outline,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogueHeaderV3(
                  compact: compact,
                  speakerName: speakerName,
                  queuedCount: queuedCount,
                  hasUnread: hasUnread,
                  typing: typing,
                  onMinimize: onMinimize,
                  onAdvance: onAdvance,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogueHeaderV3 extends StatelessWidget {
  const _DialogueHeaderV3({
    required this.compact,
    required this.speakerName,
    required this.queuedCount,
    required this.hasUnread,
    required this.typing,
    required this.onMinimize,
    required this.onAdvance,
  });

  final bool compact;
  final String speakerName;
  final int queuedCount;
  final bool hasUnread;
  final bool typing;
  final VoidCallback onMinimize;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Color.lerp(
        ConnectionsColorsV3.paper,
        ConnectionsColorsV3.relationship,
        .18,
      ),
      border: const Border(
        bottom: BorderSide(
          color: ConnectionsColorsV3.outline,
          width: ConnectionsShadowsV3.outlineThin,
        ),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 4 : 6,
        compact ? 7 : 9,
        compact ? 4 : 6,
      ),
      child: Row(
        children: [
          GameIconMedallionV3(
            icon: Icons.favorite_rounded,
            color: ConnectionsColorsV3.relationship,
            size: compact ? 22 : 28,
          ),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    speakerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ConnectionsTypographyV3.windowTitle(
                      size: compact ? 14 : 18,
                    ).copyWith(color: ConnectionsColorsV3.ink),
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 7),
                  const _UnreadDotV3(),
                ],
              ],
            ),
          ),
          if (queuedCount > 0) ...[
            _QueuedIndicatorV3(count: queuedCount, compact: compact),
            const SizedBox(width: 4),
          ],
          IconButton(
            key: const ValueKey('dialogue_minimize_v3'),
            tooltip: 'Minimizar diálogo',
            onPressed: onMinimize,
            constraints: BoxConstraints.tightFor(
              width: compact ? 24 : 30,
              height: compact ? 24 : 30,
            ),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          IconButton(
            key: const ValueKey('dialogue_advance_v3'),
            tooltip: typing ? 'Completar fala' : 'Avançar fala',
            onPressed: onAdvance,
            constraints: BoxConstraints.tightFor(
              width: compact ? 24 : 30,
              height: compact ? 24 : 30,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              typing
                  ? Icons.keyboard_double_arrow_right_rounded
                  : Icons.chevron_right_rounded,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DialogueBodyV3 extends StatelessWidget {
  const _DialogueBodyV3({required this.visibleText, required this.compact});

  final String visibleText;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: ConnectionsColorsV3.paperElevated),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 14,
        compact ? 8 : 10,
        compact ? 10 : 14,
        compact ? 9 : 11,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(
            ConnectionsColorsV3.paper,
            ConnectionsColorsV3.warning,
            .08,
          ),
          borderRadius: BorderRadius.circular(ConnectionsRadiusV3.medium),
          border: Border.all(
            color: ConnectionsColorsV3.outlineSoft.withValues(alpha: .45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const ValueKey('dialogue_coral_detail_v3'),
              width: compact ? 4 : 5,
              decoration: const BoxDecoration(
                color: ConnectionsColorsV3.relationship,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 12,
                  vertical: compact ? 7 : 9,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    visibleText,
                    key: const ValueKey('dialogue_text_v3'),
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: ConnectionsTypographyV3.body(
                      size: compact ? 13 : 15,
                    ).copyWith(color: ConnectionsColorsV3.ink, height: 1.2),
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

class _QueuedIndicatorV3 extends StatelessWidget {
  const _QueuedIndicatorV3({required this.count, required this.compact});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('dialogue_continue_indicator_v3'),
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 6 : 8,
      vertical: compact ? 2 : 3,
    ),
    decoration: BoxDecoration(
      color: ConnectionsColorsV3.relationship,
      borderRadius: BorderRadius.circular(ConnectionsRadiusV3.circle),
      border: Border.all(
        color: ConnectionsColorsV3.outline,
        width: ConnectionsShadowsV3.outlineThin,
      ),
    ),
    child: Text(
      '+$count',
      maxLines: 1,
      style: ConnectionsTypographyV3.badge(
        size: compact ? 9 : 10,
      ).copyWith(color: ConnectionsColorsV3.onColor),
    ),
  );
}

class _UnreadDotV3 extends StatelessWidget {
  const _UnreadDotV3({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: ConnectionsColorsV3.warning,
      shape: BoxShape.circle,
    ),
  );
}
