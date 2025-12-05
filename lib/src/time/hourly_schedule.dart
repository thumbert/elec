import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';
import 'package:timeseries/timeseries.dart';

abstract class HourlySchedule {
  HourlySchedule();

  /// Construct a time schedule which returns different values based on the
  /// bucket. For example all Peak hours value is 100, all Offpeak hours
  /// value is 80.  Note that the bucket covering doesn't need to be complete.
  factory HourlySchedule.byBucket(Map<Bucket, num> values) {
    return _HourlyScheduleByBucket(values);
  }

  /// Construct a time schedule which returns different values based on the
  /// bucket and the month of the year.
  ///
  /// Note that not all months of the year need to be defined, or the bucket
  /// covering to be complete.
  ///
  /// Note that by using a custom bucket definition, you can restrict the
  /// HourlySchedule to whatever hours of the day you are interested.
  factory HourlySchedule.byBucketMonth(Map<Bucket, Map<int, num>> values) {
    return _HourlyScheduleByBucketMonth(values);
  }

  /// Construct an hourly schedule which returns different values based on the
  /// month of the year.  All hours of the month will have the same value.
  /// Note that not all months of the year need to be defined.
  factory HourlySchedule.byMonth(Map<int, num> values) {
    return _HourlyScheduleByMonth(values);
  }

  /// Construct an infinitely long schedule, same value for all hours.
  factory HourlySchedule.filled(num value) {
    return HourlyScheduleFilled(value);
  }

  /// Create an hourly schedule from a timeseries.  No intra-bucket shaping.
  /// For example the input timeseries can be monthly.
  /// Works even if the bucket covering is not complete.
  factory HourlySchedule.fromForwardCurve(PriceCurve forwardCurve) {
    return _HourlyScheduleFromForwardCurve(forwardCurve);
  }

  /// Create an hourly schedule from a timeseries.
  /// The input timeseries can have any periodicity higher than hourly.
  factory HourlySchedule.fromTimeSeries(TimeSeries<num> timeSeries) {
    return _HourlyScheduleFromTimeSeries(timeSeries);
  }

  /// Construct an hourly schedule from an hourly shape.
  factory HourlySchedule.fromHourlyShape(HourlyShape hourlyShape) {
    return _HourlyScheduleFromHourlyShape(hourlyShape);
  }

  /// return the value in this hour, or [null] if the schedule is not defined
  /// for the hour.
  late num? Function(Hour) _f;

  /// Return the value of the schedule associated with this hour.
  num? operator [](Hour hour) => _f(hour);

  /// Return the value of the schedule associated with this hour.
  num? valueAt(Hour hour) => _f(hour);

  /// Default implementation.  May not be the fastest.
  /// Construct the hourly timeseries associated with this schedule for a
  /// given [interval].  The timeseries will have values only where the
  /// HourlySchedule is defined.
  TimeSeries<num> toHourly(Interval interval) {
    var hours = interval.splitLeft((dt) => Hour.beginning(dt));
    var out = TimeSeries<num>();
    for (var hour in hours) {
      var value = _f(hour);
      if (value != null) out.add(IntervalTuple(hour, value));
    }
    return out;
  }

  Map<String, dynamic> toJson();
}

class _HourlyScheduleByBucket extends HourlySchedule {
  /// Construct a time schedule which returns different values based on the
  /// bucket. For example all Peak hours value is 100, all Offpeak hours
  /// value is 80.  Note that the bucket covering doesn't need to be complete.
  _HourlyScheduleByBucket(this.values) {
    _f = (Hour hour) {
      for (var bucket in values.keys) {
        if (bucket.containsHour(hour)) return values[bucket];
      }
      return null;
    };
  }

  final Map<Bucket, num> values;

  @override
  Map<String, dynamic> toJson() {
    var out = <Map<String, dynamic>>[];
    for (var bucket in values.keys) {
      out.add({
        'bucket': bucket.toString(),
        'value': values[bucket],
      });
    }
    return {
      'type': 'HourlySchedule.byBucket',
      'values': out,
    };
  }
}

class _HourlyScheduleByBucketMonth extends HourlySchedule {
  /// Construct a time schedule which returns different values based on the
  /// bucket and the month of the year.
  ///
  /// Note that not all months of the year need to be defined, or the bucket
  /// covering to be complete.
  ///
  /// Note that by using a custom bucket definition, you can restrict the
  /// HourlySchedule to whatever hours of the day you are interested.
  _HourlyScheduleByBucketMonth(this.values) {
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
  }

