library analysis.seasonal_analysis;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import 'seasonality.dart';

class SeasonalAnalysis {
  final TimeSeries<num> xs;
  Seasonality _seasonality;
  Map<int, TimeSeries<num>> _groups;
  Map<Interval, TimeSeries<num>> _paths;

  /// Input time series needs to be monthly.
  /// Groups are the months of the year, e.g. the keys are 1, 2, ... 12.  For
  /// key = 1, the value is a monthly time series corresponding to Jan from
  /// different calendar years.  The paths are a map from calendar year to a
  /// monthly time series of 12 values.
  SeasonalAnalysis.monthOfYear(this.xs) {
    _seasonality = Seasonality.monthOfYear;
    _groups = _groupByIndex(xs, (e) => e.start.month);
    _paths = _toPath(xs, (e) {
      var year = Interval(
          TZDateTime(e.interval.start.location, e.interval.start.year),
          TZDateTime(e.interval.start.location, e.interval.start.year + 1));
      return Tuple2(year, e);
    });
  }

  /// Input time series needs to be weekly.
  /// Groups are the weeks of the year, e.g. the keys are 1, 2, ... 53.  For
  /// key = 1, the value is a weekly time series corresponding to week 1 from
  /// different calendar years.  The paths are a map from calendar year to a
  /// weekly time series of 52/53 values.
  SeasonalAnalysis.weekOfYear(this.xs) {
    _seasonality = Seasonality.weekOfYear;
    _groups = _groupByIndex(xs, (e) => Week.fromTZDateTime(e.start).week);
    _paths = _toPath(xs, (e) {
      var year = Interval(
          TZDateTime(e.interval.start.location, e.interval.start.year),
          TZDateTime(e.interval.start.location, e.interval.start.year + 1));
      return Tuple2(year, e);
    });
  }

  /// Input time series needs to be daily.
  /// Groups are the days of the year, e.g. the keys are 1, 2, ... 365/366.  For
  /// key = 1, the value is a daily time series corresponding to day 1 from
  /// different calendar years.  The paths are a map from calendar year to
  /// a daily time series of 365/366 values.
  SeasonalAnalysis.dayOfYear(this.xs) {
    _seasonality = Seasonality.dayOfYear;
    _groups =
        _groupByIndex(xs, (e) => Date.fromTZDateTime(e.start).dayOfYear());
    _paths = _toPath(xs, (e) {
      var year = Interval(
          TZDateTime(e.interval.start.location, e.interval.start.year),
          TZDateTime(e.interval.start.location, e.interval.start.year + 1));
      return Tuple2(year, e);
    });
  }

  /// Input time series needs to be daily.
  /// Groups are the days of the week, e.g. the keys are 1, 2, ... 7.  For
  /// key = 1, the value is a daily time series corresponding to day 1 from
  /// different weeks of the year.  The paths are a map from a calendar week to
  /// a daily time series of 7 values.
  SeasonalAnalysis.dayOfWeek(this.xs) {
    _seasonality = Seasonality.dayOfWeek;
    _groups = _groupByIndex(xs, (e) => e.start.weekday);
    _paths =
        _toPath(xs, (e) => Tuple2(Week.fromTZDateTime(e.interval.start), e));
  }

  /// Input time series needs to be hourly.
  /// Groups are the hours of the day, e.g. the keys are 1, 2, ... 24/25.  For
  /// key = 1, the value is an hourly time series corresponding to hour 1 from
  /// different calendar days.  The paths are a map from a calendar day to
  /// an hourly time series of 23/24/25 values.
  SeasonalAnalysis.hourOfDay(this.xs) {
    _seasonality = Seasonality.hourOfDay;
    _groups = _groupByIndex(xs, (e) => e.start.hour);
    _paths =
        _toPath(xs, (e) => Tuple2(Date.fromTZDateTime(e.interval.start), e));
  }

