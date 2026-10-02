import 'package:flutter/material.dart';

import 'connections_colors_v3.dart';

abstract final class ConnectionsTypographyV3 {
  static const String? titleFont = null;
  static const String? bodyFont = null;

  static TextStyle gameTitle({double size = 20}) => TextStyle(
    color: ConnectionsColorsV3.ink,
    fontFamily: titleFont,
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: .1,
  );

  static TextStyle windowTitle({double size = 18}) => TextStyle(
    color: ConnectionsColorsV3.ink,
    fontFamily: titleFont,
    fontSize: size,
    fontWeight: FontWeight.w900,
  );

  static TextStyle button({double size = 14}) => TextStyle(
    color: ConnectionsColorsV3.ink,
    fontFamily: titleFont,
    fontSize: size,
    fontWeight: FontWeight.w900,
  );

  static TextStyle resourceValue({double size = 16}) => TextStyle(
    color: ConnectionsColorsV3.ink,
    fontFamily: bodyFont,
    fontSize: size,
    fontWeight: FontWeight.w900,
  );

  static TextStyle resourceLabel({double size = 11}) => TextStyle(
    color: ConnectionsColorsV3.inkSecondary,
    fontFamily: bodyFont,
    fontSize: size,
    fontWeight: FontWeight.w700,
  );

  static TextStyle body({double size = 13}) => TextStyle(
    color: ConnectionsColorsV3.ink,
    fontFamily: bodyFont,
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle secondary({double size = 12}) => TextStyle(
    color: ConnectionsColorsV3.inkSecondary,
    fontFamily: bodyFont,
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static TextStyle badge({double size = 10.5}) => TextStyle(
    color: ConnectionsColorsV3.onColor,
    fontFamily: titleFont,
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: .35,
  );

  static TextStyle tooltip({double size = 12}) => TextStyle(
    color: ConnectionsColorsV3.onColor,
    fontFamily: bodyFont,
    fontSize: size,
    fontWeight: FontWeight.w700,
  );
}
