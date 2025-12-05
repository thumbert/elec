import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';

class LoadShape {
  LoadShape(this.hourlyData) {
    var aux = groupBy(hourlyData, (e) => Date.containing(e.interval.start));
    _dailyGroups = aux
        .map((key, value) => MapEntry(key, value.map((f) => f.value).toList()));
  }

  final TimeSeries<num> hourlyData;

  /// cache the daily split
  late final Map<Date, List<num>> _dailyGroups;

  /// NOTE: not using bucket yet!
  List<Map<String, dynamic>> makeTraces(
      {required Map<Term, Set<Date>> groups, required Bucket bucket}) {
    var out = <Map<String, dynamic>>[];

    /// group them by year to see year over year changes
    var terms = groups.keys.toList();
    for (var i = 0; i < terms.length; i++) {
      var vs = [
        ...groups[terms[i]]!.map((date) => MapEntry(date, _dailyGroups[date]!))
      ];
      for (final v in vs) {
        var avg = v.value.mean();
        var weights = v.value.map((e) => e / avg).toList();
        out.add({
          'x': List.generate(v.value.length, (i) => i),
          'y': weights,
          'date': v.key.toString(),
          'mode': 'lines',
          'name': '${v.key}',
          'marker': {
            'color': '#b0b0b0',
          },
          'xaxis': 'x${v.key.year - 2019}',
          'yaxis': 'y${v.key.year - 2019}',
          'showlegend': false,
        });
      }

      /// calculate the median
      var summary = <num>[];
      for (var hour = 0; hour < 24; hour++) {
        var xs = <num>[];
        for (var i = 0; i < vs.length; i++) {
          if (vs[i].value.length == 23) {
            continue;
          }
          xs.add(vs[i].value[hour]);
        }
        var quantile = Quantile(xs);
        summary.add(quantile.median());
      }
      var meanSummary = mean(summary);
      var summaryWeight = summary.map((e) => e / meanSummary).toList();
      out.add({
        'x': List.generate(24, (i) => i),
        'y': summaryWeight,
        'mode': 'lines',
        'name': 'median ${terms[i].startDate.year}',
        'line': {
          'color': '#663399',
          'width': 4,
        },
        'xaxis': 'x${terms[i].startDate.year - 2019}',
        'yaxis': 'y${terms[i].startDate.year - 2019}',
        // 'showlegend': false,
      });
    }

    return out;
  }

  /// Return a daily timeseries of hourly weights.
  /// [dates] are the set of dates you are interested in.
  /// What are you doing on Daylight savings days?
// TimeSeries<List<num>> calculateHourlyWeights(
//     {required Set<Date> forDates, required Bucket bucket}) {
//   /// keep only the dates you qre interested in
//   var xs = {...forDates.map((date) => _dailyGroups[date])};
// }

  /// Calculate stats on the weights
}
