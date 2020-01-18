library time.shape.shape_cost;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/time/bucket/bucket_utils.dart';
import 'package:timeseries/timeseries.dart';

/// Calculate the shaping cost by bucket and aggregation.
///
Map<Bucket,TimeSeries<num>> shapeCost(TimeSeries<num> price,
    TimeSeries<num> quantity, List<Bucket> buckets,
  {TimeAggregation timeAggregation = TimeAggregation.term}) {

  var qBucket = splitByBucket(quantity, buckets);
  var pBucket = splitByBucket(price, buckets);

  var out = <Bucket,TimeSeries<num>>{};
  for (var bucket in buckets) {
    TimeSeries<num> pq, pAvg, qSum;
    var _pq = TimeSeries.fromIterable(pBucket[bucket]).merge(
        TimeSeries.fromIterable(qBucket[bucket]), f: (x,y) => x*y);

    if (timeAggregation == TimeAggregation.month) {
      qSum = toMonthly(qBucket[bucket], sum);
      pAvg = toMonthly(pBucket[bucket], mean);
      pq = toMonthly(_pq, sum);

    } else if (timeAggregation == TimeAggregation.year) {
      qSum = toYearly(qBucket[bucket], sum);
      pAvg = toYearly(pBucket[bucket], mean);
      pq = toYearly(_pq, sum);

    } else if (timeAggregation == TimeAggregation.term) {
      var term = price.domain;
      if (term != quantity.domain) {
        throw ArgumentError('Domains of price and quantity are different');
      }
      qSum = TimeSeries.fromIterable([
        IntervalTuple(term, sum(qBucket[bucket].map((e) => e.value)))]);
      pAvg = TimeSeries.fromIterable([
        IntervalTuple(term, mean(pBucket[bucket].map((e) => e.value)))]);
      pq = TimeSeries.fromIterable([
        IntervalTuple(term, sum(_pq.map((e) => e.value)))]);
    }

    out[bucket] = pq/qSum - pAvg;
  }

  return out;
}