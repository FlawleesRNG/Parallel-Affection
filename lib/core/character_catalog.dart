import 'package:flutter/material.dart';

abstract final class PlayableCharacterIds {
  static const roxanne = 'roxanne';
  static const kai = 'kai';
  static const sofia = 'sofia';
  static const astra = 'astra';
  static const legacyRyomi = 'ryomi';
  static const legacyLia = 'lia';
}

class CharacterScenePresentation {
  const CharacterScenePresentation({
    required this.desktopHeightFactor,
    required this.compactHeightFactor,
    required this.alignment,
    this.visualOffset = Offset.zero,
    this.assetAspectRatio = 1500 / 2600,
    this.visibleLeftRatio = 0,
    this.visibleRightRatio = 1,
    this.visibleTopRatio = 0,
    this.visibleBottomRatio = 1,
  });

  final double desktopHeightFactor;
  final double compactHeightFactor;
  final Alignment alignment;
  final Offset visualOffset;
  final double assetAspectRatio;
  final double visibleLeftRatio;
  final double visibleRightRatio;
  final double visibleTopRatio;
  final double visibleBottomRatio;

  double get visibleWidthRatio => visibleRightRatio - visibleLeftRatio;

  double get visibleHeightRatio => visibleBottomRatio - visibleTopRatio;
}

class PlayableCharacterDefinition {
  const PlayableCharacterDefinition({
    required this.id,
    required this.visibleName,
    required this.selectorOrder,
    required this.availableFromStart,
    required this.routeReady,
    required this.sceneAsset,
    this.selectorAsset,
    required this.accent,
    required this.scenePresentation,
    this.sourceName,
    this.alternatePoseAssets = const {},
  });

  final String id;
  final String visibleName;
  final int selectorOrder;
  final bool availableFromStart;
  final bool routeReady;
  final String sceneAsset;
  final String? selectorAsset;
  String get effectiveSelectorAsset => selectorAsset ?? sceneAsset;
  final Color accent;
  final CharacterScenePresentation scenePresentation;
  final String? sourceName;
  final Map<String, String> alternatePoseAssets;
}

abstract final class PlayableCharacterCatalog {
  static const roxanneSceneAsset =
      'assets/images/characters/roxanne/poses/roxanne_base_2.png';
  static const roxanneSelectorAsset =
      'assets/images/characters/roxanne/ui/roxanne_selector_card.png';
  static const kaiSceneAsset =
      'assets/images/characters/kai/poses/kai_base_1.png';
  static const kaiSelectorAsset =
      'assets/images/characters/kai/ui/kai_selector_card.png';
  static const sofiaSceneAsset =
      'assets/images/characters/sofia/poses/sofia_base_1.png';
  static const sofiaSelectorAsset =
      'assets/images/characters/sofia/ui/sofia_selector_card.png';
  static const astraSceneAsset =
      'assets/images/characters/astra/poses/astra_base_1.png';
  static const astraSelectorAsset =
      'assets/images/characters/astra/ui/astra_selector_card.png';
  static const astraFurryPoseAsset =
      'assets/images/characters/astra/poses/astra_base_2_furry.png';

  static const roxanne = PlayableCharacterDefinition(
    id: PlayableCharacterIds.roxanne,
    visibleName: 'Roxanne',
    selectorOrder: 1,
    availableFromStart: true,
    routeReady: true,
    sceneAsset: roxanneSceneAsset,
    selectorAsset: roxanneSelectorAsset,
    accent: Color(0xFFD87468),
    sourceName: 'Roxxy',
    scenePresentation: CharacterScenePresentation(
      desktopHeightFactor: .98,
      compactHeightFactor: .90,
      alignment: Alignment.bottomCenter,
      visibleLeftRatio: 404 / 1500,
      visibleRightRatio: 1041 / 1500,
      visibleTopRatio: 157 / 2600,
      visibleBottomRatio: 2560 / 2600,
    ),
  );

  static const kai = PlayableCharacterDefinition(
    id: PlayableCharacterIds.kai,
    visibleName: 'Kai',
    selectorOrder: 2,
    availableFromStart: true,
    routeReady: true,
    sceneAsset: kaiSceneAsset,
    selectorAsset: kaiSelectorAsset,
    accent: Color(0xFF628FA3),
    scenePresentation: CharacterScenePresentation(
      desktopHeightFactor: .99,
      compactHeightFactor: .92,
      alignment: Alignment.bottomCenter,
      visibleLeftRatio: 348 / 1500,
      visibleRightRatio: 1366 / 1500,
      visibleTopRatio: 161 / 2600,
      visibleBottomRatio: 2577 / 2600,
    ),
  );

  static const sofia = PlayableCharacterDefinition(
    id: PlayableCharacterIds.sofia,
    visibleName: 'Sofia',
    selectorOrder: 3,
    availableFromStart: true,
    routeReady: true,
    sceneAsset: sofiaSceneAsset,
    selectorAsset: sofiaSelectorAsset,
    accent: Color(0xFFC8844C),
    scenePresentation: CharacterScenePresentation(
      desktopHeightFactor: .98,
      compactHeightFactor: .90,
      alignment: Alignment.bottomCenter,
      visibleLeftRatio: 393 / 1500,
      visibleRightRatio: 1186 / 1500,
      visibleTopRatio: 133 / 2600,
      visibleBottomRatio: 2570 / 2600,
    ),
  );

  static const astra = PlayableCharacterDefinition(
    id: PlayableCharacterIds.astra,
    visibleName: 'Astra',
    selectorOrder: 4,
    availableFromStart: true,
    routeReady: true,
    sceneAsset: astraSceneAsset,
    selectorAsset: astraSelectorAsset,
    accent: Color(0xFF9A7AD8),
    alternatePoseAssets: {'furry': astraFurryPoseAsset},
    scenePresentation: CharacterScenePresentation(
      desktopHeightFactor: .98,
      compactHeightFactor: .90,
      alignment: Alignment.bottomCenter,
      visibleLeftRatio: 370 / 1500,
      visibleRightRatio: 1150 / 1500,
      visibleTopRatio: 128 / 2600,
      visibleBottomRatio: 2568 / 2600,
    ),
  );

  static const all = [roxanne, kai, sofia, astra];

  static const primaryRouteCharacterId = PlayableCharacterIds.roxanne;

  static String canonicalId(String id) => switch (id) {
    PlayableCharacterIds.legacyRyomi ||
    PlayableCharacterIds.legacyLia => PlayableCharacterIds.roxanne,
    _ => id,
  };

  static PlayableCharacterDefinition? maybeById(String id) {
    final canonical = canonicalId(id);
    for (final character in all) {
      if (character.id == canonical) return character;
    }
    return null;
  }

  static PlayableCharacterDefinition byId(String id) =>
      maybeById(id) ?? roxanne;

  static String visibleName(String id) => byId(id).visibleName;

  static bool routeReady(String id) => byId(id).routeReady;
}
