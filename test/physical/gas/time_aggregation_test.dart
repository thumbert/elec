library test.physical.gas.time_aggregation_test;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/src/physical/gas/timeseries_aggregation.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() async {
  group('Gas day aggregation: ', () {
    test('for a West zone timeseries', () {
      var location = getLocation('America/Los_Angeles');
      var interval = Interval(TZDateTime(location, 2020, 11, 18, 7),
          TZDateTime(location, 2020, 11, 20, 7));
      var hours = interval.splitLeft((dt) => Hour.beginning(dt));
      var ts = TimeSeries.from(hours, [
        ...List.filled(24, 1.0),
        ...List.filled(24, 2.0),
      ]);
      var res = toGasDay(ts, mean);
      expect(res.length, 2);
      expect(res.values.toList(), [1.0, 2.0]);
      expect(
          res.intervals.first,
          Interval(TZDateTime(location, 2020, 11, 18, 7),
              TZDateTime(location, 2020, 11, 19, 7)));
    });

    test('for an East zone timeseries', () {
      var location = getLocation('America/New_York');
      var interval = Interval(TZDateTime(location, 2020, 11, 18, 10),
          TZDateTime(location, 2020, 11, 20, 10));
      var hours = interval.splitLeft((dt) => Hour.beginning(dt));
      var ts = TimeSeries.from(hours, [
        ...List.filled(24, 1.0),
        ...List.filled(24, 2.0),
      ]);
      var res = toGasDay(ts, mean);
      expect(res.length, 2);
      expect(res.values.toList(), [1.0, 2.0]);
    });
  });
}

void main() async {
  initializeTimeZones();
  await tests();
}
