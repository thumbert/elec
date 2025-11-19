import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

enum RampType { morning, evening }

class Ramp {
  Ramp({
    required this.startHourBeginning,
    required this.endHourBeginning,
    required this.minLoad,
    required this.maxLoad,
  });

  final int startHourBeginning;
  final int endHourBeginning;
  final num minLoad;
  final num maxLoad;

  /// Calculate how steep the ramp is, in MW.
  num slope() => (maxLoad - minLoad) / (endHourBeginning - startHourBeginning);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ramp &&
        other.startHourBeginning == startHourBeginning &&
        other.endHourBeginning == endHourBeginning &&
        other.minLoad == minLoad &&
        other.maxLoad == maxLoad;
  }

  @override
  int get hashCode =>
      Object.hash(startHourBeginning, endHourBeginning, minLoad, maxLoad);
}

/// Extract the load ramp for morning and evening periods.
/// Not all days have ramps.
///
/// * [ts] is an hourly timeseries.
/// * [thresholdMw] is the minimum MW difference to consider a ramp.  You want to
/// avoid picking up small fluctuations as ramps.
/// * [thresholdDurationHours] is the minimum duration in hours to consider a ramp.
/// <p>Return a daily timeseries.
TimeSeries<List<Ramp>> calculateLoadRamp(TimeSeries<num> ts,
    {num thresholdMw = 300, num thresholdDurationHours = 4}) {
  var ramp = TimeSeries<List<Ramp>>();
  var byDay = groupBy(ts, (e) => Date.containing(e.interval.start));

  for (var date in byDay.keys) {
    var daySeries = byDay[date]!;

    var minima = <int>[];
    var maxima = <int>[];
    for (var i = 1; i < daySeries.length - 1; i++) {
      if (daySeries[i].value < daySeries[i - 1].value &&
          daySeries[i].value < daySeries[i + 1].value) {
        minima.add(i);
      }
      if (daySeries[i].value > daySeries[i - 1].value &&
          daySeries[i].value > daySeries[i + 1].value) {
        maxima.add(i);
      }
    }
    var ramps = <Ramp>[];
    for (var i = 0; i < minima.length; i++) {
      var minIdx = minima[i];
      // find the closest maximum after this minimum
      var maxIdx = maxima.firstWhereOrNull((m) => m > minIdx);
      if (maxIdx != null) {
        var minLoad = daySeries[minIdx].value;
        var maxLoad = daySeries[maxIdx].value;
        if ((maxLoad - minLoad) >= thresholdMw &&
            (maxIdx - minIdx) >= thresholdDurationHours) {
          ramps.add(Ramp(
            startHourBeginning: minIdx,
            endHourBeginning: maxIdx,
            minLoad: minLoad,
            maxLoad: maxLoad,
          ));
        }
      }
    }
    if (ramps.isNotEmpty) {
      ramp.add(
        IntervalTuple(date, ramps),
      );
    }
  }
  return ramp;
}
