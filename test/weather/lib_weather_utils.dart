import 'package:elec/src/weather/lib_weather_utils.dart';
import 'package:test/test.dart';

void tests() {
  group('Lib_weather_utils tests:', () {
    test('makeHistoricalTerm', () {
      var xs = makeHistoricalTerm(1, 3, n: 30);

      /// bad design, you can't really test as is because it depends on asOfDate
      expect(xs.length, 30);
    });
  });
}

void main() {
  tests();
}
