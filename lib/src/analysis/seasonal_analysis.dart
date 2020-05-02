library analysis.seasonal_analysis;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:tuple/tuple.dart';

import 'seasonality.dart';

class SeasonalAnalysis {
  final TimeSeries<num> xs;
  final Seasonality seasonality;
  Map<int, List<num>> _groups;
  Map<Interval, List<Tuple2<int,num>>> _paths;

  SeasonalAnalysis(this.xs, this.seasonality) {
    _groups = seasonality.toGroups(xs);
    _paths = seasonality.toPaths(xs);
  }

  /// Get the data grouped by the groups (the fast component).
  Map<int, List<num>> get groups => _groups;

  /// Get the data grouped by the paths (the slow component).
  Map<Interval, List<Tuple2<int,num>>> get paths => _paths;

  /// Calculate the mean by group.
  Map<int, num> meanByGroup() {
    return {for (var key in _groups.keys) key : mean(_groups[key])};
  }

  /// Calculate the quantile by group.
  Map<int,List<QuantilePair>> quantileByGroup(List<num> probabilities) {
    var out = <int,List<QuantilePair>>{};  // group -> probabilities
    for (var group in _groups.keys) {
      var quantile = Quantile(_groups[group]);
      out[group] = [for (var p in probabilities) QuantilePair(p, quantile.value(p))];
    }
    return out;
  }
}

