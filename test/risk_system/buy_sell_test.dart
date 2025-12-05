import 'package:elec/risk_system.dart';
import 'package:test/test.dart';

void tests() {
  group('BuySell tests', () {
    test('BuySell.fromSign', () {
      var buy = BuySell.fromSign(1);
      expect(buy, BuySell.buy);
    });
    test('equality', () {
      expect(BuySell.buy == BuySell.buy, true);
      expect(BuySell.buy == BuySell.sell, false);
    });
  });
}

void main() {
  tests();
}
