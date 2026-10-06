import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/character_catalog.dart';
import '../../core/number_formatter.dart';
import '../../core/theme/game_tokens.dart';
import '../../data/character_routes.dart';
import '../../data/date_locations.dart';
import '../../models/idle_models.dart';

Future<void> showDateSelectionDialog(
  BuildContext context,
  GameController controller, {
  required String characterId,
  ValueChanged<ActionResult>? onStarted,
}) => showDialog<void>(
  context: context,
  builder: (_) => DateSelectionDialog(
    controller: controller,
    characterId: characterId,
    onStarted: onStarted,
  ),
);

class DateSelectionDialog extends StatefulWidget {
  const DateSelectionDialog({
    super.key,
    required this.controller,
    required this.characterId,
    this.onStarted,
  });
  final GameController controller;
  final String characterId;
  final ValueChanged<ActionResult>? onStarted;
  @override
  State<DateSelectionDialog> createState() => _DateSelectionDialogState();
}

class _DateSelectionDialogState extends State<DateSelectionDialog> {
  Timer? _timer;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      await widget.controller.tick();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterId = PlayableCharacterCatalog.canonicalId(
      widget.characterId,
    );
    final active = widget.controller.state.activeEncounter;
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 700),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: GameColors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      active == null
                          ? 'Escolher encontro'
                          : 'Encontro acontecendo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _message!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            Expanded(
              child: active == null
                  ? _DateLocationsView(
                      controller: widget.controller,
                      characterId: characterId,
                      busy: _busy,
                      onStart: _start,
                    )
                  : _ActiveDateView(
                      controller: widget.controller,
                      active: active,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(String locationId) async {
    setState(() => _busy = true);
    final result = await widget.controller.startDate(
      widget.characterId,
      locationId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onStarted?.call(result);
    if (!result.message.contains('iniciado')) {
      setState(() => _message = result.message);
    }
  }
}

class _DateLocationsView extends StatelessWidget {
  const _DateLocationsView({
    required this.controller,
    required this.characterId,
    required this.busy,
    required this.onStart,
  });
  final GameController controller;
  final String characterId;
  final bool busy;
  final ValueChanged<String> onStart;
  @override
  Widget build(BuildContext context) {
    final character = PlayableCharacterCatalog.byId(characterId);
    final stage = controller.state.characters[characterId]?.stage ?? 0;
    final requirements = CharacterDateRequirements.forStage(characterId, stage);
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: DateLocationCatalog.locations.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 410,
        childAspectRatio: 1.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final location = DateLocationCatalog.locations[index];
        final count = controller.dateCount(characterId, location.id);
        final matches = requirements.where(
          (item) => item.locationId == location.id,
        );
        final requirement = matches.isEmpty ? null : matches.first;
        final afford = controller.state.money >= location.baseCost;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _DateArt(
                  location: location,
                  characterId: characterId,
                  small: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${NumberFormatter.money(location.baseCost)} • ${location.baseDuration.inSeconds}s',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${character.visibleName}: $count realizados',
                          style: const TextStyle(fontSize: 11),
                        ),
                        if (requirement != null)
                          Text(
                            'REQUISITO ATUAL  $count/${requirement.requiredCount}${count >= requirement.requiredCount ? ' ✓' : ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        const SizedBox(height: 4),
                        FilledButton(
                          onPressed: busy || !afford
                              ? null
                              : () => onStart(location.id),
                          child: Text(
                            afford ? 'Iniciar' : 'Dinheiro insuficiente',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActiveDateView extends StatelessWidget {
  const _ActiveDateView({required this.controller, required this.active});
  final GameController controller;
  final ActiveEncounter active;
  @override
  Widget build(BuildContext context) {
    final location = DateLocationCatalog.byId(active.locationId);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final end = active.endsAt ?? now;
    final total = (end - active.startedAt).clamp(1, 1 << 30);
    final factor = ((now - active.startedAt) / total).clamp(0.0, 1.0);
    final remaining = Duration(milliseconds: (end - now).clamp(0, 1 << 30));
    final character = PlayableCharacterCatalog.byId(active.characterId);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Expanded(
            child: _DateArt(
              location: location,
              characterId: active.characterId,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${character.visibleName} — ${location.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: factor, minHeight: 12),
          const SizedBox(height: 8),
          Text('${remaining.inSeconds}s restantes'),
        ],
      ),
    );
  }
}

class _DateArt extends StatelessWidget {
  const _DateArt({
    required this.location,
    required this.characterId,
    this.small = false,
  });
  final DateLocationDefinition location;
  final String characterId;
  final bool small;
  @override
  Widget build(BuildContext context) => Container(
    width: small ? 74 : double.infinity,
    height: small ? double.infinity : null,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: GameColors.roseBeige,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Image.asset(
      DateLocationCatalog.preferredImageAsset(characterId, location.id),
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => Image.asset(
        location.imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, fallbackError, fallbackStackTrace) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(location.icon, size: small ? 32 : 80, color: GameColors.coral),
            if (!small) ...[
              const SizedBox(height: 10),
              Text(
                location.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Text(
                'Arte do encontro será adicionada',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