  /// Input time series must be daily.
  /// Given a list of terms, e.g. Nov12-Mar13, Nov13-Mar14, Nov14-Mar15, etc.
  /// Groups will be the days from the beginning each term, e.g. day 1, day 2,
  /// ..., while paths will be the time series associated with each term.
  /// First day of term is 1 (not 0) for consistency with dayOfYear,
  /// dayOfMonth, etc.
  SeasonalAnalysis.dayOfTerm(this.xs, List<Term> terms) {
    _seasonality = Seasonality.dayOfTerm;
    _groups = <int, TimeSeries<num>>{};
    _paths = <Interval, TimeSeries<num>>{};
    for (var term in terms) {
      var ts = xs.window(term.interval);
      var startDate = ts.first.interval as Date;
      for (var e in ts) {
        var _dayOfTerm = (e.interval as Date).value - startDate.value + 1;
        _groups.putIfAbsent(_dayOfTerm, () => TimeSeries<num>()).add(e);
        _paths[term.interval] = TimeSeries.fromIterable(ts);
      }
    }
  }

  /// Input time series [xs] should be daily.
  /// This seasonality is useful for periodic time series, where a moving
  /// average approach is preferred when creating the groups.  For example a
  /// look at precipitation data, sunshine or even detrended temperatures.
  ///
  /// [days] is the number of days you use before and after the given day of
  /// year to form the group.
  static SeasonalAnalysis dayOfYearCentered(TimeSeries<num> xs, int days) {
    var _daysOfYear = List.generate(366, (i) => i + 1);
    var _grps = <int, TimeSeries<num>>{};
    for (var d in _daysOfYear) {
      var res = TimeSeries<num>();
      var obs = xs.where((e) => (e.interval as Date).dayOfYear() == d);
      for (var e in obs) {
        var date = e.interval as Date;
        var interval = Interval(date.subtract(days).start, date.add(days).end);
        res.addAll(xs.window(interval));
      }
      _grps[d] = res;
    }

    var sa = SeasonalAnalysis.dayOfYear(xs)..groups = _grps;
    return sa;
  }

  Seasonality get seasonality => _seasonality;

  /// Get the data grouped by the groups.  For example, for Seasonality.dayOfYear
  /// each entity of the [groups] has as key the day of the year, and as values
  /// a daily TimeSeries for all the years in the input that correspond to this
  /// day of the year, e.g. for key = 1, all 1-Jan in the input time series.
  Map<int, TimeSeries<num>> get groups => _groups;

  /// Get the data grouped by the paths.  For example, for
  /// [Seasonality.dayOfYear], each entity of the [paths] has as key a calendar
  /// year and as value a daily TimeSeries.
  Map<Interval, TimeSeries<num>> get paths => _paths;

  set groups(Map<int, TimeSeries> value) => _groups = value;

  /// Calculate the mean by group.
  Map<int, num> meanByGroup() {
    return {for (var key in _groups.keys) key: mean(_groups[key].values)};
  }

  /// Calculate the summary statistics by group
  Map<int, Map<String, num>> summaryByGroup() =>
      {for (var group in _groups.keys) group: summary(_groups[group].values)};

  /// Calculate the summary statistics by path
  Map<Interval, Map<String, num>> summaryByPath() =>
      {for (var key in _paths.keys) key: summary(_paths[key].values)};

  /// Calculate the quantile by group.
  Map<int, List<QuantilePair>> quantileByGroup(List<num> probabilities) {
    var out = <int, List<QuantilePair>>{}; // group -> probabilities
    for (var group in _groups.keys) {
      var quantile = Quantile(_groups[group].values.toList());
      out[group] = [
        for (var p in probabilities) QuantilePair(p, quantile.value(p))
      ];
    }
    return out;
  }
}

Map<Interval, TimeSeries<num>> _toPath(TimeSeries<num> xs,
    Tuple2<Interval, IntervalTuple> Function(IntervalTuple obs) f) {
  var grp = <Interval, TimeSeries<num>>{};
  var n = xs.length;
  for (var i = 0; i < n; i++) {
    var t2 = f(xs[i]);
    grp.putIfAbsent(t2.item1, () => TimeSeries<num>()).add(t2.item2);
  }
  return grp;
}

Map<int, TimeSeries<K>> _groupByIndex<K>(
    TimeSeries<K> xs, int Function(Interval interval) f) {
  var grp = <int, TimeSeries<K>>{};
  var n = xs.length;
  for (var i = 0; i < n; i++) {
    var group = f(xs[i].interval);
    grp.putIfAbsent(group, () => TimeSeries<K>()).add(xs[i]);
  }
  return grp;
}
