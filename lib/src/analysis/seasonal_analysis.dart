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

  /// Get the data grouped by the groups (e.g. for a Seasonality.dayOfYear
  /// this would be all the observations grouped by day.) -- the fast component
  Map<int, TimeSeries<num>> get groups => _groups;

  /// Get the data grouped by the paths (the slow component, e.g. year for
  /// [Seasonality.dayOfYear]).
  Map<Interval, TimeSeries<num>> get paths => _paths;

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
