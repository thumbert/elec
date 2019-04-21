library time.bucket.hourly_shape;

import 'package:timezone/standalone.dart';
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

  /// Calculate the hourly shape from a given timeseries.
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

    // the average by month, bucket
    var bucketPrice = <Tuple2<int, Bucket>, num>{};
    var grp = x.splitByIndex((hour) {
      var bucket = buckets.firstWhere((bucket) => bucket.containsHour(hour));
      return Tuple2(hour.start.month, bucket);
    });
    grp.entries.forEach((e) {
      bucketPrice[e.key] = mean(e.value.values);
    });

    // the weights by month, bucket, hour of day
    var weights = <Tuple3<int, Bucket, int>, num>{};
    var grpHour = x.splitByIndex((hour) {
      var bucket = buckets.firstWhere((bucket) => bucket.containsHour(hour));
      return Tuple3(hour.start.month, bucket, hour.start.hour);
    });
    grpHour.entries.forEach((e) {
      var month = e.key.item1;
      var bucket = e.key.item2;
      weights[e.key] =
          mean(e.value.values) / bucketPrice[Tuple2(month, bucket)];
    });

    _data = List.generate(12, (i) => <Bucket, HourlyWeights>{});
    var g1 = groupBy(weights.entries, (e) => e.key.item1 as int);
    g1.entries.forEach((e) {
      var month = e.key;
      var g2 = groupBy(e.value, (e) => e.key.item2 as Bucket);
      g2.entries.forEach((f) {
        var bucket = f.key;
        var weights = f.value.map((g) => g.value);
        _data[month - 1][bucket] = HourlyWeights(bucket, weights);
      });
    });
  }

  /// Construct an hourly shape from a 3 element List, each element is a Map
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

/// Calculate the hourly shape by year, month and Weekday / Weekend & Holiday
/// The input timeseries needs to be hourly frequency.
TimeSeries<Map<String, HourlyWeights>> hourlyShapeByYearMonthDayType(
    TimeSeries<num> x) {
  var location = x.first.interval.start.location;
  var buckets = [
      Bucket5x16(location),
      Bucket2x16H(location),
      Bucket7x8(location),
  ];

  // split the timeseries into year chunks
  var xh = x.splitByIndex((e) => e.start.year);
  var months = List.generate(12, (i) => i + 1);


  var aux = <IntervalTuple<Map<String,HourlyWeights>>>[];
  for (var year in xh.keys) {
    print('year: $year');
    var hs = HourlyShape.fromTimeSeries(xh[year], buckets: buckets);
    for (var month in months) {
      print('month: $month');
      var hsm = hs.valuesForMonth(month);
      var w7x8 = hsm[Bucket7x8(location)].weights;
      var w2x16H = hsm[Bucket2x16H(location)].weights;
      var w5x16 = hsm[Bucket5x16(location)].weights;
      var y = <String, HourlyWeights>{
        'Weekday': HourlyWeights(
            Bucket7x24(location), <num>[]..addAll(w7x8)..addAll(w5x16)),
        'Weekend/Holiday': HourlyWeights(
            Bucket7x24(location), <num>[]..addAll(w7x8)..addAll(w2x16H)),
      };
      aux.add(IntervalTuple(Month(year, month, location: location), y));
    }
  }

  return TimeSeries.fromIterable(aux);
}
