library physical.load.lib_duck_curve;

import 'package:dama/analysis/interpolation/multi_linear_interpolator.dart';
import 'package:dama/dama.dart';

/// Calculate the strength of the duck curve for one day.
/// Where
///  - [ws] are the **hourly** weights.  Sum of [ws] is the number of hours
///    in the day
///  - [start] is the hour start, typically 7 (in hour beginning)
///  - [end] is the hour end, typically 18 (in hour beginning)
///
/// The result is the signed area between the curve [ws] and the straight line
/// determined by [ws[start]] and [ws[end]].
///
/// Note: a sunny day with high solar generation will return a 'large' negative
/// value, while a cloudy day.
num duckMeasure(List<num> ws, {required int start, required int end}) {
  assert(end - start > 1);
  var areaWeights = ws.sublist(start, end + 1).sum() / (end - start + 1);
  return areaWeights - (ws[start] + ws[end]) / 2;
}
