import 'package:dama/basic/num_iterable_extensions.dart';
import 'package:timeseries/timeseries.dart';

/// Calculate difference between Top [n] - Bottom [n] values in a timeseries.
/// 
/// <p>Typically, for a battery energy storage system n=4, the product is called 
/// TB4.
///
/// Input [x] is an hourly series for one calendar day.
/// 
IntervalTuple<num> tbN(TimeSeries<num> x, {required int n}) {
  if (x.length < 2 * n) {
    throw ArgumentError('Timeseries has less than ${2 * n} observations');
  }
  var vs = x.values.toList()..sort();
  var topN = vs.sublist(vs.length - n);
  var bottomN = vs.take(n);
  var value = topN.mean() - bottomN.mean();
  return IntervalTuple(x.domain, value);
}
