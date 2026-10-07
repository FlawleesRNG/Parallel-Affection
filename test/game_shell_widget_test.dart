import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/app/game_controller.dart';
import 'package:projeto_conexoes/core/character_catalog.dart';
import 'package:projeto_conexoes/core/idle_rules.dart';
import 'package:projeto_conexoes/core/relationship_stages.dart';
import 'package:projeto_conexoes/core/theme/app_theme.dart';
import 'package:projeto_conexoes/core/theme/game_tokens.dart';
import 'package:projeto_conexoes/core/theme/visual_themes.dart';
import 'package:projeto_conexoes/data/idle_balance.dart';
import 'package:projeto_conexoes/features/characters/gift_selection_dialog.dart';
import 'package:projeto_conexoes/features/game_shell/idle_dating_game_shell.dart';
import 'package:projeto_conexoes/models/idle_models.dart';
import 'package:projeto_conexoes/services/game_storage.dart';
import 'package:projeto_conexoes/services/simulation_service.dart';
import 'package:projeto_conexoes/shared/game_ui.dart';
import 'package:projeto_conexoes/ui_v3/components/character_dialogue_window_v3.dart';
import 'package:projeto_conexoes/ui_v3/components/character_selector_v3.dart';
import 'package:projeto_conexoes/ui_v3/components/top_hud_v3.dart';
import 'package:projeto_conexoes/ui_v3/debug/ui_debug_settings_v3.dart';
import 'package:projeto_conexoes/ui_v3/controllers/ryomi_windows_controller_v3.dart';
import 'package:projeto_conexoes/ui_v3/dialogue/dialogue_message_v3.dart';
import 'package:projeto_conexoes/ui_v3/dialogue/dialogue_queue_v3.dart';
import 'package:projeto_conexoes/ui_v3/layout/ryomi_breakpoints_v3.dart';

class _MemoryStorage implements GameStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _CountingStorage implements GameStorage {
  String? value;
  int writes = 0;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

Future<GameController> _controller() async {
  final controller = GameController(_MemoryStorage());
  await controller.initialize();
  return controller;
}

Widget _app(GameController controller) => MaterialApp(
  theme: AppTheme.dark(),
  debugShowCheckedModeBanner: false,
  home: IdleDatingGameShell(controller: controller),
);

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

void _expectNoActionOverlap(WidgetTester tester) {
  final ids = ['action_talk', 'action_interact', 'action_gift', 'action_date'];
  final rects = {for (final id in ids) id: _rect(tester, id)};
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      expect(
        rects[ids[i]]!.overlaps(rects[ids[j]]!),
        isFalse,
        reason: '${ids[i]} must not overlap ${ids[j]}',
      );
    }
  }
}

void _expectSameActionHeight(WidgetTester tester) {
  final heights = [
    _rect(tester, 'action_talk').height,
    _rect(tester, 'action_interact').height,
    _rect(tester, 'action_gift').height,
    _rect(tester, 'action_date').height,
  ];
  for (final height in heights.skip(1)) {
    expect(height, closeTo(heights.first, .1));
  }
}

void _expectBadgesInsideButtons(WidgetTester tester) {
  for (final id in ['talk', 'interact', 'gift', 'date']) {
    final badgeFinder = find.byKey(ValueKey('action_${id}_badge'));
    if (badgeFinder.evaluate().isEmpty) continue;
    final button = _rect(tester, 'action_$id');
    final badge = tester.getRect(badgeFinder);
    expect(button.contains(badge.topLeft), isTrue);
    expect(button.contains(badge.bottomRight), isTrue);
  }
}

void _expectActionGrid2x2(WidgetTester tester) {
  final talk = _rect(tester, 'action_talk');
  final interact = _rect(tester, 'action_interact');
  final gift = _rect(tester, 'action_gift');
  final date = _rect(tester, 'action_date');
  expect(talk.top, closeTo(interact.top, .1));
  expect(gift.top, closeTo(date.top, .1));
  expect(gift.top, greaterThan(talk.bottom));
  expect(talk.left, lessThan(interact.left));
  expect(gift.left, lessThan(date.left));
}

void _expectNoRegionOverlap(Map<String, Rect> regions) {
  final entries = regions.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      expect(
        entries[i].value.overlaps(entries[j].value),
        isFalse,
        reason: '${entries[i].key} must not overlap ${entries[j].key}',
      );
    }
  }
}

void _expectDesktopRyomiRegions(WidgetTester tester) {
  final selector = _rect(tester, 'character_selector_region');
  final progress = _rect(tester, 'relationship_progress_region');
  final character = _rect(tester, 'character_presentation_region');
  final controlsArea = _rect(tester, 'character_controls_area');
  final controls = _rect(tester, 'interaction_controls_region');
  final dialogue = _rect(tester, 'character_dialogue_region');
  final ryomiCard = _rect(tester, 'character_selector_ryomi');
  final characterHitbox = _rect(tester, 'ryomi_character_tap_area');

  expect(selector.right, lessThanOrEqualTo(progress.left + .1));
  expect(progress.right, lessThanOrEqualTo(character.left + .1));
  expect(character.right, lessThanOrEqualTo(controlsArea.left + .1));
  expect(controls.bottom, lessThanOrEqualTo(dialogue.top + .1));

  expect(ryomiCard.height, inInclusiveRange(64, 90));
  expect(ryomiCard.width, greaterThan(ryomiCard.height * 1.45));
  expect(progress.top, lessThanOrEqualTo(selector.top + .1));
  expect(controls.top, lessThanOrEqualTo(character.top + .1));
  expect(dialogue.left, greaterThan(character.center.dx));
  expect(dialogue.center.dx, greaterThan(character.center.dx));

  _expectNoRegionOverlap({
    'selector': selector,
    'progress': progress,
    'character': character,
    'controls/dialogue': controlsArea,
  });
  _expectNoRegionOverlap({'controls': controls, 'dialogue': dialogue});
  expect(characterHitbox.right, lessThanOrEqualTo(controlsArea.left + .1));
  expect(characterHitbox.left, greaterThanOrEqualTo(character.left - .1));
}

Future<void> _sendDevelopmentShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

Future<void> _enterUiV3(WidgetTester tester) async {
  tester.takeException();
  if (find.byKey(const ValueKey('ryomi_ui_v3_shell')).evaluate().isEmpty) {
    await _sendDevelopmentShortcut(tester, LogicalKeyboardKey.keyV);
    await tester.pumpAndSettle();
  }
  expect(find.byKey(const ValueKey('ryomi_ui_v3_shell')), findsOneWidget);
}

