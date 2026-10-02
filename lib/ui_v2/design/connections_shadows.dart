import 'package:flutter/material.dart';

abstract final class ConnectionsShadows {
  static const soft = [
    BoxShadow(color: Color(0x246B535D), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const button = [
    BoxShadow(color: Color(0x406B535D), blurRadius: 0, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x1F6B535D), blurRadius: 14, offset: Offset(0, 7)),
  ];
}
