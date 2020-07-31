library test.time.hourly_schedule_test;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/time/bucket/hourly_bucket_scalars.dart';
import 'package:elec/src/time/hourly_schedule.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';

void tests() {
  group('Hourly schedule tests:', () {
    var location = getLocation('America/New_York');
    var peak = IsoNewEngland.bucketPeak;
    var offpeak = IsoNewEngland.bucketOffpeak;
    var b2x16H = IsoNewEngland.bucket2x16H;
    var b7x8 = IsoNewEngland.bucket7x8;
    test('one value all hours', () {
      var hs = HourlySchedule.filled(10);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 10);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(ts.values.toList(), List.filled(24, 10));
      expect(hs.toJson(), {'type': 'filled', 'values': 10});
    });
    test('one value by month', () {
      var values = Map.fromIterables([1, 5, 9], [1, 5, 9]);
      var hs = HourlySchedule.byMonth(values);
      expect(hs[Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))], 1);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 5, 5, 4))), 5);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 4))), 9);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(ts.values.toList(), List.filled(24, 1));
      expect(hs.toJson(), {'type': 'byMonth',
        'values': [
          {'month': 1, 'value': 1},
          {'month': 5, 'value': 5},
          {'month': 9, 'value': 9},
        ]
      });
    });
    test('one value by bucket', () {
      var hs = HourlySchedule.byBucket({peak: 1, offpeak: 2});
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 2);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 5, 5, 4))), 2);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 23))), 2);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(
          ts.values.toList(), [...List.filled(7, 2), ...List.filled(16, 1), 2]);
      expect(hs.toJson(), {'type': 'byBucket',
        'values': [
          {'bucket': '5x16', 'value': 1},
          {'bucket': 'Offpeak', 'value': 2},
        ]
      });
    });
    test('one value by bucket and month', () {
      var values = {
        peak: {1: 10, 9: 90},
        offpeak: {1: 1, 5: 5, 9: 9},
      };
      var hs = HourlySchedule.byBucketMonth(values);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 1);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 5, 5, 4))), 5);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 23))), 9);
      expect(hs[Hour.beginning(TZDateTime(location, 2019, 9, 5, 22))], 90);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(ts.values.toList(),
          [...List.filled(7, 1), ...List.filled(16, 10), 1]);
      expect(hs.toJson(), {'type': 'byBucketMonth',
        'values': [
          {'bucket': '5x16', 'month': 1, 'value': 10},
          {'bucket': '5x16', 'month': 9, 'value': 90},
          {'bucket': 'Offpeak', 'month': 1, 'value': 1},
          {'bucket': 'Offpeak', 'month': 5, 'value': 5},
          {'bucket': 'Offpeak', 'month': 9, 'value': 9},
        ]
      });
    });
    test('one value by bucket, month, hour', () {
      var values = {
        1: [
          HourlyBucketScalars(peak, List.generate(16, (i) => i)),
          HourlyBucketScalars(offpeak, List.generate(24, (i) => i)),
        ],
        9: [
          HourlyBucketScalars(peak, List.generate(16, (i) => i + 50)),
          HourlyBucketScalars(offpeak, List.generate(24, (i) => i + 20)),
        ],
      };
      var hs = HourlySchedule.byMonthBucketHour(values);
      expect(hs[Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))], 4);
      expect(hs[Hour.beginning(TZDateTime(location, 2019, 9, 5, 4))], 24);
      expect(hs[Hour.beginning(TZDateTime(location, 2019, 9, 5, 22))], 65);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(ts.values.toList(), [
        ...List.generate(7, (i) => i),
        ...List.generate(16, (i) => i),
        23
      ]);
      var ts2 = hs.toHourly(Date(2019, 10, 14, location: location));
      expect(ts2.isEmpty, true);
      expect(hs.toJson(), {'type': 'byMonthBucketHour',
        'values': [
          {'month': 1, 'bucket': '5x16', 'value': List.generate(16, (i) => i)},
          {'month': 1, 'bucket': 'Offpeak', 'value': List.generate(24, (i) => i)},
          {'month': 9, 'bucket': '5x16', 'value': List.generate(16, (i) => i + 50)},
          {'month': 9, 'bucket': 'Offpeak', 'value': List.generate(24, (i) => i + 20)},
        ]
      });
    });
    test('from timeseries, complete covering', () {
      var month = Month(2021, 1, location: location);
      var ts = TimeSeries.fromIterable([
        IntervalTuple(month, {peak: 60.7, b2x16H: 54.93, b7x8: 48.89})
      ]);
      var hs = HourlySchedule.fromTimeSeriesWithBucket(ts);
      var out = hs.toHourly(month);
      expect(out.length, 744);
    });
    test('from timeseries, incomplete covering', () {
      var month = Month(2021, 1, location: location);
      var ts = TimeSeries.fromIterable([IntervalTuple(month, {peak: 60.7})]);
      var hs = HourlySchedule.fromTimeSeriesWithBucket(ts);
      var out = hs.toHourly(month);
      expect(out.length, 320);
    });
    test('toMonthly', () {
      var hs = HourlySchedule.filled(1);
      var count = hs.toMonthly(Term.parse('Cal20', location).interval,
              (xs) => xs.length);
      expect(count.length, 12);
      expect(count.observationAt(Month(2020,3, location: location)).value, 743);
    });

  });
}

void main() async {
  await initializeTimeZone();
  tests();
}
