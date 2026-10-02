import 'package:flutter/material.dart';

import 'connections_colors.dart';

abstract final class ConnectionsTypography {
  static const title = TextStyle(
    color: ConnectionsColors.ink,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: .2,
  );

  static const label = TextStyle(
    color: ConnectionsColors.ink,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );

  static const caption = TextStyle(
    color: ConnectionsColors.muted,
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );
}
