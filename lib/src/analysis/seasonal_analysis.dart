library analysis.seasonal_analysis;

import 'package:dama/dama.dart';
import 'package:dama/stat/descriptive/ecdf.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:collection/collection.dart';


class Seasonality {
  final String name;
  final Map<int,List<num>> Function(TimeSeries<num>) _grouping;

  const Seasonality._internal(this.name, this._grouping);

  static var year = Seasonality._internal('year',
      (TimeSeries<num> xs) => _groupByIndex(xs, (e) => e.start.year));
  static var monthOfYear = Seasonality._internal('monthOfYear',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => e.start.month));
  static var weekOfYear = Seasonality._internal('weekOfYear',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => Week.fromTZDateTime(e.start).week));
  static var dayOfYear = Seasonality._internal('dayOfYear',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => Date.fromTZDateTime(e.start).dayOfYear()));
  static var dayOfWeek = Seasonality._internal('dayOfWeek',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => e.start.weekday));
  static var hourOfDay = Seasonality._internal('hourOfDay',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => e.start.hour));

  @override
  String toString() => name;
}


class SeasonalAnalysis {
  final TimeSeries<num> xs;
  final Seasonality seasonality;
  Map<int, List<num>> _groups;

  SeasonalAnalysis(this.xs, this.seasonality) {
    _groups = seasonality._grouping(xs);
  }

  Map<int, List<num>> get groups => _groups;

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


Map<int, List<K>> _groupByIndex<K>(TimeSeries<K> xs, int Function(Interval interval) f) {
  var grp = <int, List<K>>{};
  var n = xs.length;
  for (var i = 0; i < n; i++) {
    var group = f(xs[i].interval);
    grp.putIfAbsent(group, () => <K>[]).add(xs[i].value);
  }
  return grp;
}

