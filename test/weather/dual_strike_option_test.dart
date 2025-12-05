import 'package:test/test.dart';
import 'package:elec/src/weather/dual_strike_option.dart';

void tests() {
  group('Dual strike options', () {
    var data = [
      {'temperature': 35, 'price': 89},
      {'temperature': 31, 'price': 160},
      {'temperature': 30, 'price': 168},
      {'temperature': 22, 'price': 160},
    ];
    var ds1 = DualStrikeOption(cold2Payoff(32, 150), maxPayout: 50);

    test('one option', () {
      var payoffs =
          data.map((Map e) => ds1.value(e['temperature'], e['price']));
      expect(payoffs.take(4).toList(), [0, 10, 36, 50]);
    });
  });
}

void main() {
  tests();
}
