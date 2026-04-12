import 'package:timeseries/timeseries.dart';
import 'package:table/table.dart';

enum Show {
  all,
}

/// Reformat a monthly timeseries into tabular format with years as 
/// rows and months as columns.
/// 
/// Return a list of maps with year/month format, e.g.
/// [{'Year': 2016, 'Jan': 3.14, 'Feb': 2.71, ...},
///  {'Year': 2017, 'Jan': 3.14, 'Jun': 2.71, ...},]
///
/// There can be missing months, or incomplete years.
/// 
/// If [show] is not specified, only the months present in the timeseries 
/// are shown (and the keys are NOT ordered by month).  
/// 
/// Specifying [show] as [Show.all] will show all months, and the keys are 
/// ordered by month, e.g. Jan first, etc. Null values are added for the missing
/// months.  This is usually what you want to display the data in a table. 
///
List<Map<String, num?>> formatYearMonth(TimeSeries<num> x, {Show? show}) {
  var nest = Nest()..key((e) => e['interval'].start.year);
  nest.rollup((List xs) {
    var out = <String, num>{};
    for (var e in xs) {
      final month = e['interval'].start.month;
      out[_months[month]!] = e['value'];
    }
    return out;
  });
  var xs = x.map((e) => {'interval': e.interval, 'value': e.value}).toList();
  var aux = nest.map(xs);
  var tbl =
      flattenMap(aux, ['Year'])!.map((e) => e.cast<String, num?>()).toList();

  // sort the columns by month, and add nulls for the missing month columns
  var sortedTbl = <Map<String, num?>>[];
  if (show != null && show == Show.all) {
    for (var row in tbl) {
      var one = {'Year': row['Year']};
      for (var month in _months.keys) {
        final monthName = _months[month]!;
        one[monthName] = row[monthName];
      }
      sortedTbl.add(one);
    }
  } else {
    sortedTbl = tbl;
  }
  return sortedTbl;
}

/// Reformat a monthly timeseries into tabular format with months as 
/// rows and years as columns.
/// 
/// Return a list of maps with month/year format, e.g.
/// [{'Month': 'Jan', '2017': 3.14, '2018': 2.71, ...},
///  {'Month': 'Feb', '2017': 2.71, ...},]
///
/// If [show] is not specified, only the years present in the timeseries are 
/// shown.  The keys may not end up being ordered by year if you have 
/// incomplete years.
///
/// Specifying [show] as [Show.all] will show all years, and the keys are 
/// ordered by year.  Null values are added for the missing
/// years.  This is usually what you want to display the data in a table.
///
List<Map<String, dynamic>> formatMonthYear(TimeSeries<num> x,
    {Show? show}) {
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

  out
    .sort((a, b) => _monthIdx[a['Month']]!.compareTo(_monthIdx[b['Month']]!));

  // sort the columns by year, and add nulls for the missing year columns
  var sortedTbl = <Map<String, dynamic>>[];
  if (show != null && show == Show.all) {
    // get the list of years in the data
    var years = <String>{};
    for (var row in out) {
      for (var key in row.keys) {
        if (key != 'Month') years.add(key);   
      }
    }
    years = (years.toList()..sort()).toSet();
    for (var row in out) {
      var one = {'Month': row['Month']};
      for (var year in years) {
        one[year] = row[year];
      }
      sortedTbl.add(one);
    }
  } else {
    sortedTbl = out;
  }
  return sortedTbl; 
}

const _months = <int, String>{
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

const _monthIdx = <String, int>{
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
