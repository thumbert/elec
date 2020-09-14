library time.hourly_schedule;

import 'package:date/date.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/time/bucket/hourly_bucket_scalars.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';
import 'package:timeseries/timeseries.dart';

/// Construct an hourly time schedule.  This is a convenient way to store the
/// information needed to construct an hourly timeseries with a given "pattern"
/// of values.
///
/// Note: this is slow.  If code needs to be fast, avoid it.
class HourlySchedule {
  /// return the value in this hour, or [null] if the schedule is not defined
  /// for the hour.
  num Function(Hour) _f;

  Map<String, dynamic> _toJson;

  /// Construct a time schedule which has the same value for all hours.
  HourlySchedule.filled(num value) {
    _f = (Hour e) => value;
    _toJson = {
      'type': 'filled',
      'values': value,
    };
  }

  /// Construct a time schedule which returns different values based on the
  /// month of the year.  All hours of the month will have the same value.
  /// Note that not all months of the year need to be defined.
  HourlySchedule.byMonth(Map<int, num> values) {
    _f = (Hour e) {
      return values[e.start.month];
    };
    var out = <Map<String, dynamic>>[];
    for (var month in values.keys) {
      out.add({
        'month': month,
        'value': values[month],
      });
    }
    _toJson = {
      'type': 'byMonth',
      'values': out,
    };
  }

  /// Construct a time schedule which returns different values based on the
  /// bucket. For example all Peak hours value is 100, all Offpeak hours
  /// value is 80.  Note that the bucket covering doesn't need to be complete.
  HourlySchedule.byBucket(Map<Bucket, num> values) {
    _f = (Hour hour) {
      for (var bucket in values.keys) {
        if (bucket.containsHour(hour)) return values[bucket];
      }
      return null;
    };
    var out = <Map<String, dynamic>>[];
    for (var bucket in values.keys) {
      out.add({
        'bucket': bucket.toString(),
        'value': values[bucket],
      });
    }
    _toJson = {
      'type': 'byBucket',
      'values': out,
    };
  }

  /// Construct a time schedule which returns different values based on the
  /// bucket and the month of the year.
  ///
  /// Note that not all months of the year need to be defined, or the bucket
  /// covering to be complete.
  ///
  /// Note that by using a custom bucket definition, you can restrict the
  /// HourlySchedule to whatever hours of the day you are interested.
  HourlySchedule.byBucketMonth(Map<Bucket, Map<int, num>> values) {
    var buckets = values.keys.toList();
    var mthValues = values.values.toList();
    var n = buckets.length;
    _f = (Hour hour) {
      for (var i = 0; i < n; i++) {
        if (buckets[i].containsHour(hour)) {
          if (mthValues[i].containsKey(hour.start.month)) {
            return mthValues[i][hour.start.month];
          }
        }
      }
      return null;
    };
    var out = <Map<String, dynamic>>[];
    for (var bucket in values.keys) {
      for (var month in values[bucket].keys) {
        out.add({
          'bucket': bucket.toString(),
          'month': month,
          'value': values[bucket][month],
        });
      }
    }
    _toJson = {
      'type': 'byBucketMonth',
      'values': out,
    };
  }

  /// Construct a time schedule which returns different values based on the
  /// bucket, the month of the year, and the hour of the day.
  /// This allows the implementation of hourly shape curves for pricing on
  /// custom buckets.
  HourlySchedule.byMonthBucketHour(Map<int, List<HourlyBucketScalars>> values) {
    var months = values.keys.toSet();
    _f = (Hour hour) {
      if (months.contains(hour.start.month)) {
        for (var bValue in values[hour.start.month]) {
          if (bValue.bucket.containsHour(hour)) return bValue[hour];
        }
      }
      return null;
    };
    var out = <Map<String, dynamic>>[];
    for (var month in values.keys) {
      for (var bs in values[month]) {
        out.add({
          'month': month,
          'bucket': bs.bucket.toString(),
          'value': bs.values,
        });
      }
    }
    _toJson = {
      'type': 'byMonthBucketHour',
      'values': out,
    };
  }


  /// Create an hourly schedule from a timeseries.
  /// The input timeseries can have any periodicity higher than hourly.
  /// An order of magnitude faster to do [ts.interpolate(Duration(hours: 1))]
  HourlySchedule.fromTimeSeries(TimeSeries<num> ts) {
    _f = (Hour hour) {
      try {
        var obs = ts.observationContains(hour);
        return obs.value;
      } catch (e) {
        return null;
      }
    };
    _toJson = {
      'type': 'fromTimeSeries',
      'values': ts,   // FIXME: make it valid json
    };
  }


  /// Create an hourly schedule from a timeseries.  No intra-bucket shaping.
  /// For example the input timeseries can be monthly.
  /// Works even if the covering is not complete.
  @Deprecated('Too slow.  Use toHourly from ForwardCurve.')
  HourlySchedule.fromTimeSeriesWithBucket(TimeSeries<Map<Bucket,num>> ts) {
    _f = (Hour hour) {
      if (!ts.domain.containsInterval(hour)) {
        return null;
      } else {
        var obs = ts.observationContains(hour);
        for (var bucket in obs.value.keys) {
          if (bucket.containsHour(hour)) {
            return obs.value[bucket];
          }
        }
        return null;
      }
    };
  }

  /// Construct an hourly schedule from an hourly shape.
  /// Almost an order of magnitude faster to use [hs.toHourly(interval)].
  HourlySchedule.fromHourlyShape(HourlyShape hs) {
    // go from hourBeginning value to index in bucket.hourBeginning array
    var idx = { for (var bucket in hs.data.first.value.keys) bucket :
      Map.fromIterables(bucket.hourBeginning, List.generate(bucket.hourBeginning.length, (i) => i))};
    _f = (Hour hour) {
      var ts = hs.data;
      if (!ts.domain.containsInterval(hour)) {
        return null;
      } else {
        var obs = ts.observationContains(hour);
        for (var bucket in obs.value.keys) {
          if (bucket.containsHour(hour)) {
            var ind = idx[bucket][hour.start.hour];
            return obs.value[bucket][ind];
          }
        }
        throw ArgumentError('Can\'t find the hour $hour in buckets ${obs.value.keys}');
      }
    };
  }

  /// Return the value of the schedule associated with this hour.
  num operator [](Hour hour) => _f(hour);

  /// Return the value of the schedule associated with this hour.
  num value(Hour hour) => _f(hour);

  /// Construct the hourly timeseries associated with this schedule for a
  /// given [interval].  The timeseries will have values only where the
  /// HourlySchedule is defined.
  TimeSeries<num> toHourly(Interval interval) {
    var hours = interval.splitLeft((dt) => Hour.beginning(dt));
    var out = TimeSeries<num>();
    for (var hour in hours) {
      var value = _f(hour);
      if (value != null) out.add(IntervalTuple(hour, _f(hour)));
    }
    return out;
  }

  /// Calculate a monthly statistic
  TimeSeries<num> toMonthly(Interval interval, num Function(Iterable<num>) fun) {
    var months = interval.splitLeft((dt) => Month.fromTZDateTime(dt));
    var out = TimeSeries<num>();
    for (var month in months) {
      var values = month.splitLeft((dt) => Hour.beginning(dt))
          .map((hour) => _f(hour));
      out.add(IntervalTuple(month, fun(values)));
    }
    return out;
  }

  /// A serialization format.
  Map<String, dynamic> toJson() => _toJson;
}
