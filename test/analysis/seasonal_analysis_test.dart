library test.analysis.seasonal_analysis_test;

import 'package:date/date.dart';
import 'package:elec/src/analysis/seasonal_analysis.dart';
import 'package:elec/src/analysis/seasonality.dart';
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
  });
}

void main() async {
  await initializeTimeZones();
  tests();
}
