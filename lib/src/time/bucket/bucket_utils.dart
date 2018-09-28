library time.bucket.bucket_utils;

import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'bucket.dart';

/// Split the observations of timeseries [x] into other timeseries such that
/// each of these timeseries have intervals in a corresponding bucket.
/// Only one traversal of [x] is made.  Works for hourly and sub-hourly
/// timeseries.  The [buckets] don't need to be exclusive.  If no observations
/// fall in a given [bucket], that bucket is removed from the output.
Map<Bucket, List<IntervalTuple>> splitByBucket(
    Iterable<IntervalTuple> x, List<Bucket> buckets) {
  Map<Bucket, List<IntervalTuple>> res = new Map.fromIterables(
      buckets, new List.generate(buckets.length, (i) => []));

  x.forEach((IntervalTuple e) {
    buckets.forEach((Bucket bucket) {
      if (bucket.containsHour(new Hour.beginning(e.interval.start)))
        res[bucket].add(e);
    });
  });

  /// remove empty buckets, if any
  List emptyBuckets = [];
  res.forEach((k, List v) {
    if (v.isEmpty) emptyBuckets.add(k);
  });
  emptyBuckets.forEach((bucket) => res.remove(bucket));

  return res;
}