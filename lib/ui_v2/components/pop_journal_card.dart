import 'package:flutter/material.dart';

import '../design/connections_design.dart';

class PopJournalCard extends StatelessWidget {
  const PopJournalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = ConnectionsColors.paper,
    this.borderColor = ConnectionsColors.outline,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(ConnectionsRadius.xl),
      border: Border.all(color: borderColor, width: 2),
      boxShadow: ConnectionsShadows.soft,
    ),
    child: Padding(padding: padding, child: child),
  );
}
