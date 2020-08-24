library risk_system.marks.forward_curve;

import 'package:elec/src/time/hourly_schedule.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';
import 'package:elec_server/utils.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';

class ForwardCurve extends TimeSeries<Map<Bucket,num>>{

  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

  HourlySchedule _hourlySchedule;

  /// A simple forward curve model for daily and monthly values extending
  /// a TimeSeries<Map<Bucket,num>>.
  ForwardCurve();

  ForwardCurve.fromIterable(Iterable<IntervalTuple<Map<Bucket,num>>> xs) {
    addAll(xs);
    _hourlySchedule = HourlySchedule.fromTimeSeriesWithBucket(this);
  }

  /// Construct a forward curve given an input in this form.  The buckets
  /// can be different, but the covering needs to be complete (no gaps.)
  ///   [
  ///     {'term': '2020-07-17', '5x16': 27.10, '7x8': 15.5},
  ///     {'term': '2020-07-18', '2x16H': 22.15, '7x8': 15.5},
  ///     ...
  ///     {'term': '2020-08', '5x16': 31.50, '2x16H': 25.15, '7x8': 18.75},
  ///     ...
  ///   ]
  ///   The inputs are time-ordered.
  ForwardCurve.fromTermBucketMarks(List<Map<String,dynamic>> xs, Location location) {
    location ??= UTC;
    for (var x in xs) {
      Interval term;
      if ((x['term'] as String).length == 10) {
        term = Date.parse(x['term'], location: location);
      } else if ((x['term'] as String).length == 7) {
        term = Month.parse(x['term'], fmt: _isoFmt, location: location);
      } else {
        throw ArgumentError('Unsupported term format ${x['term']}');
      }
      var value = <Bucket,num>{};
      for (var key in x.keys.where((e) => e != 'term')) {
        value[Bucket.parse(key)] = x[key];
      }
      add(IntervalTuple(term, value));
    }
    _hourlySchedule = HourlySchedule.fromTimeSeriesWithBucket(this);
  }

  /// Calculate the value for this curve for any term and any bucket.
  /// If the curve doesn't have a value for any hour in the term you requested
  /// return [null].
  num value(Interval interval, Bucket bucket, {HourlyShape hourlyShape}) {
    if (hourlyShape != null) {
      throw ArgumentError('Not implemented yet');
    }
    var avg = 0.0;
    var i = 0;
    var hIterator = interval.hourIterator;
    while (hIterator.moveNext()) {
      if (bucket.containsHour(hIterator.current)) {
        var x0 = _hourlySchedule.value(hIterator.current);
        if (x0 == null) return x0;
        avg += x0;
        i += 1;
      }
    }
//    print(avg);
//    print(i);
    return avg/i;
  }




  /// Format this forward curve to a json format
  ///   [
  ///     {'term': '2020-07-17', '5x16': 27.10, '7x8': 15.5},
  ///     {'term': '2020-07-18', '2x16H': 22.15, '7x8': 15.5},
  ///     ...
  ///     {'term': '2020-08', '5x16': 31.50, '2x16H': 25.15, '7x8': 18.75},
  ///     ...
  ///   ]
  List<Map<String,dynamic>> toJson() {
    var out = <Map<String,dynamic>>[];
    for (var x in this) {
      var one = <String,dynamic>{};
      if (x.interval is Date) {
        one['term'] = (x.interval as Date).toString();
      } else if (x.interval is Month) {
        one['term'] = (x.interval as Month).toIso8601String();
      } else {
        throw ArgumentError('Unsupported term ${x.interval}');
      }
      for (var entry in x.value.entries) {
        one[entry.key.toString()] = entry.value;
      }
      out.add(one);
    }
    return out;
  }

