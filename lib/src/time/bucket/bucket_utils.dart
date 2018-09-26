library time.bucket.bucket_utils;

import 'package:timeseries/timeseries.dart';
import 'bucket.dart';

/// Split the observations of timeseries [x] into other timeseries such that
/// each of these timeseries have intervals in a corresponding bucket.
/// Only one traversal of [x] is made.  Works for hourly and sub-hourly
/// timeseries.
Map<Bucket,TimeSeries> splitByBucket(TimeSeries x, List<Bucket> buckets) {
  //TODO

}