library time.bucket.hourly_shape;

import 'package:elec/risk_system.dart';
import 'package:elec/src/time/bucket/bucket_utils.dart';
import 'package:table/table.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart' as dama;
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';

/// Store hourly shapes by month for a set of complete buckets,
/// e.g. 5x16, 2x16H, 7x8.
class HourlyShape extends Object with MarksCurve {
  /// Monthly timeseries.  The values for the bucket keys are the shaping
  /// factors for the hours in that bucket (sorted by hour beginning).  Note
  /// that for most buckets the sum of the List elements will add up to the
  /// numbers of hours in the bucket.  It is not the case for 7x8, in Mar and
  /// Nov because of DST.
  late TimeSeries<Map<Bucket, List<num>>> data;

  HourlyShape();

  /// Construct the shaping factors from an hourly timeseries.
  HourlyShape.fromTimeSeries(TimeSeries<num> ts, Set<Bucket> buckets) {
    this.buckets = buckets;
    // calculate the average by month/bucket/hourBeginning
    var bucketsL = buckets.toList();
    var nest = Nest()
      ..key((IntervalTuple e) => Month.containing(e.interval.start))
      ..key((IntervalTuple e) => assignBucket(e.interval as Hour, bucketsL))
      ..key((IntervalTuple e) => e.interval.start.hour)
      ..rollup((List xs) => dama.mean(xs.map(((e) => e.value as num))));
    var aux = nest.map(ts);
    var avg = flattenMap(
        aux, ['month', 'bucket', 'hourBeginning', 'averageValueForHour'])!;

    // calculate the average price by month/bucket
    var nestB = Nest()
      ..key((IntervalTuple e) => Month.containing(e.interval.start))
      ..key((IntervalTuple e) => assignBucket(e.interval as Hour, bucketsL))
      ..rollup((List xs) {
        return dama.mean(xs.map(((e) => e.value as num)));
      });
    var avgPrice0 = nestB.map(ts);
    var avgPrice = flattenMap(avgPrice0, ['month', 'bucket', 'averageValue'])!;

    // join them (by bucket/month) to calculate the shaping factor
    var xs = join(avg, avgPrice);
    var nest2 = Nest()
      ..key((e) => e['month'])
      ..key((e) => e['bucket'])
      ..rollup((List xs) {
        xs.sort((a, b) => a['hourBeginning'].compareTo(b['hourBeginning']));
        return xs
            .map((e) => e['averageValueForHour'] / e['averageValue'])
            .toList();
      });
    var bux = nest2.map(xs);

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
  ///```
  ///{
  ///  "terms": [
  ///    "2020-01",
  ///    "2020-02",
  ///    "2020-03"],
  ///  "buckets": {
  ///     "7x8": [[...], [...], [...]],
  ///     "5x16": [[...], [...], [...]],
  ///     "2x16H": [[...], [...], [...]],
  /// }
  /// ```
  HourlyShape.fromJson(Map<String, dynamic> x, Location location) {
    if (!x.keys.toSet().containsAll({'terms', 'buckets'})) {
      throw ArgumentError('Missing one of keys: terms, buckets.');
    }
    var bucketsS = (x['buckets'] as Map).keys;
    var months = (x['terms'] as List).cast<String>();
    var aux = x['buckets'] as Map;
    buckets = bucketsS.map((e) => Bucket.parse(e)).toSet();
    data = TimeSeries<Map<Bucket, List<num>>>();
    for (var i = 0; i < months.length; i++) {
      var month = Month.parse(months[i], location: location);
      var value = <Bucket, List<num>>{};
      for (var bucket in bucketsS) {
        value[Bucket.parse(bucket)] = (aux[bucket][i] as List).cast<num>();
      }
      data.add(IntervalTuple(month, value));
    }
  }

  TimeSeries<num> toHourly({Interval? interval}) {
    interval ??= data.domain;
    var ts = TimeSeries<num>();
    // need to extend the interval to make sure it matches the data boundaries
    var extInterval = Interval(Month.containing(interval.start).start,
        Month.containing(interval.end.subtract(Duration(seconds: 1))).end);
    var xs = data.window(extInterval);
    // assume same buckets for all observations
    // keep buckets in the order below for faster containsHour test
    final buckets = [Bucket.b5x16, Bucket.b7x8, Bucket.b2x16H];

    // go from hourBeginning value to index in bucket.hourBeginning array
    final idx = {
      for (var bucket in buckets)
        bucket: Map.fromIterables(bucket.hourBeginning,
            List.generate(bucket.hourBeginning.length, (i) => i))
    };
    for (var x in xs) {
      var hours = x.interval.splitLeft((dt) => Hour.beginning(dt));
      late num value;
      for (var hour in hours) {
        for (var bucket in buckets) {
          if (bucket.containsHour(hour)) {
            var ind = idx[bucket]![hour.start.hour]!;
            value = x.value[bucket]![ind];
            break; // the bucket for loop
          }
        }
        if (interval.containsInterval(hour)) {
          ts.add(IntervalTuple(hour, value));
        }
      }
    }

    return ts;
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

  /// Truncate this hourly shape to this [interval].
  void window(Interval interval) {
    data = TimeSeries.fromIterable(data.window(interval));
  }

  @override
  Map<String, dynamic> toMongoDocument(Date fromDate, String curveId) {
    return {
      'fromDate': fromDate.toString(),
      'curveId': curveId,
      ...toJson(),
    };
  }

}