  /// Make the output ready for a spreadsheet.
  /// Understands only m/dd/yyyy format!
  String toCsv() {
    var dateFmt = DateFormat('M/dd/yyyy');
    var out = <Map<String,dynamic>>[];
    for (var x in this) {
      var one = <String,dynamic>{};
      if (x.interval is Date) {
        one['term'] = (x.interval as Date).toString(dateFmt);
      } else if (x.interval is Month) {
        one['term'] = (x.interval as Month).startDate.toString(dateFmt);
      } else {
        throw ArgumentError('Unsupported term ${x.interval}');
      }
      for (var entry in x.value.entries) {
        one[entry.key.toString()] = entry.value;
      }
      out.add(one);
    }
    return listOfMapToCsv(out);
  }

//  /// Apply a function to each element of the curve.  For example use
//  /// f = (x) => 2*x to multiply each element by 2.
//  /// <p>This is a convenience function instead of operating on the underlying
//  /// TimeSeries.
//  ForwardCurve apply(num Function(num) f) {
//    var ts = TimeSeries.fromIterable(
//        timeseries.map((e) => IntervalTuple(e.interval, f(e.value))));
//    return ForwardCurve(bucket, ts);
//  }
//
//  /// Add two curves element by element.
//  ForwardCurve operator +(ForwardCurve other) {
//    if (bucket != other.bucket) {
//      throw ArgumentError('The two monthly curves must have the same bucket');
//    }
//    var ts = TimeSeries<num>();
//    for (var i = 0; i < timeseries.length; i++) {
//      var m1 = timeseries[i].interval;
//      var m2 = other.timeseries[i].interval;
//      if (m1 != m2) {
//        throw ArgumentError('Forward curves don\'t line up $m1 != $m2');
//      }
//      var value = timeseries[i].value + other.timeseries[i].value;
//      ts.add(IntervalTuple(m1, value));
//    }
//    return ForwardCurve(bucket, ts);
//  }

//  /// Subtract two curves element by element.
//  MonthlyCurve operator -(MonthlyCurve other) {
//    if (bucket != other.bucket) {
//      throw ArgumentError('The two monthly curves must be the same');
//    }
//    var ts = TimeSeries<num>();
//    for (var i = 0; i < timeseries.length; i++) {
//      var m1 = timeseries[i].interval;
//      var m2 = other.timeseries[i].interval;
//      if (m1 != m2) {
//        throw ArgumentError('Monthly curves don\'t line up $m1 != $m2');
//      }
//      var value = timeseries[i].value - other.timeseries[i].value;
//      ts.add(IntervalTuple(m1, value));
//    }
//    return MonthlyCurve(bucket, ts);
//  }
//
//  /// Multiply two curves element by element.
//  MonthlyCurve operator *(MonthlyCurve other) {
//    if (bucket != other.bucket) {
//      throw ArgumentError('The two monthly curves must be the same');
//    }
//    var ts = TimeSeries<num>();
//    for (var i = 0; i < timeseries.length; i++) {
//      var m1 = timeseries[i].interval;
//      var m2 = other.timeseries[i].interval;
//      if (m1 != m2) {
//        throw ArgumentError('Monthly curves don\'t line up $m1 != $m2');
//      }
//      var value = timeseries[i].value * other.timeseries[i].value;
//      ts.add(IntervalTuple(m1, value));
//    }
//    return MonthlyCurve(bucket, ts);
//  }
//
//  /// Add two monthly curves with different buckets using hour weighting.
//  /// The [other] bucket must to be different.  For example, calculate the
//  /// offpeak curve by adding the 2x16H and the 7x8 curves.
//  TimeSeries<num> addBucket(MonthlyCurve other) {
//    if (bucket == other.bucket) {
//      throw ArgumentError('The two monthly curves must have different buckets');
//    }
//    var ts = TimeSeries<num>();
//    for (var i = 0; i < timeseries.length; i++) {
//      var m1 = timeseries[i].interval;
//      var m2 = other.timeseries[i].interval;
//      if (m1 != m2) {
//        throw ArgumentError('The two monthly curves don\'t line up');
//      }
//      var hrs1 = bucket.countHours(m1);
//      var hrs2 = other.bucket.countHours(m1);
//      var value = (hrs1 * timeseries[i].value + hrs2 * other.timeseries[i].value) /
//          (hrs1 + hrs2);
//      ts.add(IntervalTuple(m1, value));
//    }
//    return ts;
//  }
//
//  /// Subtract two monthly curves with different buckets using hour weighting.
//  /// The [other] bucket must be different.  For example, calculate offpeak
//  /// curve by subtracting peak curve from the flat curve.
//  TimeSeries<num> subtractBucket(MonthlyCurve other) {
//    if (bucket == other.bucket) {
//      throw ArgumentError('The two monthly curves must have different buckets');
//    }
//    var ts = TimeSeries<num>();
//    for (var i = 0; i < timeseries.length; i++) {
//      var m1 = timeseries[i].interval;
//      var m2 = other.timeseries[i].interval;
//      if (m1 != m2) {
//        throw ArgumentError('The two monthly curves don\'t line up');
//      }
//      var hrs1 = bucket.countHours(m1);
//      var hrs2 = other.bucket.countHours(m1);
//      if (hrs2 >= hrs1) {
//        throw ArgumentError(
//            'Incompatible buckets: $bucket and ${other.bucket}');
//      }
//      var value = (hrs1 * timeseries[i].value - hrs2 * other.timeseries[i].value) /
//          (hrs1 - hrs2);
//      ts.add(IntervalTuple(m1, value));
//    }
//    return ts;
//  }
//
//  /// Calculate the yearly (hourly weighted) average.
//  TimeSeries<num> toYearly() {
//    var location = startMonth.location;
//    var ts = TimeSeries<num>();
//    var year = timeseries.first.interval.start.year;
//    var calYear =
//    Interval(TZDateTime(location, year), TZDateTime(location, year + 1));
//    var value = 0.0;
//    var hours = 0;
//    for (var i = 0; i < timeseries.length; i++) {
//      var year1 = timeseries[i].interval.start.year;
//      if (year != year1) {
//        // new year
//        ts.add(IntervalTuple(calYear, value));
//        value = 0.0;
//        hours = 0;
//        year = year1;
//        calYear = Interval(
//            TZDateTime(location, year), TZDateTime(location, year + 1));
//        ;
//      }
//      var hrs1 = bucket.countHours(timeseries[i].interval);
//      value = (hours * value + hrs1 * timeseries[i].value) / (hours + hrs1);
//      hours += hrs1;
//    }
//    ts.add(IntervalTuple(calYear, value));
//    return ts;
//  }
//
//  /// Calculate the value for an interval greater than one month by doing
//  /// an hour weighted average.
//  num aggregateMonths(Interval interval) {
//    if (interval.start.isBefore(timeseries.first.interval.start) ||
//        (interval.end.isAfter(timeseries.last.interval.end))) {
//      throw ArgumentError('Input interval extends beyond the underlying curve');
//    }
//
//    if (interval is Month) return timeseries.observationAt(interval).value;
//
//    if (!isBeginningOfMonth(interval.start) ||
//        !isBeginningOfMonth(interval.end)) {
//      throw ArgumentError('Input interval is not a month boundary $interval');
//    }
//
//    var months =
//    interval.splitLeft((dt) => Month.fromTZDateTime(dt)).cast<Month>();
//    var hours = months.map((month) => bucket.countHours(month));
//    var xs = timeseries.window(interval).map((e) => e.value);
//    return dama.weightedMean(xs, hours);
//  }
//
//  /// Get the curve value for this month.
//  num valueAt(Month month) => timeseries.observationAt(month).value;
//
//  /// Restrict this MonthlyCurve only to the interval of interest.
//  /// Will throw if the [interval] has no overlap with the [domain].
//  /// This [interval] should not be smaller than a month!
//  MonthlyCurve window(Interval interval) {
//    var _interval = interval.overlap(domain);
//    var aux = timeseries.window(_interval);
//    return MonthlyCurve(bucket, TimeSeries.fromIterable(aux));
//  }
}
