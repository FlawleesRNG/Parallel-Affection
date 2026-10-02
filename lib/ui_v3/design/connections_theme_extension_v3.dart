import 'package:flutter/material.dart';

import 'connections_colors_v3.dart';

@immutable
class ConnectionsThemeExtensionV3
    extends ThemeExtension<ConnectionsThemeExtensionV3> {
  const ConnectionsThemeExtensionV3({
    required this.background,
    required this.paper,
    required this.outline,
    required this.relationship,
    required this.interaction,
  });

  final Color background;
  final Color paper;
  final Color outline;
  final Color relationship;
  final Color interaction;

  static const cozyArcadeJournal = ConnectionsThemeExtensionV3(
    background: ConnectionsColorsV3.background,
    paper: ConnectionsColorsV3.paper,
    outline: ConnectionsColorsV3.outline,
    relationship: ConnectionsColorsV3.relationship,
    interaction: ConnectionsColorsV3.interaction,
  );

  @override
  ConnectionsThemeExtensionV3 copyWith({
    Color? background,
    Color? paper,
    Color? outline,
    Color? relationship,
    Color? interaction,
  }) => ConnectionsThemeExtensionV3(
    background: background ?? this.background,
    paper: paper ?? this.paper,
    outline: outline ?? this.outline,
    relationship: relationship ?? this.relationship,
    interaction: interaction ?? this.interaction,
  );

  @override
  ConnectionsThemeExtensionV3 lerp(
    ThemeExtension<ConnectionsThemeExtensionV3>? other,
    double t,
  ) {
    if (other is! ConnectionsThemeExtensionV3) return this;
    return ConnectionsThemeExtensionV3(
      background: Color.lerp(background, other.background, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      relationship: Color.lerp(relationship, other.relationship, t)!,
      interaction: Color.lerp(interaction, other.interaction, t)!,
    );
  }
}
