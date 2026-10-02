import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';
import '../design/connections_shadows_v3.dart';
import '../design/connections_typography_v3.dart';

class ClickableCharacterSceneV3 extends StatefulWidget {
  const ClickableCharacterSceneV3({
    super.key,
    required this.asset,
    required this.onCharacterPressed,
    this.characterName = 'Roxanne',
    this.feedbackText = '♥ +1',
    this.assetAspectRatio = 1500 / 2600,
    this.alignment = Alignment.bottomCenter,
    this.visualOffset = Offset.zero,
    this.visibleLeftRatio = 0,
    this.visibleRightRatio = 1,
    this.visibleTopRatio = 0,
    this.visibleBottomRatio = 1,
  });

  final String asset;
  final Future<String?> Function() onCharacterPressed;
  final String characterName;
  final String feedbackText;
  final double assetAspectRatio;
  final Alignment alignment;
  final Offset visualOffset;
  final double visibleLeftRatio;
  final double visibleRightRatio;
  final double visibleTopRatio;
  final double visibleBottomRatio;

  @override
  State<ClickableCharacterSceneV3> createState() =>
      _ClickableCharacterSceneV3State();
}

class _ClickableCharacterSceneV3State extends State<ClickableCharacterSceneV3> {
  final List<_CharacterFeedbackEntryV3> _feedbacks = [];
  int _feedbackSequence = 0;
  bool _reacting = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final visibleRect = _visibleArtRectFor(size);
      final renderedImageWidth = size.height * widget.assetAspectRatio;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedScale(
              key: const ValueKey('ryomi_character_reaction_v3'),
              scale: _reacting ? 1.018 : 1,
              alignment: widget.alignment,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOutBack,
              child: Transform.translate(
                offset: widget.visualOffset,
                child: Align(
                  alignment: widget.alignment,
                  child: OverflowBox(
                    minWidth: renderedImageWidth,
                    maxWidth: renderedImageWidth,
                    minHeight: size.height,
                    maxHeight: size.height,
                    child: Image.asset(
                      widget.asset,
                      key: const ValueKey('ryomi_official_art_v3'),
                      fit: BoxFit.contain,
                      alignment: widget.alignment,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) =>
                          _CharacterAssetFallbackV3(name: widget.characterName),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: visibleRect,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Semantics(
                button: true,
                label: widget.characterName,
                hint: 'Clique para ganhar afeição',
                child: Listener(
                  key: const ValueKey('ryomi_character_clickable_v3'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) =>
                      _handlePointerDown(event, visibleRect.topLeft),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          for (final feedback in _feedbacks)
            Positioned(
              key: ValueKey('ryomi_affection_feedback_position_${feedback.id}'),
              left: feedback.position.dx - 26,
              top: feedback.position.dy - 34,
              child: IgnorePointer(
                child: _CharacterAffectionFeedbackV3(
                  text: feedback.text,
                  onFinished: () => _removeFeedback(feedback.id),
                ),
              ),
            ),
        ],
      );
    },
  );

  Rect _visibleArtRectFor(Size size) {
    if (size.width <= 0 || size.height <= 0) return Rect.zero;
    final renderedHeight = size.height;
    final renderedWidth = renderedHeight * widget.assetAspectRatio;
    final left = (size.width - renderedWidth) / 2;
    final top = size.height - renderedHeight;
    final visibleLeft = left + renderedWidth * widget.visibleLeftRatio;
    final visibleTop = top + renderedHeight * widget.visibleTopRatio;
    final visibleWidth =
        renderedWidth * (widget.visibleRightRatio - widget.visibleLeftRatio);
    final visibleHeight =
        renderedHeight * (widget.visibleBottomRatio - widget.visibleTopRatio);
    return Rect.fromLTWH(
      visibleLeft,
      visibleTop,
      math.max(0, visibleWidth),
      math.max(0, visibleHeight),
    );
  }

  Future<void> _handlePointerDown(
    PointerDownEvent event,
    Offset artOffset,
  ) async {
    if (event.buttons != kPrimaryButton) return;
    final feedbackText = await widget.onCharacterPressed();
    if (!mounted || feedbackText == null) return;
    _triggerFeedback(artOffset + event.localPosition, feedbackText);
  }

  void _triggerFeedback(Offset position, String text) {
    final id = _feedbackSequence++;
    setState(() {
      _reacting = true;
      _feedbacks.add(_CharacterFeedbackEntryV3(id, position, text));
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _reacting = false);
    });
  }

  void _removeFeedback(int id) {
    if (!mounted) return;
    setState(() => _feedbacks.removeWhere((entry) => entry.id == id));
  }
}

class _CharacterAssetFallbackV3 extends StatelessWidget {
  const _CharacterAssetFallbackV3({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Center(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ConnectionsColorsV3.paper.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ConnectionsColorsV3.outlineSoft),
      ),
      child: SizedBox(
        width: 160,
        height: 260,
        child: Center(
          child: Text(
            (name.isEmpty ? '?' : name.characters.first).toUpperCase(),
            style: ConnectionsTypographyV3.windowTitle(
              size: 44,
            ).copyWith(color: ConnectionsColorsV3.relationshipDark),
          ),
        ),
      ),
    ),
  );
}

class _CharacterFeedbackEntryV3 {
  const _CharacterFeedbackEntryV3(this.id, this.position, this.text);

  final int id;
  final Offset position;
  final String text;
}

class _CharacterAffectionFeedbackV3 extends StatefulWidget {
  const _CharacterAffectionFeedbackV3({
    required this.text,
    required this.onFinished,
  });

  final String text;
  final VoidCallback onFinished;

  @override
  State<_CharacterAffectionFeedbackV3> createState() =>
      _CharacterAffectionFeedbackV3State();
}

class _CharacterAffectionFeedbackV3State
    extends State<_CharacterAffectionFeedbackV3>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 37),
    ]).animate(_controller);
    _slide = Tween(
      begin: const Offset(0, .16),
      end: const Offset(0, -.56),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .82, end: 1.08), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 72),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _FeedbackPillV3(
        key: const ValueKey('ryomi_affection_feedback_v3'),
        text: widget.text,
      );
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: _FeedbackPillV3(
            key: const ValueKey('ryomi_affection_feedback_v3'),
            text: widget.text,
          ),
        ),
      ),
    );
  }
}

class _FeedbackPillV3 extends StatelessWidget {
  const _FeedbackPillV3({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ConnectionsColorsV3.paper,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: ConnectionsColorsV3.outline,
        width: ConnectionsShadowsV3.outlineThin,
      ),
      boxShadow: [
        BoxShadow(
          color: ConnectionsColorsV3.relationshipDark.withValues(alpha: .9),
          offset: const Offset(0, 3),
          blurRadius: 0,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        text,
        maxLines: 1,
        style: ConnectionsTypographyV3.badge(
          size: 13,
        ).copyWith(color: ConnectionsColorsV3.relationshipDark),
      ),
    ),
  );
}
