library test.risk_system.marks.monthly_curve_test;

import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/risk_system/marks/monthly_curve.dart';
import 'package:dama/src/utils/matchers.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Monthly curve tests:', () {
    var location = getLocation('America/New_York');
    test('monthly curve indexing', (){
      var months = parseTerm('Q1,2013', tzLocation: location)!
        .splitLeft((dt) => Month.containing(dt))
        .cast<Month>();
      var curve = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [100, 95, 56]));
      expect(curve[1].interval, months[1]);
      expect(curve[1].value, 95);
      curve[2] = IntervalTuple(months[2], 75);
      expect(curve[2].value, 75);
    });
    test('FG13 aggregation, bucket 2x16H', () {
      var interval =
          Interval(TZDateTime(location, 2013), TZDateTime(location, 2013, 3));
      var months =
          interval.splitLeft((dt) => Month.containing(dt)).cast<Month>();
      var ts = TimeSeries.from(months, [100, 95]);
      var curve = MonthlyCurve(IsoNewEngland.bucket2x16H, ts);
      expect(curve.startMonth, months[0]);
      expect(curve.endMonth, months[1]);
      expect(curve.aggregateMonths(interval),
          equalsWithPrecision(97.64705, precision: 1E-4));
    });
    test('aggregate two buckets', () {
      var interval = parseTerm('Q1,2013', tzLocation: location)!;
      var months =
          interval.splitLeft((dt) => Month.containing(dt)).cast<Month>();
      var peak = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [100, 95, 56]));
      var offpeak = MonthlyCurve(
          IsoNewEngland.bucketOffpeak, TimeSeries.from(months, [81, 79, 47.5]));
      var flat = peak.addBucket(offpeak);
      expect(flat.length, 3);
      expect(flat.values.map((e) => e.toStringAsFixed(2)).toList(),
          ['89.99', '86.62', '51.34']);
    });
    test('add two curves', () {
      var interval = parseTerm('Q1,2013', tzLocation: location)!;
      var months =
          interval.splitLeft((dt) => Month.containing(dt)).cast<Month>();
      var c1 = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [100, 90, 80]));
      var c2 = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [80, 70, 50]));
      var c3 = c1 + c2;
      expect(c3.values.toList(), [180, 160, 130]);
    });
    test('multiply two curves', () {
      var interval = parseTerm('Q1,2013', tzLocation: location)!;
      var months =
          interval.splitLeft((dt) => Month.containing(dt)).cast<Month>();
      var c1 = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [100, 90, 80]));
      var c2 = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [1, 2, 3]));
      var c3 = c1 * c2;
      expect(c3.values.toList(), [100, 180, 240]);
    });
    test('multiply a curve by 2', () {
      var interval = parseTerm('Q1,2013', tzLocation: location)!;
      var months =
          interval.splitLeft((dt) => Month.containing(dt)).cast<Month>();
      var c1 = MonthlyCurve(
          IsoNewEngland.bucketPeak, TimeSeries.from(months, [100, 90, 80]));
      var c3 = c1.apply((x) => 2 * x);
      expect(c3.values.toList(), [200, 180, 160]);
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
