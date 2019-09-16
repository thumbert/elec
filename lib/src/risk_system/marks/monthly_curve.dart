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
  final TimeSeries<num> values;

  /// A simple forward curve model for monthly values.
  MonthlyCurve(this.bucket, this.values);

  Month get startMonth => values.first.interval;

  Month get endMonth => values.last.interval;

  Interval get domain => Interval(values.first.interval.start,
    values.last.interval.end);

  /// Add one curve to this monthly curve using hour weighting.
  TimeSeries<num> add(MonthlyCurve other) {
    if (domain != other.domain)
      throw ArgumentError('The two monthly curves don\'t have the same domain');
    var ts = TimeSeries<num>();
    for (int i = 0; i < values.length; i++) {
      var m1 = values[i].interval;
      var m2 = other.values[i].interval;
      if (m1 != m2)
        throw ArgumentError('The two monthly curves don\'t line up');
      var hrs1 = bucket.countHours(m1);
      var hrs2 = other.bucket.countHours(m1);
      var value = (hrs1*values[i].value + hrs2*other.values[i].value)/(hrs1 + hrs2);
      ts.add(IntervalTuple(m1, value));
    }
    return ts;
  }

  /// Subtract one curve from this monthly curve using hour weighting.
  TimeSeries<num> subtract(MonthlyCurve other) {
    if (domain != other.domain)
      throw ArgumentError('The two monthly curves don\'t have the same domain');
    var ts = TimeSeries<num>();
    for (int i = 0; i < values.length; i++) {
      var m1 = values[i].interval;
      var m2 = other.values[i].interval;
      if (m1 != m2)
        throw ArgumentError('The two monthly curves don\'t line up');
      var hrs1 = bucket.countHours(m1);
      var hrs2 = other.bucket.countHours(m1);
      var value = (hrs1*values[i].value - hrs2*other.values[i].value)/(hrs1 - hrs2);
      ts.add(IntervalTuple(m1, value));
    }
    return ts;
  }

  /// Calculate the yearly (hourly weighted) average.
  TimeSeries<num> toYearly() {
    var location = startMonth.location;
    var ts = TimeSeries<num>();
    var year = values.first.interval.start.year;
    var calYear = Interval(TZDateTime(location, year), TZDateTime(location, year+1));
    num value = 0.0;
    int hours = 0;
    for (int i = 0; i < values.length; i++) {
      var year1 = values[i].interval.start.year;
      if (year != year1) {
        // new year
        ts.add(IntervalTuple(calYear, value));
        value = 0.0;
        hours = 0;
        year = year1;
        calYear = Interval(TZDateTime(location, year), TZDateTime(location, year+1));;
      }
      var hrs1 = bucket.countHours(values[i].interval);
      value = (hours*value + hrs1*values[i].value)/(hours + hrs1);
      hours += hrs1;
    }
    ts.add(IntervalTuple(calYear, value));
    return ts;
  }

  
  
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
    return dama.weightedMean(xs, hours);
  }
  
  /// Restrict this MonthlyCurve only to the interval of interest.
  MonthlyCurve window(Interval interval) {
    if (!domain.containsInterval(interval))
      throw ArgumentError('Input interval is not contained in the domain');
    var aux = values.window(interval);
    return MonthlyCurve(bucket, TimeSeries.fromIterable(aux));
  }

  
}
