library test.risk_system.buy_sell_test;

import 'package:elec/risk_system.dart';
import 'package:test/test.dart';

void tests() {
  group('BuySell tests', () {
    test('BuySell.fromSign', () {
      var buy = BuySell.fromSign(1);
      expect(buy, BuySell.buy);
    });
  });
}

void main() {
  tests();
}
