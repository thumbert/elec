import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/time/shape/hourly_bucket_weights.dart';

/// Calculate the hourly shape from a historical hourly timeseries.
/// The input timeseries needs to be at least one full calendar year.
///
///
///
List<Map<Bucket, HourlyBucketWeights>> calculateHourlyShape(TimeSeries<num> x,
    {List<Bucket>? buckets}) {
  buckets ??= [
    Bucket.b5x16,
    Bucket.b2x16H,
    Bucket.b7x8,
  ];

  // calculate the average value by month [1..12] and bucket
  var bucketPrice = <(int, Bucket), num>{};
  for (var bucket in buckets) {
    var group = groupBy(x.where((e) => bucket.containsHour(e.interval as Hour)),
        (IntervalTuple e) => (e.interval.start.month, bucket));
    for (var e in group.entries) {
      bucketPrice[e.key] = mean(e.value.map((e) => e.value));
    }
  }

  // calculate the weights by month [1..12], bucket, hour of bucket
  var weights = <(int, Bucket, int), num>{};
  for (var bucket in buckets) {
    var groupHour = groupBy(
        x.where((e) => bucket.containsHour(e.interval as Hour)),
        (IntervalTuple e) =>
            (e.interval.start.month, bucket, e.interval.start.hour));
    for (var e in groupHour.entries) {
      var month = e.key.$1;
      var bucket = e.key.$2;
      weights[e.key] = mean(e.value.map((e) => e.value)) /
          bucketPrice[(month, bucket)]!;
    }
  }

  var data = List.generate(12, (i) => <Bucket, HourlyBucketWeights>{});
  var g1 = groupBy(weights.entries, (dynamic e) => e.key.$1 as int?);
  for (var month in g1.keys) {
    var g2 = groupBy(g1[month]!, (dynamic e) => e.key.$2 as Bucket);
    for (var bucket in g2.keys) {
      var weights = g2[bucket]!.map((e) => e.value);
      data[month! - 1][bucket] =
          HourlyBucketWeights(bucket, weights as List<num>);
    }
  }

  return data;
}
