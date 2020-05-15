library analysis.seasonal_analysis;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

import 'seasonality.dart';

class SeasonalAnalysis {
  final TimeSeries<num> xs;
  final Seasonality seasonality;
  Map<int, TimeSeries<num>> _groups;
  Map<Interval, TimeSeries<num>> _paths;

  /// The frequency of the input time series [xs] should match the frequency of
  /// the fast component of [seasonality].  E.g. a [Seasonality.dayOfYear]
  /// should be applied to a daily time series, a [Seasonality.monthOfYear] to
  /// a monthly time series, a [Seasonality.hourOfDay] to an hourly time series,
  /// etc.
  SeasonalAnalysis(this.xs, this.seasonality) {
    _groups = seasonality.toGroups(xs);
    _paths = seasonality.toPaths(xs);
  }


  /// This seasonality is useful for periodic time series, where a moving
  /// average approach is preferred when creating the groups.  For example a
  /// look at precipitation data, sunshine or even detrended temperatures.
  ///
  /// Input time series [xs] should be daily.
  /// [days] is the number of days you use before and after the given day of
  /// year to form the group.
  static SeasonalAnalysis dayOfYearCentered(TimeSeries<num> xs, int days) {
    var _daysOfYear = List.generate(366, (i) => i+1);
    var _grps = <int,TimeSeries<num>>{};
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

    var sa = SeasonalAnalysis(xs, Seasonality.dayOfYear)
      ..groups = _grps;
    return sa;
  }



  /// Get the data grouped by the groups (e.g. for a Seasonality.dayOfYear
  /// this would be all the observations grouped by day.) -- the fast component
  Map<int, TimeSeries<num>> get groups => _groups;

  /// Get the data grouped by the paths (the slow component, e.g. year for
  /// [Seasonality.dayOfYear]).
  Map<Interval, TimeSeries<num>> get paths => _paths;

  set groups(Map<int,TimeSeries> value) => _groups = value;

  /// Calculate the mean by group.
  Map<int, num> meanByGroup() {
    return {for (var key in _groups.keys) key: mean(_groups[key].values)};
  }

  /// Calculate the summary statistics by group
  Map<int, Map<String, num>> summaryByGroup() =>
      {for (var group in _groups.keys) group: summary(_groups[group].values)};

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
