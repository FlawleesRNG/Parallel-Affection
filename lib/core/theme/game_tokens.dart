import 'package:flutter/material.dart';

import '../character_catalog.dart';

abstract final class GameColors {
  static const ivory = Color(0xFFF5F1E8);
  static const sand = Color(0xFFEAE2D5);
  static const oat = Color(0xFFFFFDF7);
  static const rosyBeige = Color(0xFFF3E8DF);
  static const outline = Color(0xFF685D58);
  static const outlineSoft = Color(0xFFB8AAA4);
  static const disabledText = Color(0xFFAAA0A4);
  static const ink = Color(0xFF39323B);
  static const softInk = Color(0xFF786F70);

  static const relation = Color(0xFFD87468);
  static const relationDark = Color(0xFFA94F4B);
  static const jobs = Color(0xFF6FA17C);
  static const jobsDark = Color(0xFF497659);
  static const hobbies = Color(0xFF628FA3);
  static const hobbiesDark = Color(0xFF406B7F);
  static const achievements = Color(0xFF806987);
  static const achievementsDark = Color(0xFF5D4965);
  static const shop = Color(0xFFD6A13A);
  static const shopDark = Color(0xFFA67420);
  static const more = Color(0xFFA85E68);
  static const moreDark = Color(0xFF793F49);
  static const money = Color(0xFFC58A3A);
  static const diamonds = Color(0xFF7C82B8);
  static const timeBlocks = Color(0xFF4F9994);
  static const prestige = Color(0xFF77688C);
  static const success = Color(0xFF69A77C);
  static const warning = Color(0xFFD8894A);
  static const danger = Color(0xFFB85C5C);

  static const background = ivory;
  static const backgroundSoft = sand;
  static const panel = oat;
  static const panelStrong = rosyBeige;
  static const purple = achievementsDark;
  static const purpleSoft = achievements;
  static const amber = shop;
  static const copper = warning;
  static const coral = relation;
  static const rose = more;
  static const cyan = timeBlocks;
  static const blue = hobbies;
  static const emerald = jobs;
  static const orange = warning;
  static const violet = achievements;
  static const magenta = more;
  static const gold = shop;
  static const cream = oat;
  static const muted = softInk;
  static const paper = oat;
  static const creamLight = ivory;
  static const blush = rosyBeige;
  static const peach = Color(0xFFE7C5B5);
  static const butter = Color(0xFFE9D494);
  static const lavender = Color(0xFFD7D3E6);
  static const babyBlue = Color(0xFFD6E4E8);
  static const mint = Color(0xFFDCE8DD);
  static const roseBeige = rosyBeige;
  static const cuteStroke = outlineSoft;
  static const brownShadow = Color(0x30685D58);
  static const locked = disabledText;
  static const stroke = outlineSoft;
}

abstract final class GameSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class GameRadii {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const pill = 999.0;
}

abstract final class GameShadows {
  static const panel = [
    BoxShadow(color: Color(0x55000000), blurRadius: 22, offset: Offset(0, 10)),
  ];
  static const glow = [
    BoxShadow(color: Color(0x33E4A85C), blurRadius: 28, spreadRadius: 1),
  ];
}

abstract final class GameAssets {
  static const roxanneSceneAsset = PlayableCharacterCatalog.roxanneSceneAsset;
  static const roxanneSelectorAsset =
      PlayableCharacterCatalog.roxanneSelectorAsset;
  static const kaiSceneAsset = PlayableCharacterCatalog.kaiSceneAsset;
  static const kaiSelectorAsset = PlayableCharacterCatalog.kaiSelectorAsset;

  @Deprecated('Use roxanneSceneAsset.')
  static const ryomiSceneAsset = roxanneSceneAsset;
  @Deprecated('Use roxanneSelectorAsset.')
  static const ryomiSelectorAsset = roxanneSelectorAsset;

  @Deprecated('Use roxanneSceneAsset.')
  static const ryomiStage01 = ryomiSceneAsset;
  @Deprecated('Use roxanneSelectorAsset.')
  static const ryomiSelectorCard = ryomiSelectorAsset;
}
