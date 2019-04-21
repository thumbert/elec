library time.bucket.hourly_bucket_weights;

import 'bucket.dart';

/// The hourly weights for a given bucket.
class HourlyWeights {
  Bucket bucket;
  Map<int, num> _values;

  /// Store the weights for the given time [bucket], as a list of numbers with
  /// an average of 1.  This class is used when dealing with [HourlyShape].
  ///
  /// A value is given for each hour in the bucket, e.g. there will be 8 values
  /// for the 7x8 bucket.  This will work even for the Offpeak bucket.
  ///
  HourlyWeights(this.bucket, Iterable<num> values) {
    _values = Map.fromIterables(bucket.hourEnding, values);
  }

  num value(int hourEnding) => _values[hourEnding];

  /// get the hourly weights
  Iterable<num> get weights => _values.values;

  /// A map from hour ending -> weight
  Map<int, num> toMap() => _values;

  String toString() => toMap().toString();
}

