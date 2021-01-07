library test.risk_system.pricing.elec_option_daily_test;

import 'package:dama/dama.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/cache_provider.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/time_period.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/cache_provider.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/elec_daily_option/elec_daily_option.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/cache_provider.dart';
import 'package:elec/src/time/hourly_schedule.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec/calculators/elec_swap.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';

Map<String, dynamic> _calc0() => <String, dynamic>{
      'calculatorType': 'elec_daily_option',
      'term': 'Jan21-Feb21',
      'asOfDate': '2020-07-06',
      'buy/sell': 'Buy',
      'comments': 'a daily options calculator',
      'legs': [
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'tzLocation': 'America/New_York', // ideally this should not be here
          'bucket': '5x16',
          'quantity': {'value': 50},
          'call/put': 'call',
          'strike': {'value': 100.0},
        }
      ],
    };

// with values expanded
Map<String, dynamic> _calc1() => <String, dynamic>{
      'calculatorType': 'elec_daily_option',
      'term': 'Jan21-Feb21',
      'asOfDate': '2020-07-06',
      'buy/sell': 'Buy',
      'comments': 'a daily options calculator',
      'legs': [
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'tzLocation': 'America/New_York', // ideally this should not be here
          'bucket': '5x16',
          'quantity': {
            'value': [
              {'month': '2021-01', 'value': 50.0},
              {'month': '2021-02', 'value': 100.0},
            ]
          },
          'call/put': 'call',
          'strike': {
            'value': [
              {'month': '2021-01', 'value': 100},
              {'month': '2021-02', 'value': 100},
            ]
          },
          'priceAdjustment': {
            'value': [
              {'month': '2021-01', 'value': 0.5},
              {'month': '2021-02', 'value': 0.75},
            ]
          },
          'volatilityAdjustment': {
            'value': [
              {'month': '2021-01', 'value': 0.05},
              {'month': '2021-02', 'value': 0.05},
            ]
          },
          'fixPrice': {
            'value': [
              {'month': '2021-01', 'value': 3.15},
              {'month': '2021-02', 'value': 3.10},
            ]
          },
        }
      ],
    };

void tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  var cacheProvider =
      CacheProviderElecOption.test(client: Client(), rootUrl: rootUrl);
  group('Elec daily option tests ISONE, 1 leg:', () {
    ElecDailyOption c0, c1;
    setUp(() async {
      c0 = ElecDailyOption.fromJson(_calc0())..cacheProvider = cacheProvider;
      c1 = ElecDailyOption.fromJson(_calc1())..cacheProvider = cacheProvider;
    });
    test('from Json', () {
      expect(c0.term, Term.parse('Jan21-Feb21', UTC));
      var leg0 = c0.legs.first;
      expect(leg0.bucket, Bucket.b5x16);
      expect(leg0.callPut, CallPut.call);
    });
    test('to Json, simplest possible', () {
      var out = c0.toJson();
      expect(out.containsKey('asOfDate'), false);
      var leg0 = (out['legs'] as List).first as Map;
      expect(leg0['quantity']['value'], 50);
      expect(leg0['fixPrice']['value'], 0);
      expect(leg0['call/put'], 'Call');
      expect(leg0['strike']['value'], 100);
      // no need to serialize them because they equal zero.
      expect(leg0.containsKey('priceAdjustment'), false);
      expect(leg0.containsKey('volatilityAdjustment'), false);
    });
    test('to Json, custom everything', () {
      var out = c1.toJson();
      expect(out.containsKey('asOfDate'), false);
      var leg0 = (out['legs'] as List).first as Map;
      expect(leg0['quantity']['value'][0], {'month': '2021-01', 'value': 50});
      expect(leg0['quantity']['value'][1], {'month': '2021-02', 'value': 100});
      expect(leg0['fixPrice']['value'][0], {'month': '2021-01', 'value': 3.15});
      expect(leg0['fixPrice']['value'][1], {'month': '2021-02', 'value': 3.1});
      expect(leg0['call/put'], 'Call');
      expect(leg0['strike']['value'], 100);
      expect(leg0['priceAdjustment']['value'][0],
          {'month': '2021-01', 'value': 0.5});
      expect(leg0['priceAdjustment']['value'][1],
          {'month': '2021-02', 'value': 0.75});
      expect(leg0['volatilityAdjustment']['value'], 0.05);
    });
    test('cache provider', () async {
      var asOfDate = Date(2020, 7, 6, location: location);
      var curveDetails =
          await cacheProvider.curveDetailsCache.get('isone_energy_4000_da_lmp');
      var mh = await cacheProvider.forwardMarksCache
          .get(Tuple2(asOfDate, 'isone_energy_4000_da_lmp'));
      var vs = await cacheProvider.volSurfaceCache
          .get(Tuple2(asOfDate, curveDetails['volatilityCurveId']['daily']));
      expect(vs.strikeRatios, [0.5, 1, 1.5]);
      expect(mh.length, 17); // just the monthly component
    });
    test('price option', () async {
      await c0.build();
    });
  });
}

void main() async {
  await initializeTimeZones();
  await tests('http://localhost:8080/');
}
