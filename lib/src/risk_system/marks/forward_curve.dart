library risk_system.marks.forward_curve;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/risk_system/locations/location.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/time/bucket/monthly_bucket_value.dart';

//class ForwardCurve {
//  Location location;
//  Set<Bucket> buckets;
//
//  Map<Date, List<MonthlyBucketValue>> _cache = {};
//
//  /// A representation of a forward curve as a monthly bucket curve.
//  /// In the strict sense, it is monthly values by bucket from a prompt month
//  /// to an endMonth.
//  ///
//  /// Can also be used to represent quan
//  ForwardCurve(this.buckets);
//
//  /// Set the value of this forward curve as of a given asOfDate.
//  void setCurve(Date asOfDate, List<MonthlyBucketValue> marks) {
//    var aux = <MonthlyBucketValue>[];
//    for (var mark in marks) {
//      if (mark.month.start.isBefore(asOfDate.start))
//        throw ArgumentError('Mark $mark starts before asOfDate $asOfDate');
//      if (!buckets.contains(mark.bucket))
//        throw ArgumentError('Mark bucket ${mark.bucket} is not in $buckets');
//      aux.add(mark);
//    }
//    _cache[asOfDate] = aux;
//  }
//
//  /// Get the value of this forward curve as of a given asOfDate.
//  List<MonthlyBucketValue> getCurve(Date asOfDate) {
//    if (_cache.containsKey(asOfDate)) {
//      return _cache[asOfDate];
//    } else {
//      throw ArgumentError(
//          'Cache not set for $location Forward Curve as of $asOfDate');
//    }
//  }
//
//  /// Get the value of this forward curve as of a given asOfDate.
//  TimeSeries<num> getCurveForBucket(Date asOfDate, Bucket bucket) {
//    if (_cache.containsKey(asOfDate)) {
//      var aux = _cache[asOfDate]
//          .where((mark) => mark.bucket == bucket)
//          .map((mark) => IntervalTuple(mark.month, mark.value))
//          .toList();
//      aux.sort((a, b) => a.interval.compareTo(b.interval));
//      return TimeSeries.fromIterable(aux);
//    } else {
//      throw ArgumentError(
//          'Cache not set for $location Forward Curve as of $asOfDate');
//    }
//  }
//
//  /// Get the hourly timeseries corresponding
//  TimeSeries<num> toHourly() {
//
//
//  }
//
//
//
//  /// TODO: from Mongo backend
//  Future<Null> populateCache(Date asOfDate) async {
//    //_cache[asOfDate] = ...
//  }
//}
