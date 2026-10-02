import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/character_catalog.dart';
import '../components/connections_global_background_v3.dart';
import '../components/clickable_character_scene_v3.dart';
import '../components/dialogue_window_v3.dart';
import '../components/interaction_window_v3.dart';
import '../components/relationship_window_v3.dart';
import '../controllers/ryomi_windows_controller_v3.dart';
import 'dev_scene_layout_config.dart';
import 'ryomi_breakpoints_v3.dart';

class RyomiSceneLayoutV3 extends StatelessWidget {
  const RyomiSceneLayoutV3({
    super.key,
    required this.controller,
    required this.spec,
    required this.windowsController,
    required this.selectedCharacterId,
    this.layoutEditor,
  });

  final GameController controller;
  final RyomiLayoutSpec spec;
  final RyomiWindowsControllerV3 windowsController;
  final String selectedCharacterId;
  final DevSceneLayoutController? layoutEditor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: const ValueKey('ryomi_scene_layout_v3'),
    builder: (context, constraints) => ConnectionsGlobalBackgroundV3(
      key: const ValueKey('ryomi_scene_surface_v3'),
      child: spec.usesDesktopFrame
          ? _DesktopSceneV3(
              controller: controller,
              spec: spec,
              windowsController: windowsController,
              selectedCharacterId: selectedCharacterId,
              layoutEditor: layoutEditor,
            )
          : _VerticalSceneV3(
              controller: controller,
              spec: spec,
              windowsController: windowsController,
              selectedCharacterId: selectedCharacterId,
            ),
    ),
  );
}

class _DesktopSceneV3 extends StatelessWidget {
  const _DesktopSceneV3({
    required this.controller,
    required this.spec,
    required this.windowsController,
    required this.selectedCharacterId,
    this.layoutEditor,
  });

  final GameController controller;
  final RyomiLayoutSpec spec;
  final RyomiWindowsControllerV3 windowsController;
  final String selectedCharacterId;
  final DevSceneLayoutController? layoutEditor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final compact = spec.mode == RyomiLayoutMode.compactDesktop;
      final selectedCharacter = PlayableCharacterCatalog.byId(
        selectedCharacterId,
      );
      final presentation = selectedCharacter.scenePresentation;
      final pad = spec.isWideDesktop
          ? 18.0
          : compact
          ? 10.0
          : 16.0;
      final relationshipWidth = spec.isWideDesktop
          ? 360.0
          : compact
          ? (width < 900 ? 238.0 : 246.0)
          : 320.0;
      final relationshipHeight = spec.isWideDesktop
          ? 268.0
          : compact
          ? (spec.shortHeight ? 208.0 : 226.0)
          : 255.0;
      final expandedRelationshipHeight =
          relationshipHeight + (compact ? 52.0 : 64.0);
      final actionsWidth = spec.isWideDesktop
          ? 370.0
          : compact
          ? (width < 900 ? 248.0 : 258.0)
          : 330.0;
      final actionsHeight = spec.isWideDesktop
          ? 228.0
          : compact
          ? (spec.shortHeight ? 190.0 : 202.0)
          : 220.0;
      final dialogueWidth = compact
          ? width * (width < 900 ? .66 : .62)
          : math.min(width * .60, 900.0);
      final dialogueHeight = spec.isWideDesktop
          ? 122.0
          : compact
          ? (spec.shortHeight ? 104.0 : 112.0)
          : 110.0;
      final minimizedRelationshipWidth = compact ? 178.0 : 218.0;
      final minimizedRelationshipHeight = compact ? 40.0 : 44.0;
      final minimizedActionsWidth = compact ? 112.0 : 128.0;
      final minimizedActionsHeight = compact ? 40.0 : 44.0;
      final minimizedDialogueWidth = compact ? 132.0 : 156.0;
      final minimizedDialogueHeight = compact ? 40.0 : 44.0;
      final dialogueBottom = spec.isWideDesktop
          ? 24.0
          : compact
          ? 14.0
          : 22.0;

