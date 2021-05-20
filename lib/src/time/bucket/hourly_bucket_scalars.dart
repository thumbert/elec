library time.bucket.hourly_bucket_scalars;

import 'package:date/date.dart';
import 'bucket.dart';

class HourlyBucketScalars {
  Bucket bucket;
  List<num> values;
  late Map<int,num> _values;

  /// A list of numbers associated with each hour of a given bucket.
  /// This class is used when dealing with an [HourlySchedule].
  ///
  /// A value is given for each hour in the bucket, e.g. there will be 8 values
  /// for the 7x8 bucket.
  HourlyBucketScalars(this.bucket, this.values) {
    if (values.length != bucket.hourBeginning.length) {
      throw ArgumentError('Number of scalars don\'t match the number of hours in bucket');
    }
    _values = Map.fromIterables(bucket.hourBeginning, values);
  }

  num? operator [](Hour hour) => _values[hour.start.hour];
}

