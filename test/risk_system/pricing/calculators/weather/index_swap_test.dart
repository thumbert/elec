library test.risk_system.pricing.calculators.weather.index_swap_test;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/weather/index_swap.dart';
import 'package:elec/src/weather/lib_weather_utils.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/client/weather/noaa_daily_summary.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  group('Weather index swap tests: ', () {
    var client = NoaaDailySummary(http.Client(), rootUrl: rootUrl);
    late TimeSeries<num> hData;
    setUp(() async {
      var interval = Interval(TZDateTime.utc(1989), TZDateTime.utc(2021, 4));
      hData = await client.getDailyHistoricalTemperature('BOS', interval);
    });
    test('price Boston HDD swap for 30 years, Jan-Feb', () async {
      // create 30 years starting in 1992
      var term = Term.parse('Jan92-Feb92', UTC);
      var terms = [
        term,
        ...List.generate(
            29, (i) => term.withStartYear(term.startDate.year + i + 1))
      ];
      // value an HDD swap for each term
      var res = <Map<String, dynamic>>[];
      var sw = Stopwatch()..start();
      for (var term in terms) {
        var swap = HddSwap(
            buySell: BuySell.buy,
            term: term.interval,
            quantity: 1,
            strike: TimeSeries.fromIterable([IntervalTuple(term.interval, 0)]))
          ..airportCode = 'BOS'
          ..temperature = hData;
        res.add({'term': term, 'value': swap.value()});
      }
      sw.stop();
      expect(res.length, 30);
      // print(res);
      expect(res.first, {'term': term, 'value': 2000.5});
      expect(sw.elapsedMilliseconds, lessThan(20));
    });
  });
}

Future<void> main() async {
  initializeTimeZones();

  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);
}
