library test.risk_system.pricing.elec_option_daily_test;

import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/calculators/elec_daily_option.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:test/test.dart';
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
      expect(vs.strikeRatios, [0.5, 1, 2.0]);
      expect(mh.length, 17); // just the monthly component
    });
    test('price option', () async {
      await c0.build();
      var legs = c0.legs;
      var leaves = legs.first.leaves;
      expect(leaves.length, 2);
      var l0 = leaves[0];
      expect(l0.expirationDate, Date(2020, 12, 31, location: location));
      expect(l0.underlyingPrice, 60.7);
      expect(l0.strike, 100);
      expect(l0.volatility.toStringAsFixed(5), '1.17949');
      expect(l0.price().toStringAsFixed(4), '10.2332');
      var value = c0.dollarPrice();
      expect(value.toStringAsFixed(0), '332987');
    });
    test('show details', () async {
      await c0.build();
      var out = c0.showDetails();
      expect(out, r'''
 term                   curveId  bucket  type  strike  quantity  fwdPrice  implVol  optionPrice  delta     value
Jan21  isone_energy_4000_da_lmp    5x16  Call     100    16,000  $60.7000   117.95     $10.2332   0.42  $163,731
Feb21  isone_energy_4000_da_lmp    5x16  Call     100    16,000  $57.2000   119.97     $10.5785   0.43  $169,256''');
    });
    test('flat report', () async {
      await c1.build();
      var report = c1.flatReport();
      var aux = report.toString().split('\n');
      aux.removeAt(2); // remove line with Printed: xxxxxxxx
      var out = r'''
Flat Report
As of date: 2020-07-06

 term                   curveId  bucket  expiration  strike  type  nominalQuantity  forwardPrice  optionPrice     value
Jan21                       USD          2021-01-31                        -50,400          1.00               -$50,400
Feb21                       USD          2021-02-28                        -99,200          1.00               -$99,200

 term                   curveId  bucket  expiration  strike  type  nominalQuantity  forwardPrice  optionPrice     value
Jan21  isone_energy_4000_da_lmp    5x16  2020-12-31     100  Call           16,000         61.20        11.29  $180,583
Feb21  isone_energy_4000_da_lmp    5x16  2021-01-29     100  Call           32,000         57.95        11.77  $376,595

Value: $407,578
''';
      expect(aux.join('\n'), out);
    });
    test('monthly position report', () async {
      await c0.build();
      var report = c0.monthlyPositionReport();
      var aux = report.toString().split('\n');
      aux.removeAt(2); // remove line with Printed: xxxxxxxx
      var out = r'''
Monthly Position Report
As of date: 2020-07-06

 term  isone_energy_4000_da_lmp_5x16  total
Jan21                          6,766  6,766
Feb21                          6,939  6,939
total                         13,705       ''';
      expect(aux.join('\n'), out);
    });

    test('delta-gamma report', () async {
      await c0.build();
      var report = c0.deltaGammaReport(shocks: [-0.1, 0, 0.1]);
      var aux = report.toString().split('\n');
      aux.removeAt(3); // remove line with Printed: xxxxxxxx
      var out = r'''
DeltaGamma Report
Recalculate option deltas for different underlying prices.
As of date: 2020-07-06

 term                   curveId  bucket   -10%     0%    10%
Jan21  isone_energy_4000_da_lmp    5x16  5,976  6,766  7,497
Feb21  isone_energy_4000_da_lmp    5x16  6,213  6,939  7,608''';
      expect(aux.join('\n'), out);
    });
  });
}

void main() async {
  await initializeTimeZones();
  await tests('http://localhost:8080/');
}
