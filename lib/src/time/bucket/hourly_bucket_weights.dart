library time.bucket.hourly_bucket_weights;

import 'bucket.dart';

/// The hourly weights for a given bucket.
class HourlyWeights {
  Bucket bucket;
  Map<int, num> _values;

  /// Weights for the given [bucket], as a list of numbers with an average of 1.
  /// A value is given for each hour in the bucket, e.g. there will be 8 values
  /// for the 7x8 bucket.  This will work even for the Offpeak bucket.
  ///
  HourlyWeights(this.bucket, List<num> values) {
    if (values.length != bucket.hourEnding.length)
      throw ArgumentError(
          'Input weights for bucket $bucket should have exactly ${bucket.hourEnding.length} values');
    _values = Map.fromIterables(bucket.hourEnding, values);
  }

  num value(int hourEnding) => _values[hourEnding];

  /// A map from hour ending -> weight
  Map<int, num> toMap() => _values;
}

