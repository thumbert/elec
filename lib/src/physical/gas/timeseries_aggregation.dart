library physical.gas.timeseries_aggregation;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

final _location = getLocation('America/New_York');

/// Create an hourly gas series from an input daily timeseries.
/// The timezone of the input series is irrelevant (UTC is preffered).
/// The timezone of the output series will be in the [tz] location.
///
/// See NAESB timely gas nomination cycle.
/// 
TimeSeries<K> hourlyInterpolateGasSeries<K>(TimeSeries<K> dailySeries,
    {required Location tz}) {
  var out = TimeSeries<K>();
  if (dailySeries.isEmpty) return out;
  for (var e in dailySeries) {
    var day = (e.interval as Date).withTimeZone(tz);
    var start = day.start.add(Duration(hours: 10));
    var end = start.add(Duration(days: 1));
    while (start.isBefore(end)) {
      out.add(IntervalTuple(Hour.beginning(start), e.value));
      start = start.add(Duration(hours: 1));
    }
  }
  return out;
}


/// Calculate the NAESB gas day interval corresponding to an input TZDateTime.
Interval gasDay(TZDateTime datetime) {
  TZDateTime start, end;
  // Calculation is done in the America/New_York time zone for convenience
  var startNy = TZDateTime.fromMillisecondsSinceEpoch(_location,
      datetime.millisecondsSinceEpoch); // bring it to the NY timezone
  if (startNy.hour >= 10) {
    start = TZDateTime(_location, startNy.year, startNy.month, startNy.day, 10);
    end =
        TZDateTime(_location, startNy.year, startNy.month, startNy.day + 1, 10);
  } else {
    // it's the previous gas day
    start =
        TZDateTime(_location, startNy.year, startNy.month, startNy.day - 1, 10);
    end = TZDateTime(_location, startNy.year, startNy.month, startNy.day, 10);
  }
  return Interval(
    TZDateTime.fromMillisecondsSinceEpoch(
        datetime.location, start.millisecondsSinceEpoch),
    TZDateTime.fromMillisecondsSinceEpoch(
        datetime.location, end.millisecondsSinceEpoch),
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
