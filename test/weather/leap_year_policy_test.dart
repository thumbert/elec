import 'package:date/date.dart';
import 'package:elec/src/weather/leap_year_policy.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Leap year policy tests:', () {
    test('skip29Feb', () {
      var ts = TimeSeries.fromIterable([
        IntervalTuple(Date.utc(2020, 2, 27), 227),
        IntervalTuple(Date.utc(2020, 2, 28), 228),
        IntervalTuple(Date.utc(2020, 2, 29), 229),
        IntervalTuple(Date.utc(2020, 3, 1), 31),
      ]);
      var ts2 = ts.applyLeapYearPolicy(LeapYearPolicy.remove29Feb);
      expect(ts2, ts..removeAt(2));
    });
    test('split28FebNonLeap does nothing for leap years', () {
      var ts = TimeSeries.fromIterable([
        IntervalTuple(Date.utc(2020, 2, 27), 227),
        IntervalTuple(Date.utc(2020, 2, 28), 228),
        IntervalTuple(Date.utc(2020, 2, 29), 229),
        IntervalTuple(Date.utc(2020, 3, 1), 31),
      ]);
      var ts2 = ts.applyLeapYearPolicy(LeapYearPolicy.split28FebNonLeap);
      expect(ts2, ts);
    });
    test(
        'split28FebNonLeap splits 28Feb for non-leap years into 2 observations',
        () {
      var ts = TimeSeries<num>.fromIterable([
        IntervalTuple(Date.utc(2021, 2, 27), 227),
        IntervalTuple(Date.utc(2021, 2, 28), 228),
        IntervalTuple(Date.utc(2021, 3, 1), 31),
      ]);
      var ts2 = ts.applyLeapYearPolicy(LeapYearPolicy.split28FebNonLeap);
      var res = TimeSeries<num>.fromIterable([
        IntervalTuple(Date.utc(2021, 2, 27), 227),
        IntervalTuple(
            Interval(
                TZDateTime.utc(2021, 2, 28), TZDateTime.utc(2021, 2, 28, 12)),
            228),
        IntervalTuple(
            Interval(TZDateTime.utc(2021, 2, 28, 12), TZDateTime.utc(2021, 3)),
            228),
        IntervalTuple(Date.utc(2021, 3, 1), 31),
      ]);
      expect(ts2, res);
    });
  });
}

void main() {
  tests();
}
