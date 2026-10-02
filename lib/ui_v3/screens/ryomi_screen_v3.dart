import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/character_catalog.dart';
import '../components/character_selector_v3.dart';
import '../controllers/ryomi_windows_controller_v3.dart';
import '../layout/ryomi_breakpoints_v3.dart';
import '../layout/dev_scene_layout_config.dart';
import '../layout/ryomi_scene_layout_v3.dart';

class RyomiScreenV3 extends StatefulWidget {
  const RyomiScreenV3({
    super.key,
    required this.controller,
    required this.spec,
    this.layoutEditor,
  });

  final GameController controller;
  final RyomiLayoutSpec spec;
  final DevSceneLayoutController? layoutEditor;

  @override
  State<RyomiScreenV3> createState() => _RyomiScreenV3State();
}

class _RyomiScreenV3State extends State<RyomiScreenV3> {
  late final RyomiWindowsControllerV3 _windowsController;
  String _selectedCharacterId =
      PlayableCharacterCatalog.primaryRouteCharacterId;

  @override
  void initState() {
    super.initState();
    _windowsController = RyomiWindowsControllerV3();
  }

  @override
  void dispose() {
    _windowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: const ValueKey('ryomi_screen_v3'),
    builder: (context, constraints) {
      final content = widget.spec.usesVerticalFrame ? _vertical() : _desktop();
      if (widget.layoutEditor?.editorOpen != true) return content;
      return Stack(
        children: [
          content,
          _LayoutEditorOverlay(controller: widget.layoutEditor!),
        ],
      );
    },
  );

