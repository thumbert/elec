library risk_system.marks.mark;

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

  bool operator ==(dynamic other) {
    if (other is! MonthBucketValue) return false;
    MonthBucketValue x = other;
    return x.value == value && x.bucket == bucket && x.month == month;
  }

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
