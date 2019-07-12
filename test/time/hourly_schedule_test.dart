library test.time.hourly_schedule_test;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/time/hourly_schedule.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';

tests() {
  group('Hourly schedule tests:', () {
    var location = getLocation('US/Eastern');
    test('one value all hours', () {
      var hs = HourlySchedule.filled(10);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 10);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(ts.values.toList(), List.filled(24, 10));
    });
    test('byMonth', () {
      var hs = HourlySchedule.byMonth([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 1);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 5, 5, 4))), 5);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 4))), 9);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(ts.values.toList(), List.filled(24, 1));
    });
    test('byBucket', () {
      var peak = IsoNewEngland.bucketPeak;
      var offpeak = IsoNewEngland.bucketOffpeak;
      var hs = HourlySchedule.byBucket([peak, offpeak], [1, 2]);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 2);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 5, 5, 4))), 2);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 23))), 2);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(
          ts.values.toList(), [...List.filled(7, 2), ...List.filled(16, 1), 2]);
    });

    test('byBucketMonth', () {
      var peak = IsoNewEngland.bucketPeak;
      var offpeak = IsoNewEngland.bucketOffpeak;
      var values = {
        peak: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120],
        offpeak: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      };
      var hs = HourlySchedule.byBucketMonth(values);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 1);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 5, 5, 4))), 5);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 23))), 9);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 22))), 90);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(
          ts.values.toList(), [...List.filled(7, 1), ...List.filled(16, 10), 1]);
    });

    test('byHourMonth', () {
      var values = List.generate(12, (i) => List.generate(24, (h) => 100*i + h));
      var hs = HourlySchedule.byHourMonth(values);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 1, 1, 4))), 4);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 5, 5, 4))), 404);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 23))), 823);
      expect(hs.value(Hour.beginning(TZDateTime(location, 2019, 9, 5, 22))), 822);
      var ts = hs.toHourly(Date(2019, 1, 4, location: location));
      expect(ts.values.toList(), List.generate(24, (i) => i));
      var ts2 = hs.toHourly(Date(2019, 10, 14, location: location));
      expect(ts2.values.toList(), List.generate(24, (i) => 900 + i));
    });
  });
}

main() async {
  await initializeTimeZone();
  tests();
}
