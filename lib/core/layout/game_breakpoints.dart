enum GameLayoutSize { compact, medium, wide }

abstract final class GameBreakpoints {
  static const compact = 600.0;
  static const wide = 1100.0;

  static GameLayoutSize of(double width) {
    if (width < compact) return GameLayoutSize.compact;
    if (width < wide) return GameLayoutSize.medium;
    return GameLayoutSize.wide;
  }
}
