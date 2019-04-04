library time.bucket.hourly_bucket_weights;

import 'bucket.dart';

/// The hourly weights for a given bucket
class HourlyWeights {

  Bucket bucket;
  Map<int,num> _values;

  /// Weights for the given [bucket], as a list of numbers that add up to 1.
  HourlyWeights(this.bucket, List<num> values) {
    if (values.length != bucket.hourEnding.length)
      throw ArgumentError('Input weights for bucket $bucket should have exactly ${bucket.hourEnding.length} values');
    _values = Map.fromIterables(bucket.hourEnding, values);
  }

  num value(int hourEnding) => _values[hourEnding];

  /// A map from hour ending -> weight
  Map<int,num> toMap() => _values;

}





//class Weights7x8 implements HourlyWeights {
//  List<num> _values;
//  static final hourEnding = <int>[1, 2, 3, 4, 5, 6, 7, 24];
//
//  /// Weights for the 7x8 bucket, as 8 numbers that add up to 1.
//  ///
//  Weights7x8(List<num> values) {
//    if (values.length != 8)
//      throw ArgumentError('Input weights for 7x8 bucket should have exactly 8 values');
//    _values = values;
//  }
//
//  num value(int hourEnding) {
//    if (hourEnding >= 8 && hourEnding < 24)
//      throw ArgumentError('Invalid hourEnding $hourEnding for bucket 7x8');
//    if (hourEnding < 8) return _values[hourEnding-1];
//    else return _values.last;
//  }
//
//  /// A map from hour ending -> weight
//  Map<int,num> toMap() {
//    return Map.fromIterables(hourEnding, _values);
//  }
//}

