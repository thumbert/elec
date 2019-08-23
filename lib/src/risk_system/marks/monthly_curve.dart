library risk_system.marks.monthly_curve;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';

class MonthlyCurve {
  /// the time bucket associated with this curve.
  Bucket bucket;

  /// a monthly timeseries.
  TimeSeries<num> values;

  /// A simple forward curve model for monthly values.
  MonthlyCurve(this.bucket, this.values);

  /// Create the monthly timeseries for the aggregated bucket by
  /// hourly weighting.
  /// E.g. calculate the Flat curve from Peak and Offpeak curves.
  ///
  static TimeSeries<num> aggregate2Buckets(MonthlyCurve curve1, MonthlyCurve curve2) {
    var ts = TimeSeries<num>();
    var aux = curve1.values.merge(curve2.values, f: (x,y) => [x,y]);
    for (var obs in aux) {
      var hr1 = curve1.bucket.countHours(obs.interval);
      var hr2 = curve2.bucket.countHours(obs.interval);
      var value = (hr1*obs.value[0] + hr2*obs.value[1])/(hr1 + hr2);
      ts.add(IntervalTuple(obs.interval, value));
    }
    return ts;
  }

  Month get startMonth => values.first.interval;

  Month get endMonth => values.last.interval;

  /// Calculate the value for an interval greater than one month by doing
  /// an hour weighted average.
  num aggregateMonths(Interval interval) {
    if (interval.start.isBefore(values.first.interval.start) ||
        (interval.end.isAfter(values.last.interval.end)))
      throw ArgumentError('Input interval extends beyond the underlying curve');

    if (interval is Month) return values.observationAt(interval).value;

    if (!isBeginningOfMonth(interval.start) ||
        !isBeginningOfMonth(interval.end))
      throw ArgumentError('Input interval is not a month boundary $interval');

    var months =
        interval.splitLeft((dt) => Month.fromTZDateTime(dt)).cast<Month>();
    var hours = months.map((month) => bucket.countHours(month));
    var xs = values.window(interval).map((e) => e.value);
    return weightedMean(xs, hours);
  }
}

//class ForwardCurve {
//  Location location;
//  Set<Bucket> buckets;
//
//  Map<Date, List<MonthlyBucketValue>> _cache = {};
//
//  /// A representation of a forward curve as a monthly bucket curve.
//  /// In the strict sense, it is monthly values by bucket from a prompt month
//  /// to an endMonth.
//  ///
//  /// Can also be used to represent quan
//  ForwardCurve(this.buckets);
//
//  /// Set the value of this forward curve as of a given asOfDate.
//  void setCurve(Date asOfDate, List<MonthlyBucketValue> marks) {
//    var aux = <MonthlyBucketValue>[];
//    for (var mark in marks) {
//      if (mark.month.start.isBefore(asOfDate.start))
//        throw ArgumentError('Mark $mark starts before asOfDate $asOfDate');
//      if (!buckets.contains(mark.bucket))
//        throw ArgumentError('Mark bucket ${mark.bucket} is not in $buckets');
//      aux.add(mark);
//    }
//    _cache[asOfDate] = aux;
//  }
//
//  /// Get the value of this forward curve as of a given asOfDate.
//  List<MonthlyBucketValue> getCurve(Date asOfDate) {
//    if (_cache.containsKey(asOfDate)) {
//      return _cache[asOfDate];
//    } else {
//      throw ArgumentError(
//          'Cache not set for $location Forward Curve as of $asOfDate');
//    }
//  }
//
//  /// Get the value of this forward curve as of a given asOfDate.
//  TimeSeries<num> getCurveForBucket(Date asOfDate, Bucket bucket) {
//    if (_cache.containsKey(asOfDate)) {
//      var aux = _cache[asOfDate]
//          .where((mark) => mark.bucket == bucket)
//          .map((mark) => IntervalTuple(mark.month, mark.value))
//          .toList();
//      aux.sort((a, b) => a.interval.compareTo(b.interval));
//      return TimeSeries.fromIterable(aux);
//    } else {
//      throw ArgumentError(
//          'Cache not set for $location Forward Curve as of $asOfDate');
//    }
//  }
//
//  /// Get the hourly timeseries corresponding
//  TimeSeries<num> toHourly() {
//
//
//  }
//
//
//
//  /// TODO: from Mongo backend
//  Future<Null> populateCache(Date asOfDate) async {
//    //_cache[asOfDate] = ...
//  }
//}
