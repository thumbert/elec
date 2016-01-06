library base.summary_by_bucket;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';

import 'package:elec/elec.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/iso/nepool/config.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/api/nepool_lmp.dart';

/**
 * Calculate a monthly summary by bucket (by default the average value) for a
 * list of buckets.
 *
 * Function [f] takes an Iterable of values and computes a summary of the hourly
 * data by month and bucket.
 *
 */
Future<List<Map>> summaryByBucketMonth(
    List<Tuple2<Hour,num>> hourlyData, List<Bucket> buckets,
    {Function f}) async {
  if (f == null) {
    f = (Iterable x) {
      if (x.isEmpty) return null;
      else return x.reduce((a,b) => a + b) / x.length;
    };
  }

  /// group by month first (better if you have more buckets)
  Map mData = _groupBy(
      hourlyData, (Tuple2<Hour,num> e) => new Month.fromDateTime(e.i1.start));

  List res = [];
  mData.forEach((Month k, List v) {
    buckets.forEach((Bucket bucket) {
      var value = f(v
      .where((Tuple2<Hour,num> e) => bucket.containsHour(e.i1))
      .map((e) => e.i2));
      res.add({'bucket': bucket, 'month': k, 'value': value});
    });
  });

  return res;
}


Map _groupBy(Iterable x, Function f) {
  Map result = new Map();
  x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));

  return result;
}
