library weather.lib_weather_utils;

import 'package:dama/basic/num_iterable_extensions.dart';
import 'package:date/date.dart';
import 'package:elec/src/risk_system/pricing/calculators/weather/cdd_hdd.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

/// Calculate the CDD or HDD index for a given [term] from the daily
/// timeseries [ts].  
/// 
/// The [term] and the timeseries [ts] need to be in the same timezone.
/// 
num calculateIndex(
    {required Term term,
    required TimeSeries<num> ts,
    required CddHdd indexType}) {
  var xs = ts.window(term.interval);
  return xs.map((e) => indexType.payoff(e.value)).sum();
}

/// Make historical terms for different weather instruments.
/// To make the last complete 30 past Aug months, use startMonth = endMonth = 8.
/// To make the last complete 30 past Dec-Feb term, use startMonth = 12,
/// endMonth = 2
///
/// Do NOT return incomplete or future terms e.g. if you are interested in
/// month = 8, and current date is 10Aug2019, don't return Aug19 in
/// the generated historical terms.
///
/// Return a list of intervals in UTC time zone.
@Deprecated("Use Term.generate() from date package")
List<Interval> makeHistoricalTerm(int startMonth, int endMonth, {int n = 30}) {
  // check that the month list is increasing by 1 and has no gaps
  var yearEnd = Date.today(location: UTC).year;
  var yearStart = yearEnd - n - 1;
  var out = <Interval>[];
  for (var year = yearStart; year <= yearEnd; year++) {
    if (endMonth >= startMonth) {
      if (endMonth - startMonth == 0) {
        out.add(Month.utc(year, startMonth));
      } else {
        var start = Date.utc(year, startMonth, 1);
        var end = Month.utc(year, endMonth).endDate;
        out.add(Interval(start.start, end.end));
      }
    } else {
      // term goes into next year
      var start = Date.utc(year, startMonth, 1);
      var end = Month.utc(year + 1, endMonth).endDate;
      out.add(Interval(start.start, end.end));
    }
  }

  /// check that the last term is not in the future/incomplete
  if (!Date.today(location: UTC).isAfter(Date.containing(out.last.end))) {
    out.removeLast();
  }
  // have to do it twice, if you are in Jan19 and want last 10 Dec-Feb periods.
  if (!Date.today(location: UTC).isAfter(Date.containing(out.last.end))) {
    out.removeLast();
  }

  return out.sublist(out.length - n);
}
