library physical.gas.timeseries_aggregation;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

final _location = getLocation('America/New_York');

/// Calculate the NAESB gas day interval corresponding to an input TZDateTime.
Interval gasDay(TZDateTime datetime) {
  TZDateTime _start, _end;
  // Calculation is done in the America/New_York time zone for convenience
  var startNy = TZDateTime.fromMillisecondsSinceEpoch(_location,
      datetime.millisecondsSinceEpoch); // bring it to the NY timezone
  if (startNy.hour >= 10) {
    _start =
        TZDateTime(_location, startNy.year, startNy.month, startNy.day, 10);
    _end =
        TZDateTime(_location, startNy.year, startNy.month, startNy.day + 1, 10);
  } else {
    // it's the previous gas day
    _start =
        TZDateTime(_location, startNy.year, startNy.month, startNy.day - 1, 10);
    _end = TZDateTime(_location, startNy.year, startNy.month, startNy.day, 10);
  }
  return Interval(
    TZDateTime.fromMillisecondsSinceEpoch(
        datetime.location, _start.millisecondsSinceEpoch),
    TZDateTime.fromMillisecondsSinceEpoch(
        datetime.location, _end.millisecondsSinceEpoch),
  );
}

/// Convenience function to calculate a daily summary as specified by NAESB.
/// The function [f] takes an Iterable of values and returns the summary
/// statistic.  The TimeSeries [x] should not cross day boundaries.
///
///
/// Implementation is more efficient than the simple groupByIndex + map.
TimeSeries<T> toGasDay<K, T>(
    Iterable<IntervalTuple<K>> xs, T Function(List<K>) f) {
  var grp = <Interval, List<K>>{};
  for (var x in xs) {
    var interval = gasDay(x.interval.start);
    grp.putIfAbsent(interval, () => <K>[]).add(x.value);
  }
  return TimeSeries.from(grp.keys, grp.values.map((ys) => f(ys)));
}
