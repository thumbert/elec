library physical.gas.timeseries_aggregation;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

/// Convenience function to calculate a daily summary as specified by NAESB.
/// The function [f] takes an Iterable of values and returns the summary
/// statistic.  The TimeSeries [x] should not cross day boundaries.
///
///
/// Implementation is more efficient than the simple groupByIndex + map.
TimeSeries<T> toGasDay<K, T>(
    Iterable<IntervalTuple<K>> xs, T Function(List<K>) f) {
  var location = getLocation('America/New_York');
  var grp = <Interval, List<K>>{};
  for (var x in xs) {
    var start = x.interval.start;
    TZDateTime _start, _end;
    // Calculation is done in the America/New_York time zone
    var startNy = TZDateTime.fromMillisecondsSinceEpoch(location,
        x.interval.start.millisecondsSinceEpoch); // bring it to the NY timezone
    if (startNy.hour >= 10) {
      _start =
          TZDateTime(location, startNy.year, startNy.month, startNy.day, 10);
      _end = TZDateTime(
          location, startNy.year, startNy.month, startNy.day + 1, 10);
    } else {
      _start = TZDateTime(
          location, startNy.year, startNy.month, startNy.day - 1, 10);
      _end = TZDateTime(location, startNy.year, startNy.month, startNy.day, 10);
    }
    var interval = Interval(
      TZDateTime.fromMillisecondsSinceEpoch(
          start.location, _start.millisecondsSinceEpoch),
      TZDateTime.fromMillisecondsSinceEpoch(
          start.location, _end.millisecondsSinceEpoch),
    );

    grp.putIfAbsent(interval, () => <K>[]).add(x.value);
  }
  return TimeSeries.from(grp.keys, grp.values.map((ys) => f(ys)));
}