  final Map<Bucket, Map<int, num>> values;

  @override
  Map<String, dynamic> toJson() {
    var out = <Map<String, dynamic>>[];
    for (var bucket in values.keys) {
      for (var month in values[bucket]!.keys) {
        out.add({
          'bucket': bucket.toString(),
          'month': month,
          'value': values[bucket]![month],
        });
      }
    }
    return {
      'type': 'HourlySchedule.byBucketMonth',
      'values': out,
    };
  }
}

class _HourlyScheduleByMonth extends HourlySchedule {
  /// Construct a time schedule which returns different values based on the
  /// month of the year.  All hours of the month will have the same value.
  /// Note that not all months of the year need to be defined.
  _HourlyScheduleByMonth(this.values) {
    _f = (Hour e) {
      return values[e.start.month];
    };
  }

  final Map<int, num> values;

  @override
  Map<String, dynamic> toJson() {
    var out = <Map<String, dynamic>>[];
    for (var month in values.keys) {
      out.add({
        'month': month,
        'value': values[month],
      });
    }
    return {
      'type': 'byMonth',
      'values': out,
    };
  }
}

class HourlyScheduleFilled extends HourlySchedule {
  HourlyScheduleFilled(this.value) {
    _f = (Hour e) => value;
  }
  final num value;

  @override
  TimeSeries<num> toHourly(Interval interval) {
    var hours = interval.splitLeft((dt) => Hour.beginning(dt));
    return TimeSeries.fill(hours, value);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'HourlySchedule.filled',
        'values': value,
      };
}

class _HourlyScheduleFromHourlyShape extends HourlySchedule {
  _HourlyScheduleFromHourlyShape(this.hourlyShape) {
    // go from hourBeginning value to index in bucket.hourBeginning array
    var idx = {
      for (var bucket in hourlyShape.data.first.value.keys)
        bucket: Map.fromIterables(bucket.hourBeginning,
            List.generate(bucket.hourBeginning.length, (i) => i))
    };
    _f = (Hour hour) {
      var ts = hourlyShape.data;
      if (!ts.domain.containsInterval(hour)) {
        return null;
      } else {
        var obs = ts.observationContains(hour);
        for (var bucket in obs.value.keys) {
          if (bucket.containsHour(hour)) {
            var ind = idx[bucket]![hour.start.hour]!;
            return obs.value[bucket]![ind];
          }
        }
        throw ArgumentError(
            'Can\'t find the hour $hour in buckets ${obs.value.keys}');
      }
    };
  }

  final HourlyShape hourlyShape;

  @override
  TimeSeries<num> toHourly(Interval interval) {
    return hourlyShape.toHourly(interval: interval);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'HourlySchedule.fromHourlyShape',
        'values': hourlyShape.toJson(),
      };
}

class _HourlyScheduleFromForwardCurve extends HourlySchedule {
  _HourlyScheduleFromForwardCurve(this.forwardCurve) {
    _f = (Hour hour) {
      if (!forwardCurve.domain.containsInterval(hour)) {
        return null;
      } else {
        IntervalTuple<Map<Bucket, num?>?> obs =
            forwardCurve.observationContains(hour);
        for (var bucket in obs.value!.keys) {
          if (bucket.containsHour(hour)) {
            return obs.value![bucket];
          }
        }
        return null;
      }
    };
  }

  final PriceCurve forwardCurve;

  @override
  TimeSeries<num> toHourly(Interval interval) {
    return TimeSeries.fromIterable(forwardCurve.toHourly().window(interval));
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'HourlySchedule.fromForwardCurve',
        'values': forwardCurve.toJson(),
      };
}

class _HourlyScheduleFromTimeSeries extends HourlySchedule {
  _HourlyScheduleFromTimeSeries(this.ts) {
    _f = (Hour hour) {
      try {
        var obs = ts.observationContains(hour);
        return obs.value;
      } catch (e) {
        return null;
      }
    };
  }

  final TimeSeries<num> ts;

  @override
  TimeSeries<num> toHourly(Interval interval) {
    return TimeSeries.fromIterable(
        ts.interpolate(Duration(hours: 1)).window(interval));
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'HourlySchedule.fromTimeSeries',
        'values': ts.toJson(),
      };
}
