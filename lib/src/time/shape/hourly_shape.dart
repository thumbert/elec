library time.bucket.hourly_shape;

import 'package:elec/src/time/bucket/bucket_utils.dart';
import 'package:intl/intl.dart';
import 'package:table/table.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';

/// Store hourly shapes by month for a set of complete buckets,
/// e.g. 5x16, 2x16H, 7x8.
class HourlyShape {
  /// the covering buckets
  List<Bucket> buckets;

  /// Monthly timeseries.  The values for the bucket keys are the shaping
  /// factors for the hours in that bucket (sorted by hour beginning).
  TimeSeries<Map<Bucket, List<num>>> data;

  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

  HourlyShape();

  /// Input [ts] is an hourly timeseries.
  HourlyShape.fromTimeSeries(TimeSeries<num> ts, this.buckets) {
    // calculate the average by month/bucket/hour
    var nest = Nest()
      ..key((IntervalTuple e) => Month.fromTZDateTime(e.interval.start))
      ..key((IntervalTuple e) => assignBucket(e.interval, buckets))
      ..key((IntervalTuple e) => e.interval.start.hour)
      ..rollup((List xs) => mean(xs.map((e) => e.value)));
    var aux = nest.map(ts);
    var avg = flattenMap(aux, ['month', 'bucket', 'hourBeginning', 'value']);

    // calculate the shaping factors
    var nest2 = Nest()
      ..key((e) => e['month'])
      ..key((e) => e['bucket'])
      ..rollup((List xs) {
        var avg = mean(xs.map((e) => e['value'] as num));
        return xs.map((e) => e['value'] / avg).toList();
      });
    var bux = nest2.map(avg);

    data = TimeSeries<Map<Bucket, List<num>>>();
    for (var month in bux.keys) {
      var kv = {
        for (var entry in (bux[month] as Map).entries)
          entry.key as Bucket: (entry.value as List).cast<num>()
      };
      data.add(IntervalTuple(month, kv));
    }
  }

  /// The opposite of [toJson] method.
  HourlyShape.fromJson(Map<String,dynamic> x, Location location) {
    if (!x.keys.toSet().containsAll({'terms', 'buckets'})) {
      throw ArgumentError('Missing one of keys: terms, buckets.');
    }
    var _buckets = (x['buckets'] as Map).keys;
    var months = (x['terms'] as List).cast<String>();
    var aux = x['buckets'] as Map;
    buckets = _buckets.map((e) => Bucket.parse(e)).toList();
    data = TimeSeries<Map<Bucket, List<num>>>();
    for (var i=0; i<months.length; i++) {
      var month = Month.parse(months[i], fmt: _isoFmt, location: location);
      var value = <Bucket,List<num>>{};
      for (var _bucket in _buckets) {
        value[Bucket.parse(_bucket)] = aux[_bucket][i];
      }
      data.add(IntervalTuple(month, value));
    }
  }


  /// Format the data for serialization to Mongo.
  ///{
  ///  "terms": [
  ///    "2020-01",
  ///    "2020-02",
  ///    "2020-03"],
  ///  "buckets": {
  ///     "7x8": [[...], [...], [...]],
  ///     "5x16": [[...], [...], [...]],
  ///     "2x16H": [[...], [...], [...]],
  ///  }
  Map<String, dynamic> toJson() {
    var out = <String, dynamic>{
      'terms': <String>[],
      'buckets': <String, dynamic>{},
    };
    for (var x in data) {
      (out['terms'] as List).add((x.interval as Month).toIso8601String());
      for (var bucket in x.value.keys) {
        if (!(out['buckets'] as Map).containsKey(bucket.toString())) {
          out['buckets'][bucket.toString()] = [];
        }
        (out['buckets'][bucket.toString()] as List).add(x.value[bucket]);
      }
    }
    return out;
  }
}
