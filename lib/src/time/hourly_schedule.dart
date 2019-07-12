library time.schedule;

import 'package:date/date.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:timeseries/timeseries.dart';

/// Construct an hourly time schedule.  This is a convenient way to store the
/// information needed to construct a time-series with a given "pattern"
/// of values.
class HourlySchedule {

  num Function(Hour) _f;

  /// Construct a time schedule which has the same value for all hours.
  HourlySchedule.filled(num value) {
    _f = (Hour e) => value;
  }

  /// Construct a time schedule which returns different values based on the
  /// month of the year.  All hours of the month will have the same value.
  /// <p>[values] is a list of 12 values, one value for each month.
  ///
  HourlySchedule.byMonth(List<num> values) {
    if (values.length != 12)
      throw ArgumentError('Input list needs to have 12 elements');
    _f = (Hour e) {
      return values[e.start.month - 1];
    };
  }

  /// Construct a time schedule which returns different values based on the
  /// bucket. For example all Peak hours value is 100, all Offpeak hours
  /// value is 80.
  /// <p>The list of [buckets] needs to be a complete covering.
  HourlySchedule.byBucket(List<Bucket> buckets, List<num> values) {
    var n = buckets.length;
    _f = (Hour hour) {
      for (var i=0; i < n; i++) {
        if (buckets[i].containsHour(hour)) {
          return values[i];
        }
      }
      throw ArgumentError('Buckets $buckets are not covering hour $hour');
    };
  }


  /// Construct a time schedule which returns different values based on the
  /// bucket and the month of the year.
  /// <p>The list of [buckets] needs to be a complete covering.
  HourlySchedule.byBucketMonth(Map<Bucket,List<num>> values) {
    var buckets = values.keys.toList();
    var _values = values.values.toList();
    if (!_values.every((e) => e.length == 12))
      throw ArgumentError('Some buckets don\'t have 12 values.');
    var n = buckets.length;
    _f = (Hour hour) {
      for (var i=0; i < n; i++) {
        if (buckets[i].containsHour(hour)) {
          return _values[i][hour.start.month - 1];
        }
      }
      throw ArgumentError('Buckets $buckets are not covering hour $hour');
    };
  }


  /// Construct a schedule such that every day of the month has the same
  /// identical hourly schedule.  That is, 1st hour has the same value v11
  /// for all days of Jan, 2nd hour the same value v12 for all days of Jan.
  ///
  /// [values] is a List of 12 elements, one element for each month of the
  /// year.  Each element of [values] is itself a List of 24 values
  /// corresponding to each hour of the day.
  ///
  HourlySchedule.byHourMonth(List<List<num>> values) {
    if (values.length != 12)
      throw ArgumentError('Input $values list needs to have 12 elements');
    if (!values.every((e) => e.length == 24))
      throw ArgumentError('Some months don\'t have 24 values.');
    _f = (Hour e) {
      return values[e.start.month - 1][e.start.hour];
    };

  }


  /// Return the value of the schedule associated with this hour.
  num value(Hour hour) => _f(hour);


  /// Construct the hourly timeseries associated with this schedule for a
  /// given [interval].
  TimeSeries<num> toHourly(Interval interval) {
    var hours = interval.splitLeft((dt) => Hour.beginning(dt)).cast<Hour>();
    var out = TimeSeries<num>();
    for (var hour in hours) {
      out.add(IntervalTuple(hour, _f(hour)));
    }
    return out;
  }

}