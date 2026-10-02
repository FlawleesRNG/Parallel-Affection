import 'package:flutter/foundation.dart';

abstract final class UiDebugSettingsV3 {
  static final ValueNotifier<bool> showUiDebugLabels = ValueNotifier<bool>(
    false,
  );

  static bool get labelsVisible => showUiDebugLabels.value;

  static set labelsVisible(bool value) {
    showUiDebugLabels.value = value;
  }

  static void toggleLabels() {
    showUiDebugLabels.value = !showUiDebugLabels.value;
  }
}
