library test.elec.timeseries.seasonal_format_test;

import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timezone/data/latest.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/analysis/format/seasonal_format.dart' as seasonal;

void tests() {
  group('Timeseries seasonal format:', () {
    test('year/month', () {
      var months = Month.utc(2015, 12).nextN(28);
      var ts = TimeSeries.from(months, List.filled(months.length, 1));
      var out = seasonal.formatYearMonth(ts);
      expect(out.length, 3);
      expect(out.first.length, 13);
    });
    test('month/year', () {
      var months = Month.utc(2016, 3).nextN(28);
      var ts = TimeSeries.from(months, List.filled(months.length, 1));
      var out = seasonal.formatMonthYear(ts);
      expect(out.length, 12);
      expect(out.first.length, 3);
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
