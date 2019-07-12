library time.bucket.monthly_bucket_curve;

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/time/bucket/month_bucket_value.dart';
import 'package:tuple/tuple.dart';

class MonthBucketCurve {
  List<MonthBucketValue> values;
  Set<Bucket> _buckets = {};
  List<Month> _months = [];

  /// Construct a monthly bucket curve from a list of monthly bucket values.
  /// It can be used to represent quantities for a fixed shape deal for
  /// example.
  /// <p>The month/bucket combination should be unique.
  MonthBucketCurve(List<MonthBucketValue> values) {
    _internal(values);
  }

  /// Construct a monthly bucket curve from a list of monthly timeseries for
  /// each bucket.  The buckets should not be overlapping (no check for this
  /// is made).
  ///
  /// This may be the easiest way to construct the curve.
  /// For example, if you have two monthly timeseries corresponding to the peak
  /// and offpeak monthly prices.
  ///
  MonthBucketCurve.from(List<Bucket> buckets, List<TimeSeries<num>> xs) {
    _buckets = buckets.toSet();
    if (_buckets.length != buckets.length)
      throw ArgumentError('The buckets $buckets are not unique');
    var values = <MonthBucketValue>[];
    for (int i=0; i<buckets.length; i++) {
      var ts = xs[i];
      for (var iTuple in ts) {
        Month month = iTuple.interval;
        values.add(MonthBucketValue(month, buckets[i], iTuple.value));
      }
    }
    _internal(values);
  }

  void _internal(List<MonthBucketValue> values) {
    var _uniques = <Tuple2<Month,Bucket>>{};
    var aux = <MonthBucketValue>[];
    var _monthsS = <Month>{};
    for (var value in values) {
      aux.add(value);
      _buckets.add(value.bucket);
      _monthsS.add(value.month);
      var t2 = Tuple2(value.month, value.bucket);
      if (_uniques.contains(t2))
        throw ArgumentError('Tuple $t2 already exists');
      else _uniques.add(t2);
    }
    this.values = aux;
    _months = _monthsS.toList()..sort((a, b) => a.compareTo(b));
  }

  /// The set of buckets for this curve.  Some months may have only a partial
  /// subset of the buckets.
  Set<Bucket> get buckets => _buckets;

  /// The months for this curve, ordered.
  List<Month> get months => _months;

  /// Get the monthly timeseries associated with a given bucket.
  /// <p>Missing months are not filled with zeros.
  TimeSeries<num> getCurveForBucket(Bucket bucket) {
    var aux = values
        .where((mark) => mark.bucket == bucket)
        .map((mark) => IntervalTuple(mark.month, mark.value))
        .toList();
    aux.sort((a, b) => a.interval.compareTo(b.interval));
    return TimeSeries.fromIterable(aux);
  }

  /// Get the hourly timeseries corresponding to this MonthlyBucketCurve.
  /// <p>Missing hours are not filled with zeros.
  TimeSeries<num> toHourly() {
    var grp = groupBy(values, (MonthBucketValue x) => x.month);
    var out = TimeSeries<num>();
    for (var month in months) {
      var aux = <IntervalTuple<num>>[];
      for (var mbv in grp[month]) {
        aux.addAll(mbv.toHourly());
      }
      aux.sort((a, b) => a.interval.compareTo(b.interval));
      out.addAll(aux);
    }

    return out;
  }
}
