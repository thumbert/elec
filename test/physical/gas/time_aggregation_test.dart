library test.physical.gas.time_aggregation_test;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/physical/gas/timeseries_aggregation.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() async {
  group('Physical gas functionality', () {
    test('interpolate a daily gas price series to hourly', () {
    final ds = TimeSeries.fromIterable([
      IntervalTuple(Date.utc(2024, 1, 1), 8.01),
      IntervalTuple(Date.utc(2024, 1, 2), 9.02),
      IntervalTuple(Date.utc(2024, 1, 3), 10.03),
    ]);
    final hs = hourlyInterpolateGasSeries(ds, tz: IsoNewEngland.location);
    expect(hs.length, 24 * 3);
    expect(
        hs.first,
        IntervalTuple(
            Hour.beginning(TZDateTime(IsoNewEngland.location, 2024, 1, 1, 10)),
            8.01));

    });
  });

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
  tests();
}
