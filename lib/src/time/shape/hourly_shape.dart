library time.bucket.hourly_shape;

import 'package:timezone/timezone.dart';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart';
import 'package:tuple/tuple.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/time/shape/hourly_bucket_weights.dart';

/// Store hourly shapes by month for a set of complete buckets,
/// e.g. 5x16, 2x16H, 7x8.
/// NEEDS REVIEW 11/25/2019
class HourlyShape {

  /// the covering buckets
  List<Bucket> buckets;

  /// The outer list is for the 12 months, the inner list is for the buckets
  List<Map<Bucket, HourlyBucketWeights>> _data;

  /// Construct the hourly shape from a 12 element list containing the
  /// hourly weights for each bucket.
  HourlyShape.byMonth(List<Map<Bucket, HourlyBucketWeights>> weights) {
    if (weights.length != 12) {
      throw ArgumentError('Input weights has ${weights.length} instead of 12.');
    }
    buckets = weights.first.keys.toList(growable: false);
    _data = weights;
  }


  /// Construct an hourly shape from a List, each element is a Map
  /// with keys 'bucket' and 'weights'.  Weights is a
  /// 12 element List of List<num> with the weights for all months.
  ///
  HourlyShape.fromJson(List<Map<String, dynamic>> xs) {
    _data = List.filled(12, <Bucket, HourlyBucketWeights>{});
    for (var x in xs) {
      var bucket = Bucket.parse(x['bucket']);
      var weights = (x['weights'] as List).cast<List<num>>();
      for (var m = 0; m < weights.length; m++) {
        _data[m][bucket] = HourlyBucketWeights(bucket, weights[m]);
      }
    }
  }

  /// Return the hourly weight of this bucket, this hourBeginning for the month.
//  num value(int month, Bucket bucket, int hourBeginning) {
//    var hourlyBucketWeight = _data[month - 1][bucket];
//    return hourlyBucketWeight.value(Hour.beginning(start)hourBeginning);
//  }

  Map<Bucket, HourlyBucketWeights> valuesForMonth(int month) {
    return _data[month - 1];
  }

  /// Format the data for serialization to Mongo.  The output list has 3
  /// elements, each for one bucket.
  List<Map<String, dynamic>> toJson() {
    var buckets = _data.first.keys.toList();
    var nBuckets = buckets.length; // 3

    var out = List.generate(nBuckets, (i) => <String, dynamic>{});
    for (var b = 0; b < nBuckets; b++) {
      out[b]['bucket'] = buckets[b].name;
      out[b]['weights'] = <List<num>>[];
    }

    for (var m = 0; m < 12; m++) {
      for (var b = 0; b < nBuckets; b++) {
        out[b]['weights'].addBucket(_data[m][buckets[b]].weights.toList());
      }
    }
    return out;
  }
}


