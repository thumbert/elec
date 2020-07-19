library time.bucket.hourly_shape;

import 'package:elec/src/time/bucket/bucket_utils.dart';
import 'package:intl/intl.dart';
import 'package:table/table.dart';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart' as dama;
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';

/// Store hourly shapes by month for a set of complete buckets,
/// e.g. 5x16, 2x16H, 7x8.
class HourlyShape {
  /// the covering buckets
  List<Bucket> buckets;

  /// Monthly timeseries.  The values for the bucket keys are the shaping
  /// factors for the hours in that bucket (sorted by hour beginning).  Note
  /// that for most buckets the sum of the List elements will add up to the
  /// numbers of hours in the bucket.  It is not the case for 7x8, in Mar and
  /// Nov because of DST.
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
      ..rollup((List xs) => dama.mean(xs.map((e) => e.value)));
    var aux = nest.map(ts);
    var avg = flattenMap(aux, ['month', 'bucket', 'hourBeginning', 'value']);

    // calculate the shaping factors
    // Need to pay attention on the DST transitions.  For example: in Mar there
    // will be 31 hours beginning 0, 1; but only 30 yours beginning 2.
    var nest2 = Nest()
      ..key((e) => e['month'])
      ..key((e) => e['bucket'])
      ..rollup((List xs) {
        // In case the input [ts] has missing data, count the number of hours
        // in this month by hourBeginning to do the correct averaging.
        // Need to sort the count by hourBeginning.
        var hours = Term.fromInterval(xs.first['month']).hours()
            .where((hour) => (xs.first['bucket'] as Bucket).containsHour(hour));
        var aux = groupBy(hours, (Hour e) => e.start.hour);
        var count = [ for(var k in aux.keys) [k, aux[k].length]];
        count.sort((a,b) => a[0].compareTo(b[0]));
        // now do the scaling
        var avg = dama.weightedMean(xs.map((e) => e['value'] as num),
            count.map((e) => e[1]));
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
        value[Bucket.parse(_bucket)] = (aux[_bucket][i] as List).cast<num>();
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
