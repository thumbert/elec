library time.bucket.hourly_shape;

import 'package:timezone/timezone.dart';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart';
import 'package:tuple/tuple.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/time/bucket/hourly_bucket_weights.dart';

/// Store hourly shapes by month for a set of complete buckets,
/// e.g. 5x16, 2x16H, 7x8
class HourlyShape {
  // outer list is for the 12 months
  List<Map<Bucket, HourlyWeights>> _data;

  /// Construct the hourly shape from a 12 element list containing the
  /// hourly weights for each bucket.  Usually, you don't have this input data,
  /// and you would construct it from a time series.
  HourlyShape(List<Map<Bucket, HourlyWeights>> weights) {
    _data = weights;
  }

  /// Calculate the hourly shape from a given hourly timeseries.
  ///
  HourlyShape.fromTimeSeries(TimeSeries<num> x, {List<Bucket> buckets}) {
    if (buckets == null) {
      var location = getLocation('US/Eastern');
      buckets = [
        Bucket5x16(location),
        Bucket2x16H(location),
        Bucket7x8(location),
      ];
    }

    // calculate the average value by month [1..12], bucket
    var bucketPrice = <Tuple2<int, Bucket>, num>{};
    for (var bucket in buckets) {
      var _grp = groupBy(x.where((e) => bucket.containsHour(e.interval)),
          (IntervalTuple e) => Tuple2(e.interval.start.month, bucket));
      _grp.entries.forEach((e) {
        bucketPrice[e.key] = mean(e.value.map((e) => e.value));
      });
    }

    // calculate the weights by month [1..12], bucket, hour of day [0..23]
    var weights = <Tuple3<int, Bucket, int>, num>{};
    for (var bucket in buckets) {
      var _grpHour = groupBy(
          x.where((e) => bucket.containsHour(e.interval)),
          (IntervalTuple e) =>
              Tuple3(e.interval.start.month, bucket, e.interval.start.hour));
      _grpHour.entries.forEach((e) {
        var month = e.key.item1;
        var bucket = e.key.item2;
        weights[e.key] = mean(e.value.map((e) => e.value)) /
            bucketPrice[Tuple2(month, bucket)];
      });
    }

    _data = List.generate(12, (i) => <Bucket, HourlyWeights>{});
    var g1 = groupBy(weights.entries, (e) => e.key.item1 as int);
    for (int month in g1.keys) {
      var g2 = groupBy(g1[month], (e) => e.key.item2 as Bucket);
      for (Bucket bucket in g2.keys) {
        var weights = g2[bucket].map((e) => e.value);
        _data[month - 1][bucket] = HourlyWeights(bucket, weights);
      }
    }
  }

  /// Construct an hourly shape from a List, each element is a Map
  /// with keys 'bucket' and 'weights'.  Weights is a
  /// 12 element List of List<num> with the weights for all months.
  ///
  HourlyShape.fromJson(List<Map<String, dynamic>> xs) {
    _data = List.filled(12, <Bucket, HourlyWeights>{});
    for (var x in xs) {
      var bucket = Bucket.parse(x['bucket']);
      var weights = (x['weights'] as List).cast<List<num>>();
      for (var m = 0; m < weights.length; m++) {
        _data[m][bucket] = HourlyWeights(bucket, weights[m]);
      }
    }
  }

  /// Return the hourly weight of this bucket, this hourEnding for the month.
  num value(int month, Bucket bucket, int hourEnding) {
    return _data[month - 1][bucket].value(hourEnding);
  }

  Map<Bucket, HourlyWeights> valuesForMonth(int month) {
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
        out[b]['weights'].add(_data[m][buckets[b]].weights.toList());
      }
    }
    return out;
  }
}

/// Calculate the hourly shape by month for a bucket.
/// The input timeseries needs to be hourly frequency.
/// The return is a monthly timeseries of hourly weights.
TimeSeries<HourlyWeights> hourlyShapeByYearMonth(
    TimeSeries<num> x, Bucket bucket) {
  var xh = x.splitByIndex((e) => Month.fromTZDateTime(e.start));

  var out = TimeSeries<HourlyWeights>();
  for (var month in xh.keys) {
    var hs = HourlyShape.fromTimeSeries(xh[month], buckets: [bucket]);
    var hsm = hs.valuesForMonth(month.month);
    out.add(IntervalTuple(month, hsm[bucket]));
  }

  return TimeSeries.fromIterable(out);
}