void _expectV3RegionLayout(WidgetTester tester, Size size) {
  final hud = _rect(tester, 'top_hud_v3');
  final dock = _rect(tester, 'bottom_dock_v3');
  final selector = _rect(tester, 'character_selector_region_v3');
  final scene = _rect(tester, 'scene_region_v3');
  final surface = _rect(tester, 'ryomi_scene_surface_v3');
  final relationship = _rect(tester, 'relationship_window_position_v3');
  final interaction = _rect(tester, 'interaction_window_position_v3');
  final dialogue = _rect(tester, 'dialogue_window_position_v3');
  final ryomi = _rect(tester, 'ryomi_official_art_v3');

  expect(hud.top, closeTo(0, .1));
  expect(hud.left, closeTo(0, .1));
  expect(hud.width, closeTo(size.width, .1));
  expect(hud.height, inInclusiveRange(64, 68));
  expect(find.byKey(const ValueKey('phone_button_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('phone_badge_slot_v3')), findsOneWidget);
  _expectV3PhoneHudOrder(tester);

  expect(dock.bottom, closeTo(size.height, .1));
  expect(dock.left, closeTo(0, .1));
  expect(dock.width, closeTo(size.width, .1));
  expect(dock.height, inInclusiveRange(92, 100));

  expect(selector.top, closeTo(hud.bottom, .1));
  expect(selector.bottom, closeTo(dock.top, .1));
  expect(selector.left, closeTo(0, .1));
  expect(
    selector.width,
    size.width >= 1500 ? closeTo(270, .1) : closeTo(245, .1),
  );

  expect(scene.left, closeTo(selector.right + 8, .1));
  expect(scene.top, closeTo(hud.bottom, .1));
  expect(scene.right, closeTo(size.width, .1));
  expect(scene.bottom, closeTo(dock.top, .1));
  expect(surface, equals(scene));

  // The ROOT layout editor persists approved positions, so desktop tests must
  // validate the gameplay-safe constraints instead of a previous hard-coded
  // origin. The approved composition may intentionally overlap the selector
  // seam by a few pixels, but the window must remain visible in the play area.
  expect(relationship.right, greaterThan(scene.left));
  expect(relationship.top, greaterThanOrEqualTo(scene.top));
  expect(relationship.right, lessThanOrEqualTo(scene.right));
  expect(relationship.bottom, lessThanOrEqualTo(scene.bottom));
  // Width and height are editable ROOT layout values. Keep the assertions
  // proportional to the stage so a persisted approved composition remains
  // covered without returning to fixed dashboard-sized panels.
  expect(relationship.width / scene.width, inInclusiveRange(.18, .46));
  expect(relationship.height / scene.height, inInclusiveRange(.28, .82));

  expect(interaction.right, greaterThan(scene.left));
  expect(interaction.top, greaterThanOrEqualTo(scene.top));
  expect(interaction.right, lessThanOrEqualTo(scene.right));
  expect(interaction.bottom, lessThanOrEqualTo(scene.bottom));
  expect(interaction.width / scene.width, inInclusiveRange(.20, .42));
  expect(interaction.height / scene.height, inInclusiveRange(.25, .56));

  expect(dialogue.center.dx, closeTo(scene.center.dx, 1));
  // The dialogue stays in the reserved lower strip; its exact margin is a
  // persisted editor setting rather than a fixed layout constant.
  expect(
    dialogue.bottom,
    inInclusiveRange(scene.bottom - scene.height * .08, scene.bottom),
  );
  expect(
    dialogue.width / scene.width,
    size.width >= 1800
        ? inInclusiveRange(.45, .62)
        : inInclusiveRange(.45, .62),
  );
  expect(dialogue.height / scene.height, inInclusiveRange(.10, .25));

  // Character position and scale are editable, but must remain a dominant
  // element in the central stage (not move into either side panel).
  expect(
    ryomi.center.dx,
    inInclusiveRange(
      scene.left + scene.width * .20,
      scene.right - scene.width * .12,
    ),
  );
  expect(ryomi.top, lessThan(scene.bottom));
  expect(ryomi.bottom, greaterThan(scene.top));
  expect(ryomi.height / scene.height, inInclusiveRange(.50, 1.50));
  final visibleRyomiHeight = ryomi.height * ((2560 - 157) / 2600);
  expect(visibleRyomiHeight / scene.height, inInclusiveRange(.45, 1.30));
  expect(ryomi.width, greaterThanOrEqualTo(230));
  expect(ryomi.width / ryomi.height, inInclusiveRange(.56, .59));
  final visibleRyomiLeft = ryomi.left + ryomi.width * (404 / 1500);
  final visibleRyomiRight = ryomi.left + ryomi.width * (1041 / 1500);
  expect(visibleRyomiLeft, greaterThan(scene.left));
  expect(visibleRyomiRight, lessThan(scene.right));

  expect(relationship.overlaps(interaction), isFalse);
  expect(relationship.overlaps(dialogue), isFalse);
  expect(interaction.overlaps(dialogue), isFalse);
  expect(tester.takeException(), isNull);
}

void _expectV3PhoneHudOrder(WidgetTester tester) {
  final prestige = _rect(tester, 'resource_prestige');
  final phone = _rect(tester, 'phone_button_v3');
  final settings = _rect(tester, 'settings_v3');
  expect(prestige.right, lessThanOrEqualTo(phone.left));
  expect(phone.right, lessThanOrEqualTo(settings.left));
  expect(find.byKey(const ValueKey('save_status_v3')), findsNothing);
}

void _expectV3VerticalResponsiveLayout(WidgetTester tester, Size size) {
  final hud = _rect(tester, 'top_hud_v3');
  final dock = _rect(tester, 'bottom_dock_v3');
  final selector = _rect(tester, 'character_selector_region_v3');
  final scene = _rect(tester, 'scene_region_v3');
  final ryomi = _rect(tester, 'ryomi_official_art_v3');
  final interaction = _rect(tester, 'interaction_window_position_v3');
  final dialogue = _rect(tester, 'dialogue_window_position_v3');
  final relationship = _rect(tester, 'relationship_window_position_v3');

  expect(
    find.byKey(const ValueKey('ryomi_screen_v3_vertical_flow')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey('ryomi_scene_vertical_scroll_v3')),
    findsOneWidget,
  );
  expect(hud.top, closeTo(0, .1));
  expect(dock.bottom, closeTo(size.height, .1));
  expect(selector.top, closeTo(hud.bottom, .1));
  expect(selector.left, closeTo(0, .1));
  expect(selector.right, closeTo(size.width, .1));
  expect(selector.height, inInclusiveRange(70, 84));
  expect(scene.top, greaterThanOrEqualTo(selector.bottom));
  expect(scene.bottom, closeTo(dock.top, .1));

  expect(ryomi.center.dx, closeTo(scene.center.dx, 2));
  expect(ryomi.top, greaterThanOrEqualTo(scene.top - .1));
  expect(ryomi.height, greaterThan(size.width < 600 ? 220 : 280));
  expect(interaction.top, greaterThanOrEqualTo(ryomi.bottom));
  expect(dialogue.top, greaterThanOrEqualTo(interaction.bottom));
  expect(relationship.top, greaterThanOrEqualTo(dialogue.bottom));

  expect(find.byKey(const ValueKey('action_talk_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('action_interact_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('action_gift_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('action_date_v3')), findsOneWidget);
  expect(
    find.byKey(const ValueKey('top_hud_v3_resource_scroll')),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
}

void _expectV3CompactDesktopLayout(WidgetTester tester, Size size) {
  final hud = _rect(tester, 'top_hud_v3');
  final dock = _rect(tester, 'bottom_dock_v3');
  final selector = _rect(tester, 'character_selector_region_v3');
  final scene = _rect(tester, 'scene_region_v3');
  final relationship = _rect(tester, 'relationship_window_position_v3');
  final interaction = _rect(tester, 'interaction_window_position_v3');
  final dialogue = _rect(tester, 'dialogue_window_position_v3');
  final ryomi = _rect(tester, 'ryomi_official_art_v3');

  expect(
    find.byKey(const ValueKey('ryomi_screen_v3_main_row')),
    findsOneWidget,
  );
  expect(hud.height, inInclusiveRange(60, 64));
  expect(find.byKey(const ValueKey('phone_button_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('phone_badge_slot_v3')), findsOneWidget);
  _expectV3PhoneHudOrder(tester);
  expect(dock.height, inInclusiveRange(76, 84));
  expect(selector.width, inInclusiveRange(205, 220));
  expect(scene.left, closeTo(selector.right + 8, .1));

  // The persisted ROOT composition may overlap the selector seam slightly.
  expect(relationship.right, greaterThan(scene.left));
  expect(relationship.top, greaterThanOrEqualTo(scene.top));
  expect(relationship.right, lessThanOrEqualTo(scene.right));
  expect(relationship.bottom, lessThanOrEqualTo(scene.bottom));
  expect(relationship.width / scene.width, inInclusiveRange(.22, .46));
  expect(relationship.height / scene.height, inInclusiveRange(.28, .82));

  expect(interaction.right, greaterThan(scene.left));
  expect(interaction.top, greaterThanOrEqualTo(scene.top));
  expect(interaction.right, lessThanOrEqualTo(scene.right));
  expect(interaction.bottom, lessThanOrEqualTo(scene.bottom));
  expect(interaction.width / scene.width, inInclusiveRange(.22, .46));
  expect(interaction.height / scene.height, inInclusiveRange(.25, .58));

  expect(dialogue.center.dx, closeTo(scene.center.dx, 1));
  expect(dialogue.width / scene.width, inInclusiveRange(.58, .70));
  expect(dialogue.height / scene.height, inInclusiveRange(.10, .25));
  expect(
    dialogue.bottom,
    inInclusiveRange(scene.bottom - scene.height * .08, scene.bottom),
  );

  expect(
    ryomi.center.dx,
    inInclusiveRange(
      scene.left + scene.width * .20,
      scene.right - scene.width * .12,
    ),
  );
  expect(ryomi.top, lessThan(scene.bottom));
  expect(ryomi.bottom, greaterThan(scene.top));
  expect(ryomi.height / scene.height, inInclusiveRange(.45, 1.50));
  final visibleRyomiHeight = ryomi.height * ((2560 - 157) / 2600);
  expect(visibleRyomiHeight / scene.height, inInclusiveRange(.40, 1.30));
  final visibleRyomiLeft = ryomi.left + ryomi.width * (404 / 1500);
  final visibleRyomiRight = ryomi.left + ryomi.width * (1041 / 1500);
  expect(visibleRyomiLeft, greaterThan(scene.left));
  expect(visibleRyomiRight, lessThan(scene.right));

  expect(relationship.overlaps(interaction), isFalse);
  expect(relationship.overlaps(dialogue), isFalse);
  expect(interaction.overlaps(dialogue), isFalse);
  expect(find.byKey(const ValueKey('action_talk_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('action_interact_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('action_gift_v3')), findsOneWidget);
  expect(find.byKey(const ValueKey('action_date_v3')), findsOneWidget);
  for (final dockKey in [
    'dock_paixoes',
    'dock_empregos',
    'dock_hobbies',
    'dock_estatisticas',
    'dock_conquistas',
    'dock_loja',
    'dock_extras',
  ]) {
    expect(find.byKey(ValueKey(dockKey)), findsOneWidget);
  }
  expect(tester.takeException(), isNull);
}

void main() {
  test('catálogo oficial de relacionamento da Ryomi possui dez estágios', () {
    expect(RelationshipStageCatalog.totalStages, 10);
    expect(
      RelationshipStageCatalog.stages.map((stage) => stage.title).toList(),
      [
        'Desconhecida',
        'Mal-entendido',
        'Conhecida',
        'Colega',
        'Amiga',
        'Próxima',
        'Interessada',
        'Apaixonada',
        'Namorando',
        'Amor verdadeiro',
      ],
    );
    expect(IdleRules.stageName(7), 'Apaixonada');
    expect(IdleRules.stageName(8), 'Namorando');
    expect(IdleRules.stageName(9), 'Amor verdadeiro');
    for (final stage in RelationshipStageCatalog.stages) {
      expect(stage.index, inInclusiveRange(0, 9));
      expect(stage.affectionRequired, greaterThan(0));
      expect(stage.extraRequirementIds, isA<List<String>>());
      expect(stage.unlocks, isA<List<String>>());
    }
  });

  test(
    'Ryomi evolui automaticamente quando todos os requisitos são cumpridos',
    () async {
      final controller = await _controller();
      addTearDown(controller.dispose);

      expect(controller.state.characters['ryomi']!.stage, 0);

      await controller.debugAdvance('ryomi');
      var progress = controller.state.characters['ryomi']!;
      expect(progress.stage, 1);
      expect(progress.affection, 0);
      expect(IdleRules.stageName(progress.stage), 'Mal-entendido');

      await controller.debugAdvance('ryomi');
      progress = controller.state.characters['ryomi']!;
      expect(progress.stage, 2);
      expect(progress.affection, 0);
      expect(IdleRules.stageName(progress.stage), 'Conhecida');
    },
  );

  for (final size in [
    const Size(1024, 768),
    const Size(1152, 648),
    const Size(1280, 720),
    const Size(1366, 768),
    const Size(1440, 900),
    const Size(1600, 900),
    const Size(1920, 1080),
    const Size(2560, 1440),
  ]) {
    testWidgets(
      'seletor definitivo da Ryomi usa card oficial em ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final controller = await _controller();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();
        await _enterUiV3(tester);

        final selector = _rect(tester, 'character_selector_region_v3');
        if (size.width >= 1440) {
          expect(selector.width, inInclusiveRange(260, 280));
        } else if (size.width >= 1180) {
          expect(selector.width, inInclusiveRange(235, 250));
        } else {
          expect(selector.width, inInclusiveRange(205, 220));
        }

        expect(find.byType(CharacterSelectorCardV3), findsNWidgets(4));
        expect(
          find.byKey(const ValueKey('character_selector_roxanne_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('character_selector_kai_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('character_selector_sofia_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('character_selector_astra_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('character_selector_selected_tab_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('character_selector_badge_v3')),
          findsNothing,
        );
        expect(find.text('Selecionada'), findsNothing);
        expect(find.textContaining('em breve'), findsNothing);

        final card = _rect(tester, 'character_selector_roxanne_v3');
        if (size.width >= 1440) {
          expect(card.height, inInclusiveRange(98, 106));
        } else if (size.width >= 1180) {
          expect(card.height, inInclusiveRange(92, 100));
        } else {
          expect(card.height, inInclusiveRange(86, 94));
        }
        expect(card.height, lessThanOrEqualTo(106));
        expect(card.width, greaterThan(card.height));
        expect(card.width, greaterThan(card.height * 2));
        expect(card.left, greaterThanOrEqualTo(selector.left + 8));
        expect(card.right, lessThanOrEqualTo(selector.right + 14));

        final roxanneCard = find.byKey(
          const ValueKey('character_selector_roxanne_v3'),
        );
        expect(
          find.descendant(
            of: roxanneCard,
            matching: find.byKey(
              const ValueKey('character_selector_full_bleed_stack_v3'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: roxanneCard,
            matching: find.byKey(
              const ValueKey('character_selector_art_area_v3'),
            ),
          ),
          findsNothing,
        );
        final infoArea = tester.getRect(
          find
              .descendant(
                of: roxanneCard,
                matching: find.byKey(
                  const ValueKey('character_selector_info_area_v3'),
                ),
              )
              .first,
        );
        expect(infoArea.width / card.width, lessThanOrEqualTo(.49));
        expect(infoArea.right, lessThanOrEqualTo(card.right));
        expect(infoArea.right, greaterThan(card.center.dx));

        final image = tester.widget<Image>(
          find.byKey(const ValueKey('character_selector_roxanne_asset_v3')),
        );
        expect(
          (image.image as AssetImage).assetName,
          GameAssets.roxanneSelectorAsset,
        );
        expect(
          (image.image as AssetImage).assetName,
          isNot(GameAssets.roxanneSceneAsset),
        );
        expect(image.fit, BoxFit.cover);
        expect(image.alignment, Alignment.center);
        expect(image.filterQuality, FilterQuality.high);
        expect(image.isAntiAlias, isTrue);
        expect(image.gaplessPlayback, isTrue);

        final sceneImage = tester.widget<Image>(
          find.byKey(const ValueKey('ryomi_official_art_v3')),
        );
        expect(
          (sceneImage.image as AssetImage).assetName,
          GameAssets.roxanneSceneAsset,
        );
        expect(
          (sceneImage.image as AssetImage).assetName,
          isNot(GameAssets.roxanneSelectorAsset),
        );
        expect(sceneImage.fit, BoxFit.contain);
        expect(sceneImage.alignment, Alignment.bottomCenter);

        expect(
          find.descendant(
            of: roxanneCard,
            matching: find.byKey(const ValueKey('character_selector_stage_v3')),
          ),
          findsOneWidget,
        );
        final stageText = tester.widget<Text>(
          find.descendant(
            of: roxanneCard,
            matching: find.byKey(const ValueKey('character_selector_stage_v3')),
          ),
        );
        expect(stageText.data, 'Desconhecida');
        expect(stageText.overflow, isNot(TextOverflow.ellipsis));
        expect(
          find.descendant(
            of: roxanneCard,
            matching: find.byKey(
              const ValueKey('character_selector_route_bar_v3'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: roxanneCard,
            matching: find.byKey(
              const ValueKey('character_selector_route_bar_fill_v3'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: roxanneCard, matching: find.text('0%')),
          findsOneWidget,
        );

        await controller.debugAdvance('ryomi');
        await tester.pumpAndSettle();

        expect(
          find.descendant(of: roxanneCard, matching: find.text('10%')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('seletor lateral alterna Kai para a cena sem trocar assets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    Image sceneImage = tester.widget<Image>(
      find.byKey(const ValueKey('ryomi_official_art_v3')),
    );
    expect(
      (sceneImage.image as AssetImage).assetName,
      GameAssets.roxanneSceneAsset,
    );

    await controller.debugSetCharacterUnlocked(PlayableCharacterIds.kai, true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('character_selector_kai_v3')));
    await tester.pumpAndSettle();

    sceneImage = tester.widget<Image>(
      find.byKey(const ValueKey('ryomi_official_art_v3')),
    );
    expect(
      (sceneImage.image as AssetImage).assetName,
      GameAssets.kaiSceneAsset,
    );
    expect(
      (sceneImage.image as AssetImage).assetName,
      isNot(GameAssets.kaiSelectorAsset),
    );
    expect(sceneImage.fit, BoxFit.contain);
    expect(sceneImage.alignment, Alignment.bottomCenter);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dialogue_window_position_v3')),
        matching: find.text('Kai'),
      ),
      findsOneWidget,
    );

    final kaiCard = find.byKey(const ValueKey('character_selector_kai_v3'));
    final kaiSelectorImage = tester.widget<Image>(
      find.descendant(
        of: kaiCard,
        matching: find.byKey(const ValueKey('character_selector_kai_asset_v3')),
      ),
    );
    expect(
      (kaiSelectorImage.image as AssetImage).assetName,
      GameAssets.kaiSelectorAsset,
    );
    expect(kaiSelectorImage.fit, BoxFit.cover);
    expect(kaiSelectorImage.alignment, Alignment.center);
    expect(
      find.byKey(const ValueKey('character_selector_selected_tab_v3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('card do seletor da Ryomi responde a clique, Enter e Espaco', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 190,
              height: 120,
              child: CharacterSelectorCardV3(
                characterId: PlayableCharacterIds.roxanne,
                name: 'Ryomi',
                stageLabel: 'Desconhecida',
                routePercent: 0,
                selected: true,
                assetPath: GameAssets.ryomiSelectorAsset,
                onTap: () => activations++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CharacterSelectorCardV3));
    await tester.pumpAndSettle();
    expect(activations, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activations, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(activations, 3);
    expect(find.text('Selecionada'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('asset oficial do card da Ryomi esta registrado no bundle', () async {
    final bytes = await rootBundle.load(GameAssets.ryomiSelectorAsset);
    expect(bytes.lengthInBytes, greaterThan(0));
  });

  final sizes = <Size>[
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1280, 720),
    const Size(1366, 768),
    const Size(1600, 900),
    const Size(1920, 1080),
  ];

  for (final size in sizes) {
    testWidgets(
      'shell não apresenta overflow em ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final controller = await _controller();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Ryomi'), findsWidgets);
        expect(find.byKey(const ValueKey('action_talk')), findsOneWidget);
        expect(find.byKey(const ValueKey('action_interact')), findsOneWidget);
        expect(find.byKey(const ValueKey('action_gift')), findsOneWidget);
        expect(find.byKey(const ValueKey('action_date')), findsOneWidget);
        expect(find.text('Etapa 1 de 10'), findsOneWidget);
        expect(find.text('0 / 100'), findsWidgets);
        expect(find.textContaining('/ 12'), findsNothing);
        expect(
          find.byKey(const ValueKey('character_selector_ryomi')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('relationship_progress_panel')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('character_dialogue_panel')),
          findsOneWidget,
        );
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
        expect(
          find.byKey(const ValueKey('ryomi_official_art')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('ryomi_game_scene')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('ryomi_asset_fallback')),
          findsNothing,
        );
        expect(find.text('ARTE TRANSPARENTE PENDENTE'), findsNothing);
        expect(find.text('Presentes'), findsNothing);
        expect(find.text('Encontros'), findsNothing);
        expect(find.textContaining('Ã'), findsNothing);
      },
    );
  }

  for (final size in [
    const Size(1280, 720),
    const Size(1366, 768),
    const Size(1600, 900),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'Ryomi UI V3 possui estrutura desktop em ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final controller = await _controller();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();
        await _enterUiV3(tester);

        expect(find.byKey(const ValueKey('top_hud_v3')), findsOneWidget);
        expect(find.byKey(const ValueKey('bottom_dock_v3')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('character_selector_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('ryomi_scene_layout_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('relationship_window_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('interaction_window_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dialogue_window_v3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('ryomi_official_art_v3')),
          findsOneWidget,
        );
        _expectV3RegionLayout(tester, size);
      },
    );
  }

  testWidgets(
    'Ryomi UI V3 vínculo polido mostra rota, afeição e progresso natural',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      await _enterUiV3(tester);

      final window = find.byKey(const ValueKey('relationship_window_v3'));
      expect(window, findsOneWidget);
      expect(
        find.descendant(of: window, matching: find.text('Vínculo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: window, matching: find.text('Etapa 1 de 10')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_stage_identity_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_character_name_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_stage_title_v3')),
        findsOneWidget,
      );
      expect(find.text('DESCONHECIDA'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('relationship_route_percent_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_route_bar_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_affection_panel_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_affection_value_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_affection_bar_v3')),
        findsOneWidget,
      );
      for (var index = 0; index < 10; index++) {
        expect(
          find.byKey(ValueKey('relationship_checkpoint_v3_$index')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('relationship_next_stage_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relationship_auto_status_v3')),
        findsOneWidget,
      );
      expect(find.textContaining('Autoevolução'), findsNothing);
      expect(find.textContaining('Evolução automática'), findsNothing);
      expect(find.textContaining('Encontros iniciais'), findsNothing);
      expect(find.text('Próxima: Mal-entendido'), findsOneWidget);
      expect(find.text('Falta: Afeição 0 / 100'), findsOneWidget);
      expect(
        find.descendant(of: window, matching: find.textContaining('Avançar')),
        findsNothing,
      );
      final routeBar = _rect(tester, 'relationship_route_bar_v3');
      final affectionBar = _rect(tester, 'relationship_affection_bar_v3');
      expect(routeBar.height, inInclusiveRange(7, 9));
      expect(affectionBar.height, inInclusiveRange(14, 18));
      final current = _rect(tester, 'relationship_checkpoint_v3_0');
      final future = _rect(tester, 'relationship_checkpoint_v3_1');
      expect(current.width, greaterThan(future.width));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ryomi UI V3 faixa natural prioriza afeição pendente', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);
    for (var index = 0; index < 35; index++) {
      await controller.tapCharacter('ryomi');
    }

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(find.text('Falta: Afeição 35 / 100'), findsOneWidget);
    expect(find.textContaining('Autoevolução'), findsNothing);
    expect(find.textContaining('controller'), findsNothing);
    expect(find.textContaining('trigger'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ryomi UI V3 não mostra rótulos técnicos por padrão', (
    tester,
  ) async {
    UiDebugSettingsV3.labelsVisible = false;
    addTearDown(() => UiDebugSettingsV3.labelsVisible = false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(find.text('UI V3'), findsNothing);
    expect(find.text('Ryomi UI V3'), findsNothing);
    expect(find.text('Design V3'), findsNothing);
    expect(find.text('HUD V3'), findsNothing);
    expect(find.text('Vínculo V3'), findsNothing);
    expect(find.text('Ações V3'), findsNothing);
    expect(find.text('Diálogo V3'), findsNothing);
    expect(find.text('Dock V3'), findsNothing);
    expect(find.text('Seletor V3'), findsNothing);
    expect(find.byKey(const ValueKey('debug_ui_version_toggle')), findsNothing);
    expect(
      find.byKey(const ValueKey('design_system_preview_v3_button')),
      findsNothing,
    );
    expect(UiDebugSettingsV3.labelsVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modo de inspeção começa desativado e ativa manualmente', (
    tester,
  ) async {
    UiDebugSettingsV3.labelsVisible = false;
    addTearDown(() => UiDebugSettingsV3.labelsVisible = false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(UiDebugSettingsV3.labelsVisible, isFalse);
    expect(find.text('Dock V3'), findsNothing);

    await _sendDevelopmentShortcut(tester, LogicalKeyboardKey.keyI);
    await tester.pumpAndSettle();
    expect(UiDebugSettingsV3.labelsVisible, isTrue);
    expect(find.text('Dock V3'), findsOneWidget);
    expect(find.text('Seletor V3'), findsOneWidget);

    await _sendDevelopmentShortcut(tester, LogicalKeyboardKey.keyI);
    await tester.pumpAndSettle();
    expect(UiDebugSettingsV3.labelsVisible, isFalse);
    expect(find.text('Dock V3'), findsNothing);
    expect(find.text('Seletor V3'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('galeria de design continua acessível por atalho dev', (
    tester,
  ) async {
    UiDebugSettingsV3.labelsVisible = false;
    addTearDown(() => UiDebugSettingsV3.labelsVisible = false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    expect(find.text('Design V3'), findsNothing);

    await _sendDevelopmentShortcut(tester, LogicalKeyboardKey.keyD);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('design_system_preview_v3')),
      findsOneWidget,
    );
    expect(find.text('Design System V3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ryomi UI V3 HUD definitivo apresenta recursos corretos', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    final hud = find.byKey(const ValueKey('top_hud_v3'));
    expect(
      find.descendant(of: hud, matching: find.text('Conexões')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hud, matching: find.text('Dinheiro')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hud, matching: find.text('Cerejas')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hud, matching: find.text('Tempo')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hud, matching: find.text('Blocos')),
      findsNothing,
    );
    expect(
      find.descendant(of: hud, matching: find.text('Diamantes')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('money_note_icon_v3')), findsOneWidget);
    expect(find.byKey(const ValueKey('cherries_icon_v3')), findsOneWidget);
    expect(
      find.descendant(of: hud, matching: find.byIcon(Icons.diamond_rounded)),
      findsNothing,
    );
    expect(
      find.descendant(of: hud, matching: find.text('6 / 6')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hud, matching: find.text('x1.0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hud, matching: find.text('+0%')),
      findsOneWidget,
    );
    expect(find.text('Salvando'), findsNothing);
    expect(find.byKey(const ValueKey('save_status_v3')), findsNothing);
    expect(find.byKey(const ValueKey('phone_button_v3')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_v3')), findsOneWidget);
    _expectV3PhoneHudOrder(tester);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(1024, 768),
    const Size(1152, 648),
    const Size(1280, 720),
    const Size(1366, 768),
    const Size(1600, 900),
    const Size(1920, 1080),
  ]) {
    testWidgets('Ryomi UI V3 HUD definitivo permanece em linha em '
        '${size.width}x${size.height}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      await _enterUiV3(tester);

      final hud = _rect(tester, 'top_hud_v3');
      final ids = [
        'game_identity_v3',
        'resource_money',
        'resource_cherries',
        'resource_time_blocks',
        'resource_speed',
        'resource_prestige',
        'phone_button_v3',
        'settings_v3',
      ];
      final rects = {for (final id in ids) id: _rect(tester, id)};
      for (final rect in rects.values) {
        expect(hud.contains(rect.topLeft), isTrue);
        expect(hud.contains(rect.bottomRight), isTrue);
      }
      expect(
        rects['game_identity_v3']!.right,
        lessThan(rects['resource_money']!.left),
      );
      expect(
        rects['resource_money']!.right,
        lessThan(rects['resource_cherries']!.left),
      );
      expect(
        rects['resource_cherries']!.right,
        lessThan(rects['resource_time_blocks']!.left),
      );
      expect(
        rects['resource_time_blocks']!.right,
        lessThan(rects['resource_speed']!.left),
      );
      expect(
        rects['resource_speed']!.right,
        lessThan(rects['resource_prestige']!.left),
      );
      expect(
        rects['phone_button_v3']!.right,
        lessThanOrEqualTo(rects['settings_v3']!.left),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Ryomi UI V3 indicador de salvamento é transitório', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final state = (await _controller()).state;
    Future<void> pumpHud({
      required SaveIndicatorPhase phase,
      required int sequence,
      String? message,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopHudV3(
              state: state,
              spec: RyomiLayoutSpec.fromSize(const Size(1280, 720)),
              onSettings: () {},
              savePhase: phase,
              saveSequence: sequence,
              saveError: message,
            ),
          ),
        ),
      );
    }

    await pumpHud(phase: SaveIndicatorPhase.idle, sequence: 0);
    await tester.pumpAndSettle();
    expect(find.text('Salvando…'), findsNothing);
    expect(find.text('Salvo'), findsNothing);

    await pumpHud(phase: SaveIndicatorPhase.saving, sequence: 1);
    await tester.pump();
    expect(find.text('Salvando…'), findsOneWidget);

    await pumpHud(phase: SaveIndicatorPhase.saved, sequence: 2);
    await tester.pump();
    expect(find.text('Salvo'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Salvo'), findsNothing);

    await pumpHud(
      phase: SaveIndicatorPhase.error,
      sequence: 3,
      message: 'Falha ao salvar progresso.',
    );
    await tester.pump();
    expect(find.text('Falha ao salvar'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4100));
    expect(find.text('Falha ao salvar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('presentes e encontros abrem modais próprios', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 768);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byKey(const ValueKey('action_gift')));
    await tester.pumpAndSettle();
    expect(find.textContaining('PRESENTEAR ROXANNE'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm_gift')), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('action_date')));
    await tester.pumpAndSettle();
    expect(find.text('Escolher encontro'), findsOneWidget);
    expect(find.textContaining('Roxanne: 0 realizados'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tela da Ryomi usa quatro regiões horizontais no desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ryomi_relationship_desktop_layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('character_selector_region')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('character_selector_ryomi')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('relationship_progress_region')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('relationship_progress_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('relationship_affection_bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('character_presentation_region')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('character_controls_area')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('interaction_controls_region')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('character_dialogue_region')),
      findsOneWidget,
    );

    final selector = _rect(tester, 'character_selector_region');
    final progress = _rect(tester, 'relationship_progress_region');
    final character = _rect(tester, 'character_presentation_region');
    final controls = _rect(tester, 'character_controls_area');
    _expectDesktopRyomiRegions(tester);
    expect(selector.width, inInclusiveRange(168, 172));
    expect(progress.width, inInclusiveRange(303, 307));
    expect(character.width, greaterThan(460));
    expect(controls.width, inInclusiveRange(303, 307));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(1280, 720), const Size(1600, 900)]) {
    testWidgets('posições relativas da Ryomi em ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();

      _expectDesktopRyomiRegions(tester);
      _expectNoActionOverlap(tester);
      _expectSameActionHeight(tester);
      _expectBadgesInsideButtons(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(900, 700),
    const Size(768, 1024),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets(
      'Ryomi UI V3 reorganiza responsivamente em ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final controller = await _controller();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();
        await _enterUiV3(tester);

        _expectV3VerticalResponsiveLayout(tester, size);
      },
    );
  }

  for (final size in [
    const Size(1024, 768),
    const Size(1152, 648),
    const Size(1024, 600),
  ]) {
    testWidgets('Ryomi UI V3 usa PC compacto em ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      await _enterUiV3(tester);

      _expectV3CompactDesktopLayout(tester, size);
    });
  }

  testWidgets('Ryomi UI V3 abre overlay provisório do celular pelo HUD', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    final before = controller.state.characters['ryomi']!;
    final beforeMoney = controller.state.money;
    final beforeDiamonds = controller.state.diamonds;

    expect(find.byKey(const ValueKey('phone_button_v3')), findsOneWidget);
    _expectV3PhoneHudOrder(tester);
    await tester.tap(find.byKey(const ValueKey('phone_button_v3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('phone_overlay_v3')), findsOneWidget);
    expect(find.text('Celular'), findsOneWidget);
    expect(
      find.text('Sistema de mensagens em desenvolvimento'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ryomi_ui_v3_shell')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('phone_overlay_close_v3')));
    await tester.pumpAndSettle();

    final after = controller.state.characters['ryomi']!;
    expect(find.byKey(const ValueKey('phone_overlay_v3')), findsNothing);
    expect(find.byKey(const ValueKey('ryomi_ui_v3_shell')), findsOneWidget);
    expect(after.affection, before.affection);
    expect(after.stage, before.stage);
    expect(controller.state.money, beforeMoney);
    expect(controller.state.diamonds, beforeDiamonds);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ryomi UI V3 DEV aparece somente após login ROOT em Extras', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(find.byKey(const ValueKey('dock_dev')), findsNothing);
    expect(find.byKey(const ValueKey('dev_tools_view')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dock_extras')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin_access_card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin_open_login')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin_login_panel')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('admin_username_field')),
      'Guilherme.Felipi',
    );
    await tester.enterText(
      find.byKey(const ValueKey('admin_password_field')),
      String.fromCharCodes([80, 101, 113, 117, 101, 110, 97, 51, 50, 64]),
    );
    await tester.tap(find.byKey(const ValueKey('admin_submit_login')));
    await tester.pumpAndSettle();
    expect(find.text('Usuário ou senha incorretos.'), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_dev')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('admin_username_field')),
      'guilherme.felipi',
    );
    await tester.enterText(
      find.byKey(const ValueKey('admin_password_field')),
      String.fromCharCodes([80, 101, 113, 117, 101, 110, 97, 51, 50, 64]),
    );
    await tester.tap(find.byKey(const ValueKey('admin_submit_login')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('admin_authenticated_card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dock_dev')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dock_dev')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dock_dev_selected')), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_tools_view')), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_tools_title')), findsOneWidget);

    final before = controller.state.characters['ryomi']!.affection;
    await tester.tap(find.text('Clique direto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simular 1 clique'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(controller.state.characters['ryomi']!.affection, before + 1);

    await tester.tap(find.text('SAIR DO MODO ADMIN'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dock_dev')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caixa de diálogo pode minimizar e reabrir', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('character_dialogue_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('character_dialogue_panel_content')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('character_dialogue_minimize')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('character_dialogue_panel_content')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('character_dialogue_restore')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('character_dialogue_restore')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('character_dialogue_panel_content')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('painel de progresso mostra dez checkpoints e rota válida', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    for (var index = 0; index < 10; index++) {
      expect(
        find.byKey(ValueKey('relationship_checkpoint_$index')),
        findsOneWidget,
      );
    }
    expect(find.text('Etapa 1 de 10'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('relationship_stage_title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('relationship_next_stage')),
      findsOneWidget,
    );
    expect(find.textContaining('MAL-ENTENDIDO'), findsOneWidget);
    final percentText = tester
        .widget<Text>(find.byKey(const ValueKey('relationship_route_percent')))
        .data!;
    final percent = int.parse(percentText.replaceAll('%', ''));
    expect(percent, inInclusiveRange(0, 100));
    expect(find.text('Presentes 0 / 0'), findsNothing);
    expect(find.text('Encontros 0 / 0'), findsNothing);

    final current = _rect(tester, 'relationship_checkpoint_0');
    final future = _rect(tester, 'relationship_checkpoint_1');
    expect(current.width, greaterThan(future.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ações da Ryomi usam grid 2x2 na região direita desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('interaction_grid_v2')), findsOneWidget);
    _expectNoActionOverlap(tester);
    _expectSameActionHeight(tester);
    _expectBadgesInsideButtons(tester);

    expect(find.text('CONVERSAR'), findsOneWidget);
    expect(find.text('INTERAGIR'), findsOneWidget);
    expect(find.text('PRESENTEAR'), findsOneWidget);
    expect(find.text('ENCONTRO'), findsOneWidget);
    _expectActionGrid2x2(tester);
    _expectDesktopRyomiRegions(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ações da Ryomi usam grid 2x2 em largura mobile', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    _expectNoActionOverlap(tester);
    _expectSameActionHeight(tester);
    _expectBadgesInsideButtons(tester);

    _expectActionGrid2x2(tester);
    final talk = _rect(tester, 'action_talk');
    expect(
      tester.getRect(find.byKey(const ValueKey('ryomi_official_art'))).bottom,
      lessThanOrEqualTo(talk.top),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('ações da Ryomi ficam estáveis em 1280x720', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    _expectNoActionOverlap(tester);
    _expectSameActionHeight(tester);
    _expectBadgesInsideButtons(tester);
    _expectActionGrid2x2(tester);
    _expectDesktopRyomiRegions(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Presentear e Encontro têm hitboxes e cliques independentes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    _expectNoActionOverlap(tester);

    await tester.tapAt(_rect(tester, 'action_gift').center);
    await tester.pumpAndSettle();
    expect(find.textContaining('PRESENTEAR ROXANNE'), findsOneWidget);
    expect(find.text('Escolher encontro'), findsNothing);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    await tester.tapAt(_rect(tester, 'action_date').center);
    await tester.pumpAndSettle();
    expect(find.text('Escolher encontro'), findsOneWidget);
    expect(find.textContaining('PRESENTEAR ROXANNE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empregos e Hobbies são destinos separados', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byKey(const ValueKey('dock_empregos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jobs_grid')), findsOneWidget);
    expect(find.text('Nv. 1'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('dock_hobbies')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hobbies_grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empregos reservam Tempo e usam feedback contextual na aba', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);
    await tester.tap(find.byKey(const ValueKey('dock_empregos')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('jobs_grid')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('job_card_neighborhood_deliveries')),
      findsOneWidget,
    );
    expect(find.text('ENTREGAS DE BAIRRO'), findsOneWidget);
    expect(find.text('Nv. 1'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('job_card_neighborhood_deliveries')),
    );
    await tester.tap(
      find.byKey(const ValueKey('job_card_neighborhood_deliveries')),
    );
    await tester.pumpAndSettle();

    expect(controller.state.jobs['neighborhood_deliveries']!.active, isTrue);
    expect(controller.state.availableBlocks, 4);
    expect(find.text('EM ANDAMENTO'), findsNothing);
    expect(find.text('Tempo livre'), findsNothing);
    expect(
      find.byKey(const ValueKey('gameplay_feedback_overlay_v3')),
      findsNothing,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Impulso de Emprego confirma no card antes de gastar Cerejas', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await controller.debugSetResources(diamonds: 10);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);
    await tester.tap(find.byKey(const ValueKey('dock_empregos')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('job_card_neighborhood_deliveries')),
    );
    await tester.tap(
      find.byKey(const ValueKey('job_card_neighborhood_deliveries')),
    );
    await tester.pumpAndSettle();

    final before = controller.state.diamonds;
    await tester.tap(find.byIcon(Icons.local_florist_rounded).first);
    await tester.pumpAndSettle();

    expect(controller.state.diamonds, before);
    expect(find.text('APRIMORAR ENTREGAS DE BAIRRO?'), findsOneWidget);

    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    expect(find.text('APRIMORAR ENTREGAS DE BAIRRO?'), findsNothing);

    await tester.tap(find.byIcon(Icons.local_florist_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('APRIMORAR'));
    await tester.pumpAndSettle();

    expect(controller.state.diamonds, before - IdleBalance.jobBoostCherryCost);
    expect(controller.state.jobs['neighborhood_deliveries']!.upgraded, isTrue);
    expect(find.text('Impulsos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Estatísticas é aba independente entre Hobbies e Conquistas', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    final hobbies = _rect(tester, 'dock_hobbies');
    final statistics = _rect(tester, 'dock_estatisticas');
    final achievements = _rect(tester, 'dock_conquistas');
    expect(hobbies.right, lessThanOrEqualTo(statistics.left + 1));
    expect(statistics.right, lessThanOrEqualTo(achievements.left + 1));

    await tester.tap(find.byKey(const ValueKey('dock_estatisticas')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dock_estatisticas_selected')),
      findsOneWidget,
    );
    expect(find.text('Estatísticas'), findsWidgets);
    expect(find.text('Progresso da Roxanne'), findsOneWidget);
    expect(find.text('Afeição atual'), findsOneWidget);
    expect(
      find.textContaining('serão registrados em uma etapa futura'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loja e Extras usam linguagem visual colecionável', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byKey(const ValueKey('dock_loja')));
    await tester.pumpAndSettle();
    expect(find.text('Loja'), findsWidgets);
    expect(find.text('Presentes'), findsOneWidget);
    expect(find.text('Melhorias'), findsOneWidget);
    expect(find.text('Blocos'), findsOneWidget);
    expect(find.text('Cosméticos futuros'), findsOneWidget);
    expect(find.text('Escolher presente'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dock_extras')));
    await tester.pumpAndSettle();
    expect(find.text('Extras'), findsWidgets);
    expect(find.text('Mais'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modal compacto usa bottom sheet', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    showGiftSelectionDialog(
      tester.element(find.byType(IdleDatingGameShell)),
      controller,
      onDelivered: (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('PRESENTEAR ROXANNE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requisitos ficam recolhidos e expandem sob demanda', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    expect(find.textContaining('Música nível'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('requirements_toggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Música nível'), findsOneWidget);
    expect(find.text('Presentes 0 / 0'), findsNothing);
    expect(find.text('Encontros 0 / 0'), findsNothing);
  });

  testWidgets('feedback e cooldown aparecem ao conversar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byKey(const ValueKey('action_talk')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(FloatingRewardText), findsOneWidget);
    expect(find.byKey(const ValueKey('action_talk_cooldown')), findsOneWidget);
    expect(find.textContaining('restantes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('tapCharacter concede afeição sem cooldown nem timestamps', () async {
    final controller = await _controller();
    addTearDown(controller.dispose);
    final before = controller.state.characters['ryomi']!;

    final result = await controller.tapCharacter('ryomi');
    final afterOne = controller.state.characters['ryomi']!;

    expect(result.message, contains('+1'));
    expect(afterOne.affection, before.affection + 1);
    expect(afterOne.lifetimeAffection, before.lifetimeAffection + 1);
    expect(afterOne.lastInteractAt, before.lastInteractAt);
    expect(afterOne.lastTalkAt, before.lastTalkAt);

    for (var i = 0; i < 9; i++) {
      await controller.tapCharacter('ryomi');
    }
    final afterTen = controller.state.characters['ryomi']!;
    expect(afterTen.affection, before.affection + 10);
    expect(afterTen.lastInteractAt, before.lastInteractAt);
    expect(afterTen.lastTalkAt, before.lastTalkAt);
  });

  testWidgets('clique direto na Ryomi é clicker sem SnackBar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    final before = controller.state.characters['ryomi']!;
    await tester.tap(find.byKey(const ValueKey('ryomi_character_tap_area')));
    await tester.pump(const Duration(milliseconds: 120));

    final after = controller.state.characters['ryomi']!;
    expect(after.affection, before.affection + 1);
    expect(after.lastInteractAt, before.lastInteractAt);
    expect(after.lastTalkAt, before.lastTalkAt);
    expect(find.byType(FloatingRewardText), findsOneWidget);
    expect(find.text('♥ +1'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('relationship_affection_value')),
          )
          .data,
      '1 / 100',
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('cliques rápidos na Ryomi não são descartados e agrupam efeito', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byKey(const ValueKey('ryomi_character_tap_area')));
    }
    await tester.pump(const Duration(milliseconds: 180));

    final progress = controller.state.characters['ryomi']!;
    expect(progress.affection, 10);
    expect(progress.lastInteractAt, 0);
    expect(progress.lastTalkAt, 0);
    expect(find.textContaining('+10'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('clique direto funciona durante cooldown de ações', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('action_interact')));
    await tester.pump(const Duration(milliseconds: 120));
    final afterInteract = controller.state.characters['ryomi']!;
    expect(
      find.byKey(const ValueKey('action_interact_cooldown')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('ryomi_character_tap_area')));
    await tester.pump(const Duration(milliseconds: 120));
    final afterTapDuringInteract = controller.state.characters['ryomi']!;
    expect(afterTapDuringInteract.affection, afterInteract.affection + 1);
    expect(afterTapDuringInteract.lastInteractAt, afterInteract.lastInteractAt);

    await tester.tap(find.byKey(const ValueKey('action_talk')));
    await tester.pump(const Duration(milliseconds: 120));
    final afterTalk = controller.state.characters['ryomi']!;
    expect(find.byKey(const ValueKey('action_talk_cooldown')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ryomi_character_tap_area')));
    await tester.pump(const Duration(milliseconds: 120));
    final afterTapDuringTalk = controller.state.characters['ryomi']!;
    expect(afterTapDuringTalk.affection, afterTalk.affection + 1);
    expect(afterTapDuringTalk.lastTalkAt, afterTalk.lastTalkAt);

    await tester.tap(find.byKey(const ValueKey('action_interact')));
    await tester.pump(const Duration(milliseconds: 120));
    final afterBlockedInteract = controller.state.characters['ryomi']!;
    expect(afterBlockedInteract.affection, afterTapDuringTalk.affection);
    expect(find.textContaining('restantes'), findsWidgets);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets(
    'Ryomi UI V3 clique primário na personagem concede +1 e feedback',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      await _enterUiV3(tester);

      expect(IdleBalance.directCharacterClickAffection, 1);
      final before = controller.state.characters['ryomi']!;
      final hitbox = _rect(tester, 'ryomi_character_clickable_v3');
      await tester.tapAt(hitbox.center);
      await tester.pump(const Duration(milliseconds: 80));

      final after = controller.state.characters['ryomi']!;
      expect(after.affection, before.affection + 1);
      expect(after.lastTalkAt, before.lastTalkAt);
      expect(after.lastInteractAt, before.lastInteractAt);
      expect(
        find.byKey(const ValueKey('ryomi_affection_feedback_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('gameplay_feedback_overlay_v3')),
        findsNothing,
      );
      expect(find.textContaining('afeição passiva'), findsNothing);
      expect(find.text('♥ +1'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('relationship_affection_value_v3')),
            )
            .data,
        '1 / 100',
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 900));
    },
  );

  testWidgets('Ryomi UI V3 vazio e botão secundário não concedem afeição', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    final area = _rect(tester, 'ryomi_character_area_v3');
    final hitbox = _rect(tester, 'ryomi_character_clickable_v3');
    final emptyPoint = Offset(area.left + 4, hitbox.center.dy);
    expect(hitbox.contains(emptyPoint), isFalse);
    await tester.tapAt(emptyPoint);
    await tester.pump(const Duration(milliseconds: 80));
    expect(controller.state.characters['ryomi']!.affection, 0);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.addPointer(location: hitbox.center);
    await tester.pump();
    await gesture.down(hitbox.center);
    await tester.pump();
    await gesture.up();
    await gesture.removePointer();
    await tester.pump(const Duration(milliseconds: 80));

    expect(controller.state.characters['ryomi']!.affection, 0);
    expect(
      find.byKey(const ValueKey('ryomi_affection_feedback_v3')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  test('afeição automática começa na etapa 3 e calcula progresso fechado', () {
    final service = SimulationService();
    final now = DateTime(2026, 1, 1, 12);
    final lastSavedAt = now
        .subtract(const Duration(seconds: 3))
        .millisecondsSinceEpoch;
    final beforeUnlock = IdleState.fresh().copyWith(
      lastSavedAt: lastSavedAt,
      characters: {'ryomi': const CharacterProgress(unlocked: true, stage: 1)},
    );
    final unlocked = IdleState.fresh().copyWith(
      lastSavedAt: lastSavedAt,
      characters: {
        'ryomi': CharacterProgress(
          unlocked: true,
          stage: IdleBalance.passiveAffectionUnlockStage,
        ),
      },
    );

    final blockedResult = service.advance(beforeUnlock, now, offline: true);
    expect(blockedResult.state.characters['ryomi']!.affection, 0);
    expect(blockedResult.summary.affection, 0);

    final unlockedResult = service.advance(unlocked, now, offline: true);
    expect(unlockedResult.state.characters['ryomi']!.affection, 3);
    expect(unlockedResult.state.characters['ryomi']!.lifetimeAffection, 3);
    expect(unlockedResult.summary.affection, 3);
    expect(unlockedResult.summary.hasChanges, isTrue);
  });

  test('clique direto solicita salvamento com debounce', () async {
    final storage = _CountingStorage();
    final controller = GameController(storage);
    await controller.initialize();
    addTearDown(controller.dispose);
    final writesAfterInitialize = storage.writes;

    await controller.tapCharacter('ryomi');
    await controller.tapCharacter('ryomi');
    await controller.tapCharacter('ryomi');

    expect(storage.writes, writesAfterInitialize);
    expect(controller.state.characters['ryomi']!.affection, 3);

    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(storage.writes, writesAfterInitialize + 1);
    final saved = IdleState.decode(storage.value!);
    expect(saved.characters['ryomi']!.affection, 3);
  });

  testWidgets('arte oficial da Ryomi é usada com proporção preservada', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('ryomi_official_art')),
    );
    expect((image.image as AssetImage).assetName, GameAssets.ryomiSceneAsset);
    expect(
      (image.image as AssetImage).assetName,
      isNot(GameAssets.ryomiSelectorAsset),
    );
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.bottomCenter);
    expect(image.filterQuality, FilterQuality.high);
    expect(image.isAntiAlias, isTrue);
    expect(image.gaplessPlayback, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('asset oficial da Ryomi está registrado no bundle', () async {
    final bytes = await rootBundle.load(GameAssets.ryomiSceneAsset);
    expect(bytes.lengthInBytes, greaterThan(0));
  });

  test('paleta global oficial está centralizada', () {
    expect(GameColors.ivory, const Color(0xFFF5F1E8));
    expect(GameColors.sand, const Color(0xFFEAE2D5));
    expect(GameColors.oat, const Color(0xFFFFFDF7));
    expect(GameColors.rosyBeige, const Color(0xFFF3E8DF));
    expect(GameColors.outline, const Color(0xFF685D58));
    expect(GameColors.outlineSoft, const Color(0xFFB8AAA4));
    expect(GameColors.ink, const Color(0xFF39323B));
    expect(GameColors.softInk, const Color(0xFF786F70));
    expect(GameColors.relation, const Color(0xFFD87468));
    expect(GameColors.jobs, const Color(0xFF6FA17C));
    expect(GameColors.hobbies, const Color(0xFF628FA3));
    expect(GameColors.achievements, const Color(0xFF806987));
    expect(GameColors.shop, const Color(0xFFD6A13A));
    expect(GameColors.more, const Color(0xFFA85E68));
    expect(GameColors.background.computeLuminance(), greaterThan(.78));
  });

  test('tema global claro e tema de personagem ficam separados', () {
    final theme = AppTheme.dark();
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, GameColors.paper);
    expect(GameVisualTheme.current.brandAccent, GameColors.more);
    expect(RyomiVisualTheme.data.id, 'roxanne');
    expect(RyomiVisualTheme.data.sceneAccent, isNot(GameColors.relation));
  });

  testWidgets('HUD e menu inferior usam componentes personalizados', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('connections_hud_v2')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('connections_bottom_menu_v2')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.byKey(const ValueKey('connections_bottom_menu_v2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('resource_money')), findsOneWidget);
    expect(find.byKey(const ValueKey('resource_diamonds')), findsOneWidget);
    expect(find.byKey(const ValueKey('resource_time_blocks')), findsOneWidget);
    expect(find.byKey(const ValueKey('resource_speed')), findsOneWidget);
    expect(find.byKey(const ValueKey('resource_prestige')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock_paixoes_selected')), findsOneWidget);
    for (final label in [
      'Paixões',
      'Empregos',
      'Hobbies',
      'Estatísticas',
      'Conquistas',
      'Loja',
      'Extras',
    ]) {
      expect(find.text(label.toUpperCase()), findsWidgets);
    }
    final dock = _rect(tester, 'connections_bottom_menu_v2');
    for (final id in [
      'dock_paixoes',
      'dock_empregos',
      'dock_hobbies',
      'dock_estatisticas',
      'dock_conquistas',
      'dock_loja',
      'dock_extras',
    ]) {
      final button = _rect(tester, id);
      expect(button.width, greaterThan(120));
      expect(button.height, greaterThan(70));
      expect(dock.contains(button.topLeft), isTrue);
      expect(dock.contains(button.bottomRight), isTrue);
    }

    final money = _rect(tester, 'resource_money');
    expect(money.height, greaterThanOrEqualTo(40));
    expect(money.width, greaterThan(70));

    await tester.tap(find.byKey(const ValueKey('dock_empregos')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dock_empregos_selected')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dock_paixoes_selected')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ryomi UI V3 vínculo minimiza, reabre e expande objetivos', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(
      find.byKey(const ValueKey('relationship_window_v3')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('relationship_minimize_v3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('relationship_window_v3')), findsNothing);
    expect(
      find.byKey(const ValueKey('relationship_window_minimized_v3')),
      findsOneWidget,
    );
    expect(find.textContaining('0%'), findsWidgets);

    tester.view.physicalSize = const Size(1600, 900);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('relationship_window_minimized_v3')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('relationship_window_minimized_v3')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('relationship_window_v3')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey('relationship_objectives_panel_v3')),
      findsNothing,
    );
    final collapsedRelationship = _rect(
      tester,
      'relationship_window_position_v3',
    );
    await tester.tap(
      find.byKey(const ValueKey('relationship_objectives_toggle_v3')),
    );
    await tester.pumpAndSettle();
    final expandedRelationship = _rect(
      tester,
      'relationship_window_position_v3',
    );
    expect(
      find.byKey(const ValueKey('relationship_objectives_panel_v3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('relationship_objective_item_v3_0')),
      findsOneWidget,
    );
    expect(find.textContaining('0 / 0'), findsNothing);
    expect(find.text('Presentes 0 / 0'), findsNothing);
    expect(find.text('Encontros 0 / 0'), findsNothing);
    final objectivesHeight = _rect(tester, 'relationship_objectives_height_v3');
    expect(objectivesHeight.height, lessThanOrEqualTo(100));
    expect(
      expandedRelationship.height,
      greaterThanOrEqualTo(collapsedRelationship.height),
    );
    expect(
      expandedRelationship.height - collapsedRelationship.height,
      lessThanOrEqualTo(70),
    );

    await tester.tap(
      find.byKey(const ValueKey('relationship_objectives_toggle_v3')),
    );
    await tester.pumpAndSettle();
    final recollapsedRelationship = _rect(
      tester,
      'relationship_window_position_v3',
    );
    expect(
      find.byKey(const ValueKey('relationship_objectives_panel_v3')),
      findsNothing,
    );
    expect(
      recollapsedRelationship.height,
      lessThanOrEqualTo(expandedRelationship.height),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ryomi UI V3 ações minimizam, reabrem e preservam callbacks', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(find.byKey(const ValueKey('interaction_window_v3')), findsOneWidget);
    for (final key in [
      'action_talk_v3',
      'action_interact_v3',
      'action_gift_v3',
      'action_date_v3',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('interaction_minimize_v3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('interaction_window_v3')), findsNothing);
    expect(
      find.byKey(const ValueKey('interaction_window_minimized_v3')),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1152, 648);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('interaction_window_minimized_v3')),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1280, 720);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('interaction_window_minimized_v3')),
    );
    await tester.pumpAndSettle();
    final before = controller.state.characters['ryomi']!.affection;
    await tester.tap(find.byKey(const ValueKey('action_talk_v3')));
    await tester.pumpAndSettle();
    expect(
      controller.state.characters['ryomi']!.affection,
      greaterThan(before),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ryomi UI V3 ações definitivas exibem recompensa e estado real', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(find.byKey(const ValueKey('interaction_window_v3')), findsOneWidget);
    expect(find.text('Ações V3'), findsNothing);
    expect(IdleBalance.talkCooldown, const Duration(seconds: 5));
    expect(IdleBalance.interactCooldown, const Duration(minutes: 1));
    expect(IdleBalance.talkAffectionReward, 5);
    expect(IdleBalance.interactAffectionReward, 15);
    for (final key in [
      'action_talk_v3',
      'action_interact_v3',
      'action_gift_v3',
      'action_date_v3',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
      expect(find.byKey(ValueKey('${key}_status')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('action_talk_v3_reward')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('action_interact_v3_reward')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('action_gift_v3_reward')), findsNothing);
    expect(find.byKey(const ValueKey('action_date_v3_reward')), findsNothing);

    expect(find.text('Conversar'), findsOneWidget);
    expect(find.text('Interagir'), findsOneWidget);
    expect(find.text('Presentear'), findsOneWidget);
    expect(find.text('Encontro'), findsOneWidget);
    expect(find.text('+5 afeição'), findsOneWidget);
    expect(find.text('+15 afeição'), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Locais'), findsOneWidget);
    expect(find.textContaining('restantes'), findsNothing);
    expect(find.text('Varia por presente'), findsNothing);
    expect(find.text('Varia por encontro'), findsNothing);
    expect(find.text('Escolher presente'), findsNothing);
    expect(find.text('Cooldown'), findsNothing);
    expect(find.text('Rápida'), findsNothing);
    expect(find.text('Novo'), findsNothing);
    expect(find.text('Cena'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ryomi UI V3 conversar e interagir aplicam cooldowns separados', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    final before = controller.state.characters['ryomi']!;
    await tester.tap(find.byKey(const ValueKey('action_interact_v3')));
    await tester.pump(const Duration(milliseconds: 120));
    final afterInteract = controller.state.characters['ryomi']!;
    expect(
      afterInteract.affection,
      before.affection + IdleBalance.interactAffectionReward,
    );
    expect(afterInteract.lastTalkAt, before.lastTalkAt);
    expect(afterInteract.lastInteractAt, greaterThan(0));
    expect(
      find.byKey(const ValueKey('action_interact_v3_cooldown_v3')),
      findsOneWidget,
    );
    expect(find.text('01:00'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('action_talk_v3_cooldown_v3')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('action_talk_v3')));
    await tester.pump(const Duration(milliseconds: 120));
    final afterTalk = controller.state.characters['ryomi']!;
    expect(
      afterTalk.affection,
      afterInteract.affection + IdleBalance.talkAffectionReward,
    );
    expect(afterTalk.lastTalkAt, greaterThan(0));
    expect(afterTalk.lastInteractAt, afterInteract.lastInteractAt);
    expect(
      find.byKey(const ValueKey('action_talk_v3_cooldown_v3')),
      findsOneWidget,
    );
    expect(find.text('00:05'), findsOneWidget);
    expect(find.textContaining('restantes'), findsNothing);
    expect(find.text('+5 afeição'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Ryomi UI V3 presentear abre catálogo e encontro usa bloqueios reais',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      await _enterUiV3(tester);

      await tester.tap(find.byKey(const ValueKey('action_gift_v3')));
      await tester.pumpAndSettle();
      expect(find.textContaining('PRESENTEAR ROXANNE'), findsOneWidget);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      await controller.debugMoney(100);
      await tester.pumpAndSettle();
      expect(find.text('Catálogo'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('action_gift_v3')));
      await tester.pumpAndSettle();
      expect(find.textContaining('PRESENTEAR ROXANNE'), findsOneWidget);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('Locais'), findsOneWidget);
      expect(find.text('Varia por encontro'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('action_date_v3')));
      await tester.pumpAndSettle();
      expect(find.text('Escolher encontro'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  test('fila de diálogo V3 respeita prioridade e evita duplicatas', () {
    final initial = DialogueMessage.create(
      id: 'initial',
      characterId: 'ryomi',
      speakerName: 'Ryomi',
      text: 'Inicial',
      context: DialogueContext.idle,
      canRepeat: false,
    );
    final queue = DialogueQueueV3(initialMessage: initial);
    final normal = DialogueMessage.create(
      id: 'normal',
      characterId: 'ryomi',
      speakerName: 'Ryomi',
      text: 'Normal',
      context: DialogueContext.talk,
      canRepeat: false,
    );
    final important = DialogueMessage.create(
      id: 'important',
      characterId: 'ryomi',
      speakerName: 'Ryomi',
      text: 'Importante',
      context: DialogueContext.relationshipAdvance,
      priority: DialoguePriority.important,
      canRepeat: false,
    );

    queue
      ..enqueue(normal)
      ..enqueue(normal)
      ..enqueue(important);

    expect(queue.queuedCount, 2);
    expect(queue.current.id, 'initial');
    expect(queue.advance(), isTrue);
    expect(queue.current.id, 'important');
    expect(queue.advance(), isTrue);
    expect(queue.current.id, 'normal');
    expect(queue.advance(), isFalse);
  });

  test('controlador V3 enfileira fala de evolução depois da ação', () {
    final windows = RyomiWindowsControllerV3();
    addTearDown(windows.dispose);

    windows.showTalkDialogue(
      characterId: PlayableCharacterIds.roxanne,
      relationshipStage: 0,
    );
    windows.enqueueRelationshipAdvance(1);

    expect(windows.currentDialogueMessage.context, DialogueContext.talk);
    expect(windows.queuedDialogueCount, 1);

    windows.advanceDialogue();

    expect(
      windows.currentDialogueMessage.context,
      DialogueContext.relationshipAdvance,
    );
    expect(windows.currentDialogue, isNotEmpty);
  });

  testWidgets('Ryomi UI V3 diálogo minimiza, reabre e atualiza fala', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    expect(find.byKey(const ValueKey('dialogue_window_v3')), findsOneWidget);
    expect(find.text('Diálogo V3'), findsNothing);
    expect(
      find.text('Estrutura provisória da caixa de diálogo.'),
      findsNothing,
    );
    expect(find.text('Roxanne'), findsWidgets);
    expect(
      find.byKey(const ValueKey('dialogue_context_badge_v3')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dialogue_coral_detail_v3')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dialogue_advance_v3')), findsOneWidget);
    final initialLine = tester
        .widget<Text>(find.byKey(const ValueKey('dialogue_text_v3')))
        .data;

    await tester.tap(find.byKey(const ValueKey('dialogue_minimize_v3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dialogue_window_v3')), findsNothing);
    expect(
      find.byKey(const ValueKey('dialogue_window_minimized_v3')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('action_talk_v3')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dialogue_window_minimized_v3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dialogue_unread_badge_v3')),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1600, 900);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dialogue_window_minimized_v3')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('dialogue_window_minimized_v3')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dialogue_window_v3')), findsOneWidget);
    final updatedLine = tester
        .widget<Text>(find.byKey(const ValueKey('dialogue_text_v3')))
        .data;
    expect(updatedLine, isNot(initialLine));
    expect(
      find.byKey(const ValueKey('dialogue_unread_badge_v3')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'CharacterDialogueWindowV3 usa fala natural quando texto vem vazio',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 640,
                height: 130,
                child: CharacterDialogueWindowV3(
                  speakerName: 'Ryomi',
                  text: '',
                  queuedCount: 1,
                  minimized: false,
                  hasUnread: true,
                  onAdvance: () {},
                  onCompleteText: () {},
                  onMinimize: () {},
                  onRestore: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byKey(const ValueKey('dialogue_window_v3')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dialogue_coral_detail_v3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dialogue_continue_indicator_v3')),
        findsOneWidget,
      );
      expect(find.textContaining('Você apareceu de novo'), findsOneWidget);
      expect(
        find.text('Estrutura provisória da caixa de diálogo.'),
        findsNothing,
      );
      expect(find.text('null'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(1024, 768),
    const Size(1152, 648),
    const Size(1280, 720),
    const Size(1600, 900),
    const Size(1920, 1080),
  ]) {
    testWidgets('Ryomi UI V3 janelas flutuantes permanecem válidas em '
        '${size.width}x${size.height}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final controller = await _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      await _enterUiV3(tester);

      final relationship = _rect(tester, 'relationship_window_position_v3');
      final interaction = _rect(tester, 'interaction_window_position_v3');
      final dialogue = _rect(tester, 'dialogue_window_position_v3');
      final ryomi = _rect(tester, 'ryomi_official_art_v3');
      final scene = _rect(tester, 'scene_region_v3');
      final hud = _rect(tester, 'top_hud_v3');
      final dock = _rect(tester, 'bottom_dock_v3');

      expect(scene.top, closeTo(hud.bottom, .1));
      expect(scene.bottom, closeTo(dock.top, .1));
      expect(relationship.overlaps(interaction), isFalse);
      expect(relationship.overlaps(dialogue), isFalse);
      expect(interaction.overlaps(dialogue), isFalse);
      expect(ryomi.bottom, greaterThan(scene.bottom));
      expect(scene.overlaps(relationship), isTrue);
      expect(scene.overlaps(interaction), isTrue);
      expect(scene.overlaps(dialogue), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Ryomi UI V3 permite todas as janelas minimizadas sem overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final controller = await _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await _enterUiV3(tester);

    final characterBeforeDialogueMinimize = _rect(
      tester,
      'ryomi_official_art_v3',
    );

    await tester.tap(find.byKey(const ValueKey('relationship_minimize_v3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('interaction_minimize_v3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dialogue_minimize_v3')));
    await tester.pumpAndSettle();

    final characterAfterDialogueMinimize = _rect(
      tester,
      'ryomi_official_art_v3',
    );
    expect(characterAfterDialogueMinimize, characterBeforeDialogueMinimize);

    expect(
      find.byKey(const ValueKey('relationship_window_minimized_v3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('interaction_window_minimized_v3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dialogue_window_minimized_v3')),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1920, 1080);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('relationship_window_minimized_v3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('interaction_window_minimized_v3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dialogue_window_minimized_v3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
