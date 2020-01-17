library time.bucket.hourly_bucket_weights;

import 'package:date/date.dart';

import '../bucket/bucket.dart';

/// The hourly weights for a given bucket.
/// Usually associated with a given month of the year, as each month of the
/// year has different hourly weights.
///
/// Additional customization can be achieved if is associated with a
/// particular calendar month.
class HourlyBucketWeights {
  Bucket bucket;
  Map<int, num> _values;

  /// Store the weights for the given time [bucket], as a list of numbers with
  /// an average of 1.  This class is used when dealing with [HourlyShape].
  ///
  /// A value is given for each hour in the bucket, e.g. there will be 8 values
  /// for the 7x8 bucket.
  HourlyBucketWeights(this.bucket, List<num> values) {
    if (values.length != bucket.hourBeginning.length) {
      throw ArgumentError('Number of weights don\'t match the number of hours in bucket');
    }
    _values = Map.fromIterables(bucket.hourBeginning, values);
  }

  num value(Hour hour) => _values[hour.start.hour];

  /// get the hourly weights
  Iterable<num> get weights => _values.values;

  /// A map from hour ending -> weight
  Map<int, num> toMap() => _values;

  @override
  String toString() => toMap().toString();
}