  Widget _vertical() {
    return Column(
      key: const ValueKey('ryomi_screen_v3_vertical_flow'),
      children: [
        SizedBox(
          key: const ValueKey('character_selector_region_v3'),
          height: widget.spec.compactSelectorHeight,
          child: CharacterSelectorV3(
            characters: widget.controller.state.characters,
            selectedCharacterId: _selectedCharacterId,
            compact: true,
            onSelected: _selectCharacter,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          key: const ValueKey('scene_region_v3'),
          child: RyomiSceneLayoutV3(
            controller: widget.controller,
            spec: widget.spec,
            windowsController: _windowsController,
            selectedCharacterId: _selectedCharacterId,
            layoutEditor: widget.layoutEditor,
          ),
        ),
      ],
    );
  }

  Widget _desktop() => Row(
    key: const ValueKey('ryomi_screen_v3_main_row'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        key: const ValueKey('character_selector_region_v3'),
        width: widget.spec.selectorWidth,
        child: CharacterSelectorV3(
          characters: widget.controller.state.characters,
          selectedCharacterId: _selectedCharacterId,
          desktopCompact: widget.spec.isCompactDesktop,
          wideDesktop: widget.spec.isWideDesktop,
          onSelected: _selectCharacter,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        key: const ValueKey('scene_region_v3'),
        child: RyomiSceneLayoutV3(
          controller: widget.controller,
          spec: widget.spec,
          windowsController: _windowsController,
          selectedCharacterId: _selectedCharacterId,
          layoutEditor: widget.layoutEditor,
        ),
      ),
    ],
  );

  void _selectCharacter(String id) {
    final canonical = PlayableCharacterCatalog.canonicalId(id);
    if (_selectedCharacterId == canonical) return;
    setState(() => _selectedCharacterId = canonical);
    widget.layoutEditor?.selectCharacter(canonical);
  }
}

class _LayoutEditorOverlay extends StatelessWidget {
  const _LayoutEditorOverlay({required this.controller});
  final DevSceneLayoutController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          controller.canvasSize = constraints.biggest;
          return Stack(
            children: [
              if (!controller.preview)
                for (final item in DevLayoutElement.values)
                  _EditorHitbox(
                    controller: controller,
                    item: item,
                    canvas: constraints.biggest,
                  ),
              if (!controller.preview)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _LayoutEditorPanel(controller: controller),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _LayoutEditorPanel extends StatelessWidget {
  const _LayoutEditorPanel({required this.controller});
  final DevSceneLayoutController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black87,
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 330,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EDITOR DE LAYOUT · ${controller.mode == DevLayoutMode.global ? 'GLOBAL' : 'PERSONAGEM'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${controller.canvasSize.width.toInt()}×${controller.canvasSize.height.toInt()} · ${controller.breakpointFor(controller.canvasSize).name}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              controller.dirty ? 'ALTERAÇÕES NÃO SALVAS' : 'Rascunho salvo',
              style: TextStyle(
                color: controller.dirty ? Colors.amber : Colors.greenAccent,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            if (controller.mode == DevLayoutMode.global)
              DropdownButton<DevLayoutElement>(
                value: controller.selected,
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (value != null) controller.selectElement(value);
                },
                items: DevLayoutElement.values
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item.name)),
                    )
                    .toList(),
              )
            else
              _CharacterAdjustmentRow(controller: controller),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton(
                  onPressed: () => controller.selectMode(DevLayoutMode.global),
                  child: const Text('EDITAR GLOBAL'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      controller.selectMode(DevLayoutMode.character),
                  child: const Text('AJUSTAR PERSONAGEM'),
                ),
                OutlinedButton(
                  onPressed: () => controller.setPreview(!controller.preview),
                  child: Text(controller.preview ? 'EDITAR' : 'PREVIEW'),
                ),
                OutlinedButton(
                  onPressed: controller.canUndo ? controller.undo : null,
                  child: const Text('DESFAZER'),
                ),
                OutlinedButton(
                  onPressed: controller.canRedo ? controller.redo : null,
                  child: const Text('REFAZER'),
                ),
                FilledButton(
                  onPressed: controller.save,
                  child: const Text('SALVAR RASCUNHO'),
                ),
                OutlinedButton(
                  onPressed: controller.close,
                  child: const Text('SAIR'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CharacterAdjustmentRow extends StatelessWidget {
  const _CharacterAdjustmentRow({required this.controller});
  final DevSceneLayoutController controller;

  @override
  Widget build(BuildContext context) {
    final value = controller.overrideFor(controller.selectedCharacterId);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        const Text('Escala', style: TextStyle(color: Colors.white70)),
        IconButton(
          tooltip: 'Reduzir escala',
          color: Colors.white,
          onPressed: () =>
              controller.updateCharacter(scale: value.scaleMultiplier - .05),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '${value.scaleMultiplier.toStringAsFixed(2)}×',
          style: const TextStyle(color: Colors.white),
        ),
        IconButton(
          tooltip: 'Aumentar escala',
          color: Colors.white,
          onPressed: () =>
              controller.updateCharacter(scale: value.scaleMultiplier + .05),
          icon: const Icon(Icons.add_circle_outline),
        ),
        IconButton(
          tooltip: 'Centralizar personagem',
          color: Colors.white,
          onPressed: () => controller.updateCharacter(offsetX: 0, offsetY: 0),
          icon: const Icon(Icons.center_focus_strong),
        ),
      ],
    );
  }
}

class _EditorHitbox extends StatelessWidget {
  const _EditorHitbox({
    required this.controller,
    required this.item,
    required this.canvas,
  });
  final DevSceneLayoutController controller;
  final DevLayoutElement item;
  final Size canvas;
  @override
  Widget build(BuildContext context) {
    if (controller.mode == DevLayoutMode.character &&
        item != DevLayoutElement.characterArea)
      return const SizedBox();
    final r = controller.draft.elements[item]!;
    final chosen = item == controller.selected;
    final characterMode = controller.mode == DevLayoutMode.character;
    return Positioned(
      left: r.x * canvas.width,
      top: r.y * canvas.height,
      width: r.width * canvas.width,
      height: r.height * canvas.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => controller.selectElement(item),
        onPanStart: (_) {
          controller.selectElement(item);
          controller.beginTransaction();
        },
        onPanUpdate: (d) => characterMode
            ? controller.updateCharacter(
                offsetX:
                    controller
                        .overrideFor(controller.selectedCharacterId)
                        .offsetX +
                    d.delta.dx,
                offsetY:
                    controller
                        .overrideFor(controller.selectedCharacterId)
                        .offsetY +
                    d.delta.dy,
              )
            : controller.updateElement(
                item,
                r.copyWith(
                  x: r.x + d.delta.dx / canvas.width,
                  y: r.y + d.delta.dy / canvas.height,
                ),
              ),
        onPanEnd: (_) => controller.endTransaction(),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: chosen ? Colors.amber : Colors.cyanAccent,
                    width: chosen ? 3 : 1,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 2,
              top: 2,
              child: Text(
                item.name,
                style: const TextStyle(color: Colors.amber, fontSize: 10),
              ),
            ),
            if (chosen && !characterMode)
              Positioned(
                right: -7,
                bottom: -7,
                child: GestureDetector(
                  onPanStart: (_) => controller.beginTransaction(),
                  onPanUpdate: (d) => controller.updateElement(
                    item,
                    r.copyWith(
                      width: r.width + d.delta.dx / canvas.width,
                      height: r.height + d.delta.dy / canvas.height,
                    ),
                  ),
                  onPanEnd: (_) => controller.endTransaction(),
                  child: const Icon(
                    Icons.open_in_full,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
