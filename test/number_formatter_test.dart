import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_conexoes/core/number_formatter.dart';

void main() {
  test('formata valores grandes', () {
    expect(NumberFormatter.money(1000), 'R\$ 1 mil');
    expect(NumberFormatter.money(12400), 'R\$ 12,4 mil');
    expect(NumberFormatter.money(1080000), 'R\$ 1,08 mi');
    expect(NumberFormatter.compact(3400000), '3,4 mi');
  });
}
