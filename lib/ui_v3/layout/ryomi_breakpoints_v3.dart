import 'package:flutter/widgets.dart';

enum RyomiLayoutMode { wideDesktop, desktop, compactDesktop, tablet, mobile }

class RyomiLayoutSpec {
  const RyomiLayoutSpec({
    required this.size,
    required this.mode,
    required this.shortHeight,
  });

  final Size size;
  final RyomiLayoutMode mode;
  final bool shortHeight;

  factory RyomiLayoutSpec.fromSize(Size size) {
    final width = size.width;
    final height = size.height;
    final mode = width >= 1440
        ? RyomiLayoutMode.wideDesktop
        : width >= 1180
        ? RyomiLayoutMode.desktop
        : width >= 960
        ? RyomiLayoutMode.compactDesktop
        : width >= 600
        ? RyomiLayoutMode.tablet
        : RyomiLayoutMode.mobile;
    return RyomiLayoutSpec(
      size: size,
      mode: height < 560 && mode.index <= RyomiLayoutMode.compactDesktop.index
          ? RyomiLayoutMode.compactDesktop
          : mode,
      shortHeight: height < 620,
    );
  }

  bool get usesDesktopFrame =>
      mode == RyomiLayoutMode.wideDesktop ||
      mode == RyomiLayoutMode.desktop ||
      mode == RyomiLayoutMode.compactDesktop;

  bool get usesVerticalFrame => !usesDesktopFrame;

  bool get isWideDesktop => mode == RyomiLayoutMode.wideDesktop;
  bool get isCompactDesktop => mode == RyomiLayoutMode.compactDesktop;
  bool get isMobile => mode == RyomiLayoutMode.mobile;
  bool get isTablet => mode == RyomiLayoutMode.tablet;

  double get hudHeight => switch (mode) {
    RyomiLayoutMode.wideDesktop => 68,
    RyomiLayoutMode.desktop => 64,
    RyomiLayoutMode.compactDesktop => shortHeight ? 60 : 64,
    RyomiLayoutMode.tablet => shortHeight ? 64 : 66,
    RyomiLayoutMode.mobile => shortHeight ? 60 : 64,
  };

  double get dockHeight => switch (mode) {
    RyomiLayoutMode.wideDesktop => 98,
    RyomiLayoutMode.desktop => 92,
    RyomiLayoutMode.compactDesktop => shortHeight ? 76 : 82,
    RyomiLayoutMode.tablet => shortHeight ? 78 : 82,
    RyomiLayoutMode.mobile => shortHeight ? 68 : 72,
  };

  double get selectorWidth => switch (mode) {
    RyomiLayoutMode.wideDesktop => 270,
    RyomiLayoutMode.desktop => 245,
    RyomiLayoutMode.compactDesktop => size.width < 1080 ? 210 : 215,
    RyomiLayoutMode.tablet => 0,
    RyomiLayoutMode.mobile => 0,
  };

  double get compactSelectorHeight => isMobile ? 80 : 82;

  double get dockGap => isMobile || isCompactDesktop ? 4 : 8;
  double get dockHorizontalPadding => isMobile
      ? 6
      : isCompactDesktop
      ? 10
      : 14;
  double get dockVerticalPadding => isMobile
      ? 6
      : isCompactDesktop
      ? 7
      : 9;
  double get dockIconSize => isMobile
      ? 20
      : isCompactDesktop
      ? 24
      : 25;
  double get dockFontSize => isMobile
      ? 9.5
      : isCompactDesktop
      ? 12.5
      : 13;
}
