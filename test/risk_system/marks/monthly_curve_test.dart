library test.risk_system.marks.monthly_curve_test;

import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/risk_system/marks/monthly_curve.dart';
import 'package:dama/src/utils/matchers.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

tests() {
  group('Monthly curve tests:', () {
    var location = getLocation('US/Eastern');
    test('FG13 aggregation, bucket 2x16H', () {
      var interval =
          Interval(TZDateTime(location, 2013), TZDateTime(location, 2013, 3));
      var months =
          interval.splitLeft((dt) => Month.fromTZDateTime(dt)).cast<Month>();
      var ts = TimeSeries.from(months, [100, 95]);
      var curve = MonthlyCurve(IsoNewEngland.bucket2x16H, ts);
      expect(curve.startMonth, months[0]);
      expect(curve.endMonth, months[1]);
      expect(curve.aggregateMonths(interval),
          equalsWithPrecision(97.64705, precision: 1E-4));
    });
    test('aggregate two buckets', () {
      var interval = parseTerm('Q1,2013', tzLocation: location);
      var months =
          interval.splitLeft((dt) => Month.fromTZDateTime(dt)).cast<Month>();
      var peak = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [100, 95, 56]));
      var offpeak = MonthlyCurve(
          IsoNewEngland.bucketOffpeak, TimeSeries.from(months, [81, 79, 47.5]));
      var flat = peak.add(offpeak);
      expect(flat.length, 3);
      expect(flat.values.map((e) => e.toStringAsFixed(2)).toList(),
          ['89.99', '86.62', '51.34']);
    });
  });
}

main() async {
  await initializeTimeZone();
  tests();
}
