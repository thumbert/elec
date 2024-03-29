library time.bucket.bucket_utils;

import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'bucket.dart';
import 'package:elec/src/time/calendar/calendar.dart';

/// Assign this [hour] to a bucket.
Bucket assignBucket(Hour hour, List<Bucket> buckets) {
  for (var bucket in buckets) {
    if (bucket.containsHour(hour)) return bucket;
  }
  throw ArgumentError('Bucket list is not complete for $hour');
}

/// Calculate if this day is a Peak day
bool isPeakDay(Date x, Calendar calendar) {
  var aux = x.weekday == 6 || x.weekday == 7 || calendar.isHoliday(x);
  return !aux;
}

/// Split the observations of timeseries [x] into other timeseries such that
/// each of these timeseries have intervals in a corresponding bucket.
/// Only one traversal of [x] is made.  Works for hourly and sub-hourly
/// timeseries.  The [buckets] don't need to be exclusive.  If no observations
/// fall in a given [bucket], that bucket is removed from the output.
Map<Bucket, List<IntervalTuple<K>>> splitByBucket<K>(
    Iterable<IntervalTuple<K>> x, List<Bucket> buckets) {
  var res = Map.fromIterables(
      buckets, List.generate(buckets.length, (i) => <IntervalTuple<K>>[]));

  for (var e in x) {
    for (var bucket in buckets) {
      if (bucket.containsHour(Hour.beginning(e.interval.start))) {
        res[bucket]!.add(e);
      }
    }
  }

  /// remove empty buckets, if any
  var emptyBuckets = <Bucket>[];
  res.forEach((k, List v) {
    if (v.isEmpty) emptyBuckets.add(k);
  });
  for (var bucket in emptyBuckets) {
    res.remove(bucket);
  }

  return res;
}
