library test.analysis.seasonal_analysis_test;

import 'package:date/date.dart';
import 'package:elec/src/analysis/seasonal/seasonal_analysis.dart';
import 'package:elec/src/analysis/seasonal/seasonality.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';

void tests() {
  group('SeasonalAnalysis tests:', () {
    test('parse', () {
      var seasonality = Seasonality.parse('hourOfDay');
      expect(seasonality, Seasonality.hourOfDay);
    });
    test('analysis by dayOfYear', () {
      var term = parseTerm('Jan10-Dec20');
      var days = term.splitLeft((dt) => Date.fromTZDateTime(dt));
      var xs = TimeSeries.fromIterable(days
          .map((date) => IntervalTuple(date, date.year + date.dayOfYear())));
      var sa = SeasonalAnalysis(xs, Seasonality.dayOfYear);
      var means = sa.meanByGroup();
      expect(means[1], 2016);
      var quantiles = sa.quantileByGroup([0, 0.25, 0.5, 0.75, 1]);
      expect(quantiles[1].map((e) => e.value).toList(),
          [2011, 2013.5, 2016, 2018.5, 2021]);
      var histories = sa.paths;
      expect(histories[parseTerm('Cal10')].length, 365);
    });
    test('day of year centered', () {
      var term = parseTerm('Jan10-Dec20');
      var days = term.splitLeft((dt) => Date.fromTZDateTime(dt));
      var xs = TimeSeries.fromIterable(days
          .map((date) => IntervalTuple(date, 1)));
      var sa = SeasonalAnalysis.dayOfYearCentered(xs, 2);
      var groups = sa.groups;
      var g1 = groups[1];
      var g1Intervals = g1.intervals.toList();
      expect(g1Intervals[0], Date(2010, 1, 1));
      expect(g1Intervals[1], Date(2010, 1, 2));
      expect(g1Intervals[2], Date(2010, 1, 3));
      expect(g1Intervals[3], Date(2010, 12, 30));
      expect(g1Intervals[4], Date(2010, 12, 31));
      expect(g1Intervals[5], Date(2011, 1, 1));
    });
  });
}

void main() async {
  await initializeTimeZones();
  tests();
}
