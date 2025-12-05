import 'package:timeseries/timeseries.dart';
import 'package:table/table.dart';

/// Reformat a monthly timeseries into tabular format with year/month
/// Return a list of maps with year/month format, e.g.
/// [{'Year': 2016, 'Jan': 3.14, 'Feb': 2.71, ...},
///  {'Year': 2017, 'Jan': 3.14, 'Jun': 2.71, ...},]
///
///
/// There can be missing months, or incomplete years.
List<Map<String, num>> formatYearMonth(TimeSeries<num> x) {
  var nest = Nest()..key((e) => e['interval'].start.year);
  nest.rollup((List xs) {
    var out = <String?, num?>{};
    for (var e in xs) {
      out[_months[e['interval'].start.month]] = e['value'];
    }
    return out;
  });
  var xs = x.map((e) => {'interval': e.interval, 'value': e.value}).toList();
  var aux = nest.map(xs);
  return flattenMap(aux, ['Year'])!.map((e) => e.cast<String, num>()).toList();
}

/// Reformat a monthly timeseries into tabular format with year/month
/// Return a list of maps with year/month format, e.g.
/// [{'Month': 'Jan', '2017': 3.14, '2018': 2.71, ...},
///  {'Month': 'Feb', '2017': 2.71, ...},]
///
/// There can be missing months, or incomplete years.  Return the rows
/// sorted by month, e.g. Jan first, etc.
List<Map<String, dynamic>> formatMonthYear(TimeSeries<num> x) {
  var nest = Nest()..key((e) => _months[e['interval'].start.month]);
  nest.rollup((List xs) {
    var out = <String, num?>{};
    for (var e in xs) {
      out[e['interval'].start.year.toString()] = e['value'];
    }
    return out;
  });
  var xs = x.map((e) => {'interval': e.interval, 'value': e.value}).toList();
  var aux = nest.map(xs);
  var out = flattenMap(aux, ['Month'])!.toList();

  return out
    ..sort((a, b) => _monthIdx[a['Month']]!.compareTo(_monthIdx[b['Month']]!));
}

var _months = <int, String>{
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec'
};

var _monthIdx = <String, int>{
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};