      return AnimatedBuilder(
        animation: Listenable.merge([windowsController, layoutEditor]),
        builder: (context, _) {
          final activeDialogueHeight = windowsController.dialogueOpen
              ? dialogueHeight
              : minimizedDialogueHeight;
          final activeDialogueWidth = windowsController.dialogueOpen
              ? dialogueWidth
              : minimizedDialogueWidth;
          final dialogueTop = height - dialogueBottom - activeDialogueHeight;
          final activeRelationshipWidth = windowsController.relationshipOpen
              ? relationshipWidth
              : minimizedRelationshipWidth;
          final relationshipAvailableHeight = math.max(
            minimizedRelationshipHeight,
            dialogueTop - pad - 12,
          );
          final activeRelationshipHeight = windowsController.relationshipOpen
              ? math.min(
                  windowsController.objectivesExpanded
                      ? expandedRelationshipHeight
                      : relationshipHeight,
                  relationshipAvailableHeight,
                )
              : minimizedRelationshipHeight;
          final activeActionsWidth = windowsController.interactionOpen
              ? actionsWidth
              : minimizedActionsWidth;
          final activeActionsHeight = windowsController.interactionOpen
              ? actionsHeight
              : minimizedActionsHeight;
          final visibleHeightRatio = math.max(
            .01,
            presentation.visibleHeightRatio,
          );
          final visibleWidthRatio = math.max(
            .01,
            presentation.visibleWidthRatio,
          );
          // The scene is a layered stage: dialogue and panels are overlays,
          // never structural reservations that shrink the character.
          final targetVisibleHeightRatio = compact ? .76 : .86;
          final maxPortraitHeight = height * .98 / visibleHeightRatio;
          final desiredPortraitHeight =
              height * targetVisibleHeightRatio / visibleHeightRatio;
          final widthLimitedHeight =
              width * .76 / (presentation.assetAspectRatio * visibleWidthRatio);
          final portraitHeight = math.max(
            0.0,
            math.min(
              maxPortraitHeight,
              math.min(desiredPortraitHeight, widthLimitedHeight),
            ),
          );
          final portraitWidth = math.min(
            width,
            portraitHeight * presentation.assetAspectRatio,
          );
          // A hero is intentionally shifted into the center-right visual
          // corridor. This is generic geometry, not a character-specific hack.
          final portraitLeft = math.max(
            0.0,
            math.min(
              width - portraitWidth,
              (width - portraitWidth) / 2 + width * .12,
            ),
          );
          // The editor's approved baseline is the real scene layout. The
          // overlay is ROOT-gated, but its saved geometry is shared gameplay
          // data for every character and every normal session.
          final useDraft = layoutEditor != null;
          final relationshipDraft =
              layoutEditor?.draft.elements[DevLayoutElement.relationship];
          final actionsDraft =
              layoutEditor?.draft.elements[DevLayoutElement.actions];
          final dialogueDraft =
              layoutEditor?.draft.elements[DevLayoutElement.dialogue];
          final characterDraft =
              layoutEditor?.draft.elements[DevLayoutElement.characterArea];
          // One shared visual mould: Roxanne's useful (non-transparent)
          // bounds define the target height, center and baseline. Other PNGs
          // only change their full-image scale to reach that same useful size.
          final reference = PlayableCharacterCatalog.roxanne.scenePresentation;
          final referenceFullHeight = useDraft
              ? characterDraft!.height *
                    height *
                    DevSceneLayoutDraft.approvedCharacterScale
              : portraitHeight;
          final normalizedFullHeight =
              referenceFullHeight *
              reference.visibleHeightRatio /
              presentation.visibleHeightRatio;
          final normalizedFullWidth =
              normalizedFullHeight * presentation.assetAspectRatio;
          final referenceFullWidth =
              referenceFullHeight * reference.assetAspectRatio;
          final referenceAreaWidth = useDraft
              ? characterDraft!.width *
                    width *
                    DevSceneLayoutDraft.approvedCharacterScale
              : portraitWidth;
          final referenceAreaLeft = useDraft
              ? characterDraft!.x * width +
                    DevSceneLayoutDraft.approvedCharacterOffsetX
              : portraitLeft;
          final referenceImageLeft =
              referenceAreaLeft + (referenceAreaWidth - referenceFullWidth) / 2;
          final sharedVisualCenter =
              referenceImageLeft +
              referenceFullWidth *
                  (reference.visibleLeftRatio + reference.visibleRightRatio) /
                  2;
          final referenceBottom = useDraft
              ? height -
                    (characterDraft!.y + characterDraft.height) * height -
                    DevSceneLayoutDraft.approvedCharacterOffsetY
              : 0.0;
          final sharedVisualBottom =
              referenceBottom +
              referenceFullHeight * (1 - reference.visibleBottomRatio);
          final configuredRelationshipWidth =
              useDraft && windowsController.relationshipOpen
              ? relationshipDraft!.width * width
              : activeRelationshipWidth;
          final configuredRelationshipHeight =
              useDraft && windowsController.relationshipOpen
              ? relationshipDraft!.height * height
              : activeRelationshipHeight;
          final configuredActionsWidth =
              useDraft && windowsController.interactionOpen
              ? actionsDraft!.width * width
              : activeActionsWidth;
          final configuredActionsHeight =
              useDraft && windowsController.interactionOpen
              ? actionsDraft!.height * height
              : activeActionsHeight;
          final configuredDialogueWidth =
              useDraft && windowsController.dialogueOpen
              ? dialogueDraft!.width * width
              : activeDialogueWidth;
          final configuredDialogueHeight =
              useDraft && windowsController.dialogueOpen
              ? dialogueDraft!.height * height
              : activeDialogueHeight;
          final configuredPortraitWidth = normalizedFullWidth;
          final configuredPortraitHeight = normalizedFullHeight;
          final configuredPortraitLeft =
              sharedVisualCenter -
              normalizedFullWidth *
                  (presentation.visibleLeftRatio +
                      presentation.visibleRightRatio) /
                  2;
          final configuredPortraitBottom =
              sharedVisualBottom -
              normalizedFullHeight * (1 - presentation.visibleBottomRatio);
          final configuredRelationshipLeft =
              useDraft && windowsController.relationshipOpen
              ? relationshipDraft!.x * width
              : pad;
          final configuredRelationshipTop =
              useDraft && windowsController.relationshipOpen
              ? relationshipDraft!.y * height
              : pad;
          final configuredActionsRight =
              useDraft && windowsController.interactionOpen
              ? width - (actionsDraft!.x + actionsDraft.width) * width
              : pad;
          final configuredActionsTop =
              useDraft && windowsController.interactionOpen
              ? actionsDraft!.y * height
              : pad;
          // The dialogue always anchors to the center of the gameplay scene,
          // both expanded and minimized. It never participates in portrait
          // geometry, so toggling it cannot move or resize the character.
          final configuredDialogueLeft = (width - configuredDialogueWidth) / 2;
          final configuredDialogueBottom =
              useDraft && windowsController.dialogueOpen
              ? height - (dialogueDraft!.y + dialogueDraft.height) * height
              : dialogueBottom;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                key: const ValueKey('ryomi_character_area_v3'),
                left: configuredPortraitLeft,
                // Bottom anchoring keeps every sprite stable when dialogue is
                // minimized or restored. The dialogue deliberately overlays
                // the lower portion of this stage.
                bottom: configuredPortraitBottom,
                child: SizedBox(
                  width: configuredPortraitWidth,
                  height: configuredPortraitHeight,
                  child: ClickableCharacterSceneV3(
                    asset: selectedCharacter.sceneAsset,
                    characterName: selectedCharacter.visibleName,
                    assetAspectRatio: presentation.assetAspectRatio,
                    alignment: presentation.alignment,
                    visualOffset: presentation.visualOffset,
                    visibleLeftRatio: presentation.visibleLeftRatio,
                    visibleRightRatio: presentation.visibleRightRatio,
                    visibleTopRatio: presentation.visibleTopRatio,
                    visibleBottomRatio: presentation.visibleBottomRatio,
                    onCharacterPressed: selectedCharacter.routeReady
                        ? () => _tapCharacter(controller, selectedCharacter.id)
                        : () async => null,
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('relationship_window_position_v3'),
                left: configuredRelationshipLeft,
                top: configuredRelationshipTop,
                width: configuredRelationshipWidth,
                height: configuredRelationshipHeight,
                child: RelationshipWindowV3(
                  state: controller.state,
                  characterId: selectedCharacter.id,
                  compact: compact,
                  windowsController: windowsController,
                ),
              ),
              Positioned(
                key: const ValueKey('interaction_window_position_v3'),
                right: configuredActionsRight,
                top: configuredActionsTop,
                width: configuredActionsWidth,
                height: configuredActionsHeight,
                child: InteractionWindowV3(
                  controller: controller,
                  selectedCharacterId: selectedCharacter.id,
                  compact: compact,
                  windowsController: windowsController,
                ),
              ),
              Positioned(
                key: const ValueKey('dialogue_window_position_v3'),
                left: configuredDialogueLeft,
                bottom: configuredDialogueBottom,
                width: configuredDialogueWidth,
                height: configuredDialogueHeight,
                child: DialogueWindowV3(
                  compact: compact,
                  windowsController: windowsController,
                  selectedCharacterName: selectedCharacter.visibleName,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _VerticalSceneV3 extends StatelessWidget {
  const _VerticalSceneV3({
    required this.controller,
    required this.spec,
    required this.windowsController,
    required this.selectedCharacterId,
  });

  final GameController controller;
  final RyomiLayoutSpec spec;
  final RyomiWindowsControllerV3 windowsController;
  final String selectedCharacterId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final landscape = width > height;
      final selectedCharacter = PlayableCharacterCatalog.byId(
        selectedCharacterId,
      );
      final presentation = selectedCharacter.scenePresentation;
      final artHeight = spec.isMobile
          ? (landscape ? 230.0 : 330.0)
          : (landscape ? 300.0 : 390.0);
      final actionHeight = spec.isMobile ? 205.0 : 220.0;
      final dialogueHeight = spec.isMobile ? 116.0 : 122.0;
      final relationshipHeight = spec.isMobile ? 270.0 : 280.0;

      return SingleChildScrollView(
        key: const ValueKey('ryomi_scene_vertical_scroll_v3'),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: ConnectionsGlobalBackgroundV3(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const ValueKey('ryomi_character_area_v3'),
                    height: artHeight,
                    child: Center(
                      child: SizedBox(
                        width: math.min(width * .72, spec.isMobile ? 280 : 360),
                        height: artHeight,
                        child: ClickableCharacterSceneV3(
                          asset: selectedCharacter.sceneAsset,
                          characterName: selectedCharacter.visibleName,
                          assetAspectRatio: presentation.assetAspectRatio,
                          alignment: presentation.alignment,
                          visualOffset: presentation.visualOffset,
                          visibleLeftRatio: presentation.visibleLeftRatio,
                          visibleRightRatio: presentation.visibleRightRatio,
                          visibleTopRatio: presentation.visibleTopRatio,
                          visibleBottomRatio: presentation.visibleBottomRatio,
                          onCharacterPressed: selectedCharacter.routeReady
                              ? () => _tapCharacter(
                                  controller,
                                  selectedCharacter.id,
                                )
                              : () async => null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    key: const ValueKey('interaction_window_position_v3'),
                    height: actionHeight,
                    child: InteractionWindowV3(
                      controller: controller,
                      selectedCharacterId: selectedCharacter.id,
                      windowsController: windowsController,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    key: const ValueKey('dialogue_window_position_v3'),
                    height: dialogueHeight,
                    child: DialogueWindowV3(
                      windowsController: windowsController,
                      selectedCharacterName: selectedCharacter.visibleName,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    key: const ValueKey('relationship_window_position_v3'),
                    height: relationshipHeight,
                    child: RelationshipWindowV3(
                      state: controller.state,
                      characterId: selectedCharacter.id,
                      windowsController: windowsController,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<String?> _tapCharacter(
  GameController controller,
  String characterId,
) async {
  final result = await controller.tapCharacter(characterId);
  final reward = RegExp(r'\+\d+[^.]*').firstMatch(result.message)?.group(0);
  final amount = RegExp(r'\d+').firstMatch(reward ?? '')?.group(0);
  return amount == null ? null : '♥ +$amount';
}
