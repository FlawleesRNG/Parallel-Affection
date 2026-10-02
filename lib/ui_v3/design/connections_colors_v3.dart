import 'package:flutter/material.dart';

abstract final class ConnectionsColorsV3 {
  static const background = Color(0xFFF7EEDC);
  static const backgroundSecondary = Color(0xFFEEDFCF);
  static const paper = Color(0xFFFFF9EF);
  static const paperElevated = Color(0xFFFFFCF6);
  static const warmSurface = Color(0xFFF3E3D5);
  static const disabledSurface = Color(0xFFDDD0C8);

  static const ink = Color(0xFF3E303B);
  static const inkSecondary = Color(0xFF75656E);
  static const inkSoft = Color(0xFF9A8990);
  static const outline = Color(0xFF5B4351);
  static const outlineSoft = Color(0xFFA88991);
  static const onColor = Color(0xFFFFF9F2);

  static const relationship = Color(0xFFE87572);
  static const relationshipDark = Color(0xFFB9525B);
  static const interaction = Color(0xFF4EA6A0);
  static const interactionDark = Color(0xFF327B78);
  static const jobs = Color(0xFF70A77C);
  static const jobsDark = Color(0xFF4D7659);
  static const hobbies = Color(0xFF679CC0);
  static const hobbiesDark = Color(0xFF486F8B);
  static const achievements = Color(0xFF8A70A3);
  static const achievementsDark = Color(0xFF624E78);
  static const shop = Color(0xFFDDAE3F);
  static const shopDark = Color(0xFFA87827);
  static const extras = Color(0xFFB96179);
  static const extrasDark = Color(0xFF844654);

  static const money = Color(0xFFCF963A);
  static const diamonds = Color(0xFF7D86BC);
  static const cherries = Color(0xFFC94F5D);
  static const timeBlocks = Color(0xFF4FA49D);
  static const speed = Color(0xFFD77C4D);
  static const prestige = Color(0xFF806C98);

  static const success = Color(0xFF5D9C72);
  static const warning = Color(0xFFD29B35);
  static const error = Color(0xFFC85B60);
  static const info = Color(0xFF6094B5);
  static const locked = Color(0xFF9C9095);

  static Color darkFor(Color color) {
    if (color == relationship) return relationshipDark;
    if (color == interaction) return interactionDark;
    if (color == jobs) return jobsDark;
    if (color == hobbies) return hobbiesDark;
    if (color == achievements) return achievementsDark;
    if (color == shop) return shopDark;
    if (color == extras) return extrasDark;
    return Color.lerp(color, outline, .38)!;
  }
}
