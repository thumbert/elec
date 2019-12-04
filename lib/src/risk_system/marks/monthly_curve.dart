library risk_system.marks.monthly_curve;

import 'package:dama/dama.dart' as dama;
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';

class MonthlyCurve {
  /// the time bucket associated with this curve.
  final Bucket bucket;

  /// a monthly timeseries.
  final TimeSeries<num> timeseries;

  /// A simple forward curve model for monthly values.
  MonthlyCurve(this.bucket, this.timeseries);

  Month get startMonth => timeseries.first.interval;

  Month get endMonth => timeseries.last.interval;

  Interval get domain =>
      Interval(timeseries.first.interval.start, timeseries.last.interval.end);

  Iterable<Month> get months => timeseries.intervals.cast<Month>();

  Iterable<num> get values => timeseries.values;

  IntervalTuple<num> operator [](int i) => timeseries[i];

  operator []=(int i, IntervalTuple<num> obs) => timeseries[i] = obs;

  /// Apply a function to each element of the curve.  For example use
  /// f = (x) => 2*x to multiply each element by 2.
  /// <p>This is a convenience function instead of operating on the underlying
  /// TimeSeries.
  MonthlyCurve apply(num Function(num) f) {
    var ts = TimeSeries.fromIterable(
        timeseries.map((e) => IntervalTuple(e.interval, f(e.value))));
    return MonthlyCurve(bucket, ts);
  }

  /// Add two curves element by element.
  MonthlyCurve operator +(MonthlyCurve other) {
    if (domain != other.domain)
      throw ArgumentError('The two monthly curves don\'t have the same domain');
    if (bucket != other.bucket)
      throw ArgumentError('The two monthly curves must be the same');
    var ts = TimeSeries<num>();
    for (int i = 0; i < timeseries.length; i++) {
      var m1 = timeseries[i].interval;
      var m2 = other.timeseries[i].interval;
      if (m1 != m2)
        throw ArgumentError('Monthly curves don\'t line up $m1 != $m2');
      var value = timeseries[i].value + other.timeseries[i].value;
      ts.add(IntervalTuple(m1, value));
    }
    return MonthlyCurve(bucket, ts);
  }

  /// Subtract two curves element by element.
  MonthlyCurve operator -(MonthlyCurve other) {
    if (domain != other.domain)
      throw ArgumentError('The two monthly curves don\'t have the same domain');
    if (bucket != other.bucket)
      throw ArgumentError('The two monthly curves must be the same');
    var ts = TimeSeries<num>();
    for (int i = 0; i < timeseries.length; i++) {
      var m1 = timeseries[i].interval;
      var m2 = other.timeseries[i].interval;
      if (m1 != m2)
        throw ArgumentError('Monthly curves don\'t line up $m1 != $m2');
      var value = timeseries[i].value - other.timeseries[i].value;
      ts.add(IntervalTuple(m1, value));
    }
    return MonthlyCurve(bucket, ts);
  }

  /// Multiply two curves element by element.
  MonthlyCurve operator *(MonthlyCurve other) {
    if (domain != other.domain)
      throw ArgumentError('The two monthly curves don\'t have the same domain');
    if (bucket != other.bucket)
      throw ArgumentError('The two monthly curves must be the same');
    var ts = TimeSeries<num>();
    for (int i = 0; i < timeseries.length; i++) {
      var m1 = timeseries[i].interval;
      var m2 = other.timeseries[i].interval;
      if (m1 != m2)
        throw ArgumentError('Monthly curves don\'t line up $m1 != $m2');
      var value = timeseries[i].value * other.timeseries[i].value;
      ts.add(IntervalTuple(m1, value));
    }
    return MonthlyCurve(bucket, ts);
  }

