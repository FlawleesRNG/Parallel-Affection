import 'package:flutter/animation.dart';

abstract final class ConnectionsMotionV3 {
  static const veryFast = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 200);
  static const gentle = Duration(milliseconds: 280);
  static const emphasis = Duration(milliseconds: 420);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const press = Curves.easeOut;
  static const expand = Curves.easeInOutCubic;
  static const fade = Curves.easeInOut;
}
