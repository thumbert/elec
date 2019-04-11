library time.bucket.bucket_utils;

import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'bucket.dart';


/// Split the observations of timeseries [x] into other timeseries such that
/// each of these timeseries have intervals in a corresponding bucket.
/// Only one traversal of [x] is made.  Works for hourly and sub-hourly
/// timeseries.  The [buckets] don't need to be exclusive.  If no observations
/// fall in a given [bucket], that bucket is removed from the output.
Map<Bucket, List<IntervalTuple<K>>> splitByBucket<K>(Iterable<IntervalTuple<K>> x,
    List<Bucket> buckets) {
  var res = Map.fromIterables(
      buckets, List.generate(buckets.length, (i) => <IntervalTuple<K>>[]));

  x.forEach((e) {
    buckets.forEach((bucket) {
      if (bucket.containsHour(Hour.beginning(e.interval.start)))
        res[bucket].add(e);
    });
  });

  /// remove empty buckets, if any
  var emptyBuckets = <Bucket>[];
  res.forEach((k, List v) {
    if (v.isEmpty) emptyBuckets.add(k);
  });
  emptyBuckets.forEach((bucket) => res.remove(bucket));

  return res;
}
