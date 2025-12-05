import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:quiver/core.dart';
import 'package:timeseries/timeseries.dart';

class MonthBucketValue {
  Month month;
  Bucket bucket;
  num value;

  /// The equivalent of a triple (month, bucket, value).
  MonthBucketValue(this.month, this.bucket, this.value);

  /// Add another MonthBucketValue to this.
  num addBucket(MonthBucketValue other) {
    if (other.bucket == bucket) {
      throw ArgumentError('The two buckets need to be different');
    }
    if (other.month != month) {
      throw ArgumentError('The two months need to be the same');
    }

    var hrs = bucket.countHours(month);
    var hrsOther = other.bucket.countHours(other.month);

    return (value * hrs + other.value * hrsOther) / (hrs + hrsOther);
  }

  /// Subract another MonthBucketValue from this.
  num subtractBucket(MonthBucketValue other) {
    if (other.bucket == bucket) {
      throw ArgumentError('The two buckets need to be different');
    }
    if (other.month != month) {
      throw ArgumentError('The two months need to be the same');
    }
    var hrs = bucket.countHours(month);
    var hrsOther = other.bucket.countHours(other.month);
    if (hrs <= hrsOther) {
      throw ArgumentError('Can\'t subtract $bucket from ${other.bucket}');
    }

    return (value * hrs - other.value * hrsOther) / (hrs - hrsOther);
  }

  @override
  bool operator ==(Object other) {
    if (other is! MonthBucketValue) return false;
    MonthBucketValue x = other;
    return x.value == value && x.bucket == bucket && x.month == month;
  }

  @override
  int get hashCode => hash3(bucket, month, value);

  TimeSeries<num> toHourly() {
    var hours = month.splitLeft((dt) => Hour.beginning(dt));
    var out = TimeSeries<num>();
    for (var hour in hours) {
      if (bucket.containsHour(hour)) out.add(IntervalTuple(hour, value));
    }
    return out;
  }
}
