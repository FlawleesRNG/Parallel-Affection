import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug/ui_debug_settings_v3.dart';

class DebugRegionLabelV3 extends StatelessWidget {
  const DebugRegionLabelV3(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: UiDebugSettingsV3.showUiDebugLabels,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0x99544745),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ),
        );
      },
    );
  }
}
