library test.weather.lib_weather_utils_test;

import 'package:date/date.dart';
import 'package:elec/src/weather/lib_weather_utils.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

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
