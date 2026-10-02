import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/number_formatter.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/idle_balance.dart';
import '../../core/character_catalog.dart';
import '../../data/character_routes.dart';
import '../../services/game_audio_hooks.dart';
import '../../shared/game_ui.dart';

Future<void> showGiftSelectionDialog(
  BuildContext context,
  GameController controller, {
  String characterId = PlayableCharacterIds.roxanne,
  ValueChanged<ActionResult>? onDelivered,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: .92,
        child: GiftSelectionDialog(
          controller: controller,
          characterId: characterId,
          onDelivered: onDelivered,
          embedded: true,
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    barrierColor: GameColors.ink.withValues(alpha: .32),
    builder: (_) => GiftSelectionDialog(
      controller: controller,
      characterId: characterId,
      onDelivered: onDelivered,
    ),
  );
}

class GiftSelectionDialog extends StatefulWidget {
  const GiftSelectionDialog({
    super.key,
    required this.controller,
    required this.characterId,
    this.onDelivered,
    this.embedded = false,
  });

  final GameController controller;
  final String characterId;
  final ValueChanged<ActionResult>? onDelivered;
  final bool embedded;

  @override
  State<GiftSelectionDialog> createState() => _GiftSelectionDialogState();
}

class _GiftSelectionDialogState extends State<GiftSelectionDialog> {
  GiftDefinition selected = IdleBalance.gifts.first;
  int quantity = 1;
  bool sending = false;

  int get maximum =>
      selected.price == 0 ? 0 : widget.controller.state.money ~/ selected.price;
  int get safeQuantity => quantity.clamp(1, 2147483647);

  int? get _remainingObjective {
    final progress = widget.controller.state.characters[widget.characterId];
    if (progress == null) return null;
    for (final requirement in CharacterRouteCatalog.byCharacterId(
      widget.characterId,
    ).stageFor(progress.stage).requirements) {
      if (requirement.type == CharacterRouteRequirementType.giftDelivered &&
          requirement.targetId == selected.id &&
          requirement.isResolved) {
        return math.max(
          0,
          requirement.requiredValue! -
              (progress.giftDeliveries[selected.id] ?? 0),
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920, maxHeight: 700),
      child: ColoredBox(
        color: GameColors.paper,
        child: Padding(
          padding: const EdgeInsets.all(GameSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [GameColors.rose, GameColors.peach],
                      ),
                      borderRadius: BorderRadius.circular(GameRadii.large),
                      boxShadow: const [
                        BoxShadow(
                          color: GameColors.brownShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.redeem_rounded,
                      color: GameColors.cream,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRESENTEAR ${PlayableCharacterCatalog.byId(widget.characterId).visibleName.toUpperCase()}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text(
                          'Um gesto certo muda a frequência entre vocês.',
                          style: TextStyle(
                            color: GameColors.softInk,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 700;
                    final grid = _GiftGrid(
                      selected: selected,
                      onSelected: (gift) => setState(() {
                        selected = gift;
                        quantity = 1;
                      }),
                    );
                    final summary = _summary(context);
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 7, child: grid),
                          const SizedBox(width: 16),
                          SizedBox(width: 260, child: summary),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(child: grid),
                        const SizedBox(height: 10),
                        summary,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.embedded) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: content,
      );
    }
    return Dialog(insetPadding: const EdgeInsets.all(12), child: content);
  }

  Widget _summary(BuildContext context) {
    final amount = safeQuantity;
    final totalCost = selected.price * amount;
    final totalAffection = selected.affection * amount;
    return GamePanel(
      borderColor: GameColors.magenta.withValues(alpha: .7),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GameColors.blush.withValues(alpha: .95),
          GameColors.paper,
          GameColors.roseBeige,
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_giftIcon(selected.id), color: GameColors.magenta, size: 34),
          const SizedBox(height: 8),
          Text(selected.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(
            selected.description,
            style: const TextStyle(
              color: GameColors.softInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const SizedBox(height: 13),
          const Text(
            'QUANTIDADE',
            style: TextStyle(
              color: GameColors.softInk,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _QuantityButton(
                label: '-10',
                selected: false,
                onPressed: () =>
                    setState(() => quantity = math.max(1, quantity - 10)),
              ),
              _QuantityButton(
                label: '-1',
                selected: false,
                onPressed: () =>
                    setState(() => quantity = math.max(1, quantity - 1)),
              ),
              SizedBox(
                width: 64,
                child: TextFormField(
                  initialValue: '$quantity',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) => setState(
                    () => quantity = math.max(1, int.tryParse(value) ?? 1),
                  ),
                ),
              ),
              _QuantityButton(
                label: '+1',
                selected: false,
                onPressed: () => setState(
                  () => quantity = math.min(2147483647, quantity + 1),
                ),
              ),
              _QuantityButton(
                label: '+10',
                selected: false,
                onPressed: () => setState(
                  () => quantity = math.min(2147483647, quantity + 10),
                ),
              ),
              _QuantityButton(
                label: 'Máx.',
                selected: quantity == maximum,
                onPressed: () => setState(() => quantity = maximum),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _SummaryLine(
            label: 'Preço unitário',
            value: NumberFormatter.money(selected.price),
          ),
          _SummaryLine(
            label: 'Custo total',
            value: NumberFormatter.money(totalCost),
            color: GameColors.gold,
          ),
          _SummaryLine(
            label: 'Afeição',
            value: '+$totalAffection',
            color: GameColors.rose,
          ),
          _SummaryLine(
            label: 'Saldo restante',
            value: NumberFormatter.money(
              widget.controller.state.money - totalCost,
            ),
          ),
          if (_remainingObjective != null) ...[
            const SizedBox(height: 6),
            Text(
              _remainingObjective == 0
                  ? 'OBJETIVO CONCLUÍDO'
                  : 'Objetivo atual: faltam $_remainingObjective',
              style: const TextStyle(
                color: GameColors.softInk,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_remainingObjective! > 0)
              TextButton(
                onPressed: () =>
                    setState(() => quantity = _remainingObjective!),
                child: const Text('COMPLETAR OBJETIVO'),
              ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('confirm_gift'),
              onPressed:
                  sending ||
                      amount <= 0 ||
                      totalCost > widget.controller.state.money
                  ? null
                  : () => _send(amount),
              style: FilledButton.styleFrom(
                backgroundColor: GameColors.magenta,
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: GameColors.magenta.withValues(alpha: .28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GameRadii.pill),
                ),
              ),
              icon: const Icon(Icons.favorite_rounded),
              label: Text(
                totalCost > widget.controller.state.money
                    ? 'Saldo insuficiente'
                    : 'Comprar e presentear',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(int amount) async {
    setState(() => sending = true);
    final result = await widget.controller.gift(
      widget.characterId,
      selected.id,
      amount,
    );
    if (!mounted) return;
    setState(() => sending = false);
    GameAudioHooks.emit(GameAudioCue.gift);
    widget.onDelivered?.call(result);
    if (widget.onDelivered == null) showGameResult(context, result);
  }
}

IconData _giftIcon(String id) => switch (id) {
  'cafe' => Icons.coffee_rounded,
  'chocolate' => Icons.favorite_rounded,
  'livro' => Icons.menu_book_rounded,
  'vinil' => Icons.album_rounded,
  'fones' => Icons.headphones_rounded,
  'cobre' => Icons.auto_awesome_rounded,
  _ => Icons.help_outline_rounded,
};

class _GiftGrid extends StatelessWidget {
  const _GiftGrid({required this.selected, required this.onSelected});

  final GiftDefinition selected;
  final ValueChanged<GiftDefinition> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      itemCount: IdleBalance.gifts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: constraints.maxWidth >= 520 ? 3 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: constraints.maxWidth >= 520 ? 1.35 : 1.18,
      ),
      itemBuilder: (context, index) {
        final gift = IdleBalance.gifts[index];
        final active = gift.id == selected.id;
        return InkWell(
          onTap: () {
            GameAudioHooks.emit(GameAudioCue.click);
            onSelected(gift);
          },
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(GameRadii.medium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [GameColors.blush, GameColors.roseBeige],
                    )
                  : null,
              color: active ? null : Colors.white.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(GameRadii.large),
              border: Border.all(
                color: active ? GameColors.magenta : GameColors.cuteStroke,
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: GameColors.magenta.withValues(alpha: .18),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: GameColors.brownShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _giftIcon(gift.id),
                      color: active ? GameColors.magenta : GameColors.coral,
                      size: 28,
                    ),
                    const Spacer(),
                    Text(
                      '+${gift.affection}',
                      style: const TextStyle(
                        color: GameColors.rose,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  gift.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GameColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  NumberFormatter.money(gift.price),
                  style: const TextStyle(
                    color: GameColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(GameRadii.small),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? GameColors.magenta : Colors.white,
        borderRadius: BorderRadius.circular(GameRadii.small),
        border: Border.all(
          color: selected ? GameColors.magenta : GameColors.cuteStroke,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : GameColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.color = GameColors.ink,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: GameColors.softInk, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}
