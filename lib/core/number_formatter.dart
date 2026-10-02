abstract final class NumberFormatter {
  static String compact(int value) {
    final absolute = value.abs();
    if (absolute < 1000) return value.toString();
    const units = [(1000000000, 'bi'), (1000000, 'mi'), (1000, 'mil')];
    for (final unit in units) {
      if (absolute >= unit.$1) {
        final amount = value / unit.$1;
        return '${_compactDecimal(amount)} ${unit.$2}';
      }
    }
    return value.toString();
  }

  static String money(int value) => 'R\$ ${compact(value)}';

  static String moneyDecimal(double value) {
    final rounded = value.abs() < 1000 ? value : value.roundToDouble();
    if (rounded == rounded.roundToDouble()) {
      return money(rounded.round());
    }
    return 'R\$ ${_compactDecimal(rounded)}';
  }

  static String _compactDecimal(double amount) {
    final absolute = amount.abs();
    final decimals = absolute >= 100
        ? 0
        : absolute >= 10
        ? 1
        : 2;
    var text = amount.toStringAsFixed(decimals).replaceAll('.', ',');
    while (text.contains(',') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith(',')) text = text.substring(0, text.length - 1);
    return text;
  }
}
