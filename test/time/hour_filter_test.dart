library test.time.hour_filter_test;

import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/risk_system/marks/monthly_curve.dart';
import 'package:dama/src/utils/matchers.dart';
import 'package:elec/src/time/hour_filter.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';

tests() {
  group('Hourly filter tests:', () {
    var location = getLocation('US/Eastern');
    test('with bucket', () {
      var interval = parseTerm('Q1,2019', tzLocation: location);
      var b7x8 = IsoNewEngland.bucket7x8;
      var hf = HourlyFilter(interval).withBucket(b7x8);
      var hours = hf.hours().toList();
      expect(hours.length, 719);
    });
    test('with hourBeginning and weekday', () {
      var interval = parseTerm('Dec19', tzLocation: location);
      var hf = HourlyFilter(interval)
          .withHoursBeginningIn({16, 17, 18})
          .withWeekday(7);
      var hours = hf.hours().toList();
      expect(hours.length, 15);
      expect(hours.first.start, TZDateTime(location, 2019, 12, 1, 16));
      expect(hours.last.start, TZDateTime(location, 2019, 12, 29, 18));
    });


  });
}

main() async {
  await initializeTimeZone();
  tests();
}
