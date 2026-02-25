import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/time/shape/tb_n.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';

void tests() {
  group('Top N - Bottom N (tb4) tests:', () {
    test('one day', () {
      var term = Term.parse('23Feb26', IsoNewEngland.location);
      var hours = term.hours();
      var price = TimeSeries.from(hours, [
        51.74,
        60.73,
        51.82,
        53.55,
        53.67,
        50.24,
        55.55,
        76.9,
        80.54,
        56.41,
        75.24,
        70.12,
        76.21,
        78.89,
        82.98,
        81.99,
        92.97,
        87.66,
        80.82,
        67.54,
        68.52,
        69.26,
        68.44,
      ]);
      var spread = tbN(price, n: 4);
      expect(spread.value.toStringAsFixed(3), '34.562');
    });
  });
}

void main() async {
  await initializeTimeZone();
  tests();
}