  /// Add two monthly curves with different buckets using hour weighting.
  /// The [other] bucket must to be different.  For example, calculate the
  /// offpeak curve by adding the 2x16H and the 7x8 curves.
  TimeSeries<num> addBucket(MonthlyCurve other) {
    if (domain != other.domain)
      throw ArgumentError('The two monthly curves don\'t have the same domain');
    if (bucket == other.bucket)
      throw ArgumentError('The two monthly curves must have different buckets');
    var ts = TimeSeries<num>();
    for (int i = 0; i < timeseries.length; i++) {
      var m1 = timeseries[i].interval;
      var m2 = other.timeseries[i].interval;
      if (m1 != m2)
        throw ArgumentError('The two monthly curves don\'t line up');
      var hrs1 = bucket.countHours(m1);
      var hrs2 = other.bucket.countHours(m1);
      var value = (hrs1 * timeseries[i].value + hrs2 * other.timeseries[i].value) /
          (hrs1 + hrs2);
      ts.add(IntervalTuple(m1, value));
    }
    return ts;
  }

  /// Subtract two monthly curves with different buckets using hour weighting.
  /// The [other] bucket must to be different.  For example, calculate offpeak
  /// curve by subtracting peak curve from the flat curve.
  TimeSeries<num> subtractBucket(MonthlyCurve other) {
    if (domain != other.domain)
      throw ArgumentError('The two monthly curves don\'t have the same domain');
    if (bucket == other.bucket)
      throw ArgumentError('The two monthly curves must have different buckets');
    var ts = TimeSeries<num>();
    for (int i = 0; i < timeseries.length; i++) {
      var m1 = timeseries[i].interval;
      var m2 = other.timeseries[i].interval;
      if (m1 != m2)
        throw ArgumentError('The two monthly curves don\'t line up');
      var hrs1 = bucket.countHours(m1);
      var hrs2 = other.bucket.countHours(m1);
      if (hrs2 >= hrs1)
        throw ArgumentError(
            'Incompatible buckets: $bucket and ${other.bucket}');
      var value = (hrs1 * timeseries[i].value - hrs2 * other.timeseries[i].value) /
          (hrs1 - hrs2);
      ts.add(IntervalTuple(m1, value));
    }
    return ts;
  }

  /// Calculate the yearly (hourly weighted) average.
  TimeSeries<num> toYearly() {
    var location = startMonth.location;
    var ts = TimeSeries<num>();
    var year = timeseries.first.interval.start.year;
    var calYear =
        Interval(TZDateTime(location, year), TZDateTime(location, year + 1));
    num value = 0.0;
    int hours = 0;
    for (int i = 0; i < timeseries.length; i++) {
      var year1 = timeseries[i].interval.start.year;
      if (year != year1) {
        // new year
        ts.add(IntervalTuple(calYear, value));
        value = 0.0;
        hours = 0;
        year = year1;
        calYear = Interval(
            TZDateTime(location, year), TZDateTime(location, year + 1));
        ;
      }
      var hrs1 = bucket.countHours(timeseries[i].interval);
      value = (hours * value + hrs1 * timeseries[i].value) / (hours + hrs1);
      hours += hrs1;
    }
    ts.add(IntervalTuple(calYear, value));
    return ts;
  }

  /// Calculate the value for an interval greater than one month by doing
  /// an hour weighted average.
  num aggregateMonths(Interval interval) {
    if (interval.start.isBefore(timeseries.first.interval.start) ||
        (interval.end.isAfter(timeseries.last.interval.end)))
      throw ArgumentError('Input interval extends beyond the underlying curve');

    if (interval is Month) return timeseries.observationAt(interval).value;

    if (!isBeginningOfMonth(interval.start) ||
        !isBeginningOfMonth(interval.end))
      throw ArgumentError('Input interval is not a month boundary $interval');

    var months =
        interval.splitLeft((dt) => Month.fromTZDateTime(dt)).cast<Month>();
    var hours = months.map((month) => bucket.countHours(month));
    var xs = timeseries.window(interval).map((e) => e.value);
    return dama.weightedMean(xs, hours);
  }

  /// Get the curve value for this month.
  num valueAt(Month month) => timeseries.observationAt(month).value;

  /// Restrict this MonthlyCurve only to the interval of interest.
  /// Will throw if the [interval] has no overlap with the [domain].
  /// This [interval] should not be smaller than a month!
  MonthlyCurve window(Interval interval) {
    var _interval = interval.overlap(domain);
    var aux = timeseries.window(_interval);
    return MonthlyCurve(bucket, TimeSeries.fromIterable(aux));
  }
}
