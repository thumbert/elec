import 'package:dama/dama.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/time/bucket/bucket_utils.dart';
import 'package:timeseries/timeseries.dart';

/// Calculate the shaping cost by bucket and aggregation.
///
Map<Bucket, TimeSeries<num>> shapeCost(
    TimeSeries<num> price, TimeSeries<num> quantity, List<Bucket> buckets,
    {TimeAggregation timeAggregation = TimeAggregation.term}) {
  var qBucket = splitByBucket(quantity, buckets);
  var pBucket = splitByBucket(price, buckets);

  var out = <Bucket, TimeSeries<num>>{};
  for (var bucket in buckets) {
    late TimeSeries<num> pq;
    late TimeSeries<num> pAvg;
    late TimeSeries<num> qSum;
    var pq0 = TimeSeries.fromIterable(pBucket[bucket]!).merge(
        TimeSeries.fromIterable(qBucket[bucket]!),
        f: (x, dynamic y) => x! * y);

    if (timeAggregation == TimeAggregation.month) {
      qSum = toMonthly(qBucket[bucket]!, sum);
      pAvg = toMonthly(pBucket[bucket]!, mean);
      pq = toMonthly(pq0, sum);
    } else if (timeAggregation == TimeAggregation.year) {
      qSum = toYearly(qBucket[bucket]!, sum);
      pAvg = toYearly(pBucket[bucket]!, mean);
      pq = toYearly(pq0, sum);
    } else if (timeAggregation == TimeAggregation.term) {
      var term = price.domain;
      if (term != quantity.domain) {
        throw ArgumentError('Domains of price and quantity are different');
      }
      qSum = TimeSeries.fromIterable(
          [IntervalTuple(term, sum(qBucket[bucket]!.map((e) => e.value)))]);
      pAvg = TimeSeries.fromIterable(
          [IntervalTuple(term, mean(pBucket[bucket]!.map((e) => e.value)))]);
      pq = TimeSeries.fromIterable(
          [IntervalTuple(term, sum(pq0.map((e) => e.value)))]);
    }

    out[bucket] = pq / qSum - pAvg;
  }

  return out;
}
