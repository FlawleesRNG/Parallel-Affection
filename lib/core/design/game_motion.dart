import 'package:flutter/material.dart';

abstract final class GameMotion {
  static const quick = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const pressCurve = Curves.easeOutCubic;
}
