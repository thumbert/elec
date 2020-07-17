library test.risk_system.pricing.elec_calc_cdf_test;

import 'package:dama/basic/count.dart';
import 'package:dama/dama.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/client/marks/forward_marks.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/elec_calc_cfd.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:tuple/tuple.dart';

/// Monthly quantities and prices, ISONE
Map<String, dynamic> _calc1() => <String, dynamic>{
      'term': 'Jan21-Mar21',
      'asOfDate': '2020-05-29',
      'buy/sell': 'Buy',
      'comments': 'a simple calculator for winter times',
      'legs': [
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'cash/physical': 'cash',
          'bucket': '5x16',
          'quantity': [
            {'month': '2021-01', 'value': 50},
            {'month': '2021-02', 'value': 50},
            {'month': '2021-03', 'value': 50},
          ],
          'fixPrice': [
            {'month': '2021-01', 'value': 50.5},
            {'month': '2021-02', 'value': 50.5},
            {'month': '2021-03', 'value': 50.5},
          ],
        }
      ],
    };
Map<String, dynamic> _calc2() => <String, dynamic>{
      'term': 'Jan21-Mar21',
      'asOfDate': '2020-05-29',
      'buy/sell': 'Buy',
      'comments': 'a simple calculator for winter times',
      'legs': [
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'cash/physical': 'cash',
          'bucket': '5x16',
          'quantity': [
            {'month': '2021-01', 'value': 50},
            {'month': '2021-02', 'value': 50},
            {'month': '2021-03', 'value': 50},
          ],
        },
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'cash/physical': 'cash',
          'bucket': 'offpeak',
          'quantity': [
            {'month': '2021-01', 'value': 50},
            {'month': '2021-02', 'value': 50},
            {'month': '2021-03', 'value': 50},
          ],
        },
      ],
    };

void tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  var curveIdClient = CurveIdClient(Client(), rootUrl: rootUrl);
  var forwardMarksClient = ForwardMarks(Client(), rootUrl: rootUrl);
  group('Elec calc cdf tests ISONE, 1 leg:', () {
    ElecCalculatorCfd c1;
    setUp(() async {
      c1 = ElecCalculatorCfd(
          curveIdClient: curveIdClient, forwardMarksClient: forwardMarksClient);
      await c1.fromJson(_calc1());
    });
    test('fromJson', () {
      expect(c1.asOfDate, Date(2020, 5, 29, location: UTC));
      expect(c1.term, Term.parse('Jan21-Mar21', UTC));
      var _term = Term.parse('Jan21-Mar21', location);
      var _months = _term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
      expect(c1.legs.length, 1);
      var leg = c1.legs.first;
      expect(leg.quantity, TimeSeries<num>.from(_months, [50, 50, 50]));
      expect(leg.fixPrice, TimeSeries<num>.from(_months, [50.5, 50.5, 50.5]));
      expect(leg.floatingPrice.values.map((e) => e.toStringAsFixed(2)),
          ['58.25', '55.75', '40.00']);
    });
    test('toJson (don\'t serialize the floatingPrice and asOfDate)', () {
      var aux = _calc1();
      ((aux['legs'] as List).first as Map).remove('floatingPrice');
      aux.remove('asOfDate');
      expect(c1.toJson(), aux);
    });
    test('price it', () async {
      expect(c1.dollarPrice().round(), 14800);
      var leg = c1.legs.first;
      expect(leg.price.toStringAsFixed(2), '50.79');
      expect(leg.leaves.length, 3); // 3 months
    });
    test('test curveIdCache', () async {
      var doc = await c1.curveIdCache.get('isone_energy_4000_da_lmp');
      expect(doc['commodity'], 'electricity');
      expect(doc['serviceType'], 'energy');
      expect(doc['region'], 'isone');
    });
    test('test forwardMarksCache', () async {
      var doc = await c1.forwardMarksCache
          .get(Tuple2(Date(2020, 5, 29), 'isone_energy_4000_da_lmp'));
      expect(doc.length, 19);
      var x0 = doc.first;
      expect(x0.interval, Month(2020, 6, location: location));
      expect(x0.value, <Bucket, num>{
        IsoNewEngland.bucket5x16: 22.2,
        IsoNewEngland.bucket2x16H: 18.35,
        IsoNewEngland.bucket7x8: 12.928,
      });
      print(doc.observationAt(Month(2021, 3, location: location)));
    });
    test('test getForwardMarks for 7x8 bucket', () async {
      var x = await c1.getFloatingPrice(
          Bucket.b7x8, 'isone_energy_4000_da_lmp', TimePeriod.hour);
      expect(x.length, 719);
      var mPrice = toMonthly(x, mean);
      var mar = Month(2021, 3, location: location);
      /// TODO: my hourly shaping for Mar21 is wrong because of DST!
      expect(mPrice.observationAt(mar).value.toStringAsPrecision(3), '33.343');
    });
    test('test getForwardMarks for non-standard bucket', () async {
      var x = await c1.getFloatingPrice(
          Bucket.b5x8, 'isone_energy_4000_da_lmp', TimePeriod.hour);
      var mPrice = toMonthly(x, mean);
      var jan = Month(2021, 1, location: location);
      expect(mPrice.observationAt(jan).value.toStringAsFixed(3), '48.072');
    });
    test('change buy/sell and reprice', () async {
      var calc = c1..buySell = BuySell.sell;
      await calc.build();
      expect(calc.dollarPrice().round(), -14800);
      var leg = calc.legs.first;
      expect(leg.price.toStringAsFixed(2), '50.79');
    });
    test('change calculator term and reprice', () async {
      var calc = c1..term = Term.parse('Jan21-Feb21', location);
      await calc.build();
      expect(calc.legs.first.floatingPrice.intervals.toList(), [
        Month(2021, 1, location: location),
        Month(2021, 2, location: location)
      ]);
      expect(
          calc.legs.first.floatingPrice.values
              .map((e) => e.toStringAsFixed(2))
              .toList(),
          ['58.25', '55.75']);
      expect(calc.dollarPrice().round(), 208000);
      var leg = calc.legs.first;
      expect(leg.leaves.length, 2); // two months only
      expect(leg.price.toStringAsFixed(2), '57.00');
    });
    test('change calculator asOfDate and reprice', () async {
      var calc = c1
        ..term = Term.parse('Jan21-Feb21', location)
        ..asOfDate = Date(2020, 7, 6);
      await calc.build();
      expect(calc.legs.first.floatingPrice.first.value.toStringAsFixed(2),
          '60.70');
      expect(calc.dollarPrice().round(), 270400);
      var leg = calc.legs.first;
      expect(leg.leaves.length, 2); // two months only
      expect(leg.price.toStringAsFixed(2), '58.95');
    });
//    test('change calculator bucket and reprice', () async {
//      var calc = c1..legs.first.bucket = IsoNewEngland.bucket7x8;
//      await calc.build();
//      expect(calc.legs.first.floatingPrice.intervals, [
//        Month(2021, 1, location: location),
//        Month(2021, 2, location: location),
//        Month(2021, 3, location: location),
//      ]);
//      expect(
//          calc.legs.first.floatingPrice.values
//              .map((e) => e.toStringAsFixed(3))
//              .toList(),
//          ['48.072', '46.284', '33.343']);
//      var leg = calc.legs.first;
//      expect(leg.price.toStringAsFixed(3), '42.455');
//    });
    test('price non-standard bucket 5x8', () async {
      var calc = c1
        ..term = Term.parse('Jan21-Feb21', location)
        ..legs.first.bucket = Bucket.b5x8;
      await calc.build();
      expect(calc.legs.first.floatingPrice.intervals, [
        Month(2021, 1, location: location),
        Month(2021, 2, location: location),
      ]);
      expect(
          calc.legs.first.floatingPrice.values.map((e) => e.toStringAsFixed(3)),
          ['48.072', '46.284']);
      var leg = calc.legs.first;
      expect(leg.price.toStringAsFixed(3), '42.455');
    });
    test('parse calculator without fixPrice', () async {
      var aux = <String, dynamic>{
        'term': 'Jan21-Mar21',
        'asOfDate': '2020-05-29',
        'buy/sell': 'Buy',
        'legs': [
          {
            'curveId': 'isone_energy_4000_da_lmp',
            'cash/physical': 'cash',
            'bucket': '5x16',
            'quantity': [
              {'month': '2021-01', 'value': 50},
              {'month': '2021-02', 'value': 50},
              {'month': '2021-03', 'value': 50},
            ],
          }
        ],
      };
      var calc = ElecCalculatorCfd(
          curveIdClient: curveIdClient, forwardMarksClient: forwardMarksClient);
      await calc.fromJson(aux);
      expect(calc.dollarPrice().round(), 2560000);
    });
    test('flat report', () {
      var calc = c1..dollarPrice();
      var report = calc.flatReport();
      var aux = report.toString().split('\n');
      aux.removeAt(2); // remove line with Printed: xxxxxxxx
      var out = r'''
Flat Report
As of date: 2020-05-29

 term                   curveId  bucket  nominalQuantity  forwardPrice      value
Jan21                       USD                 -808,000          1.00  -$808,000
Feb21                       USD                 -808,000          1.00  -$808,000
Mar21                       USD                 -929,200          1.00  -$929,200

 term                   curveId  bucket  nominalQuantity  forwardPrice      value
Jan21  isone_energy_4000_da_lmp    5x16           16,000         58.25   $932,000
Feb21  isone_energy_4000_da_lmp    5x16           16,000         55.75   $892,000
Mar21  isone_energy_4000_da_lmp    5x16           18,400         40.00   $736,000

Value: $14,800
''';
      expect(aux.join('\n'), out);
    });
    test('position report', () {
      var calc = c1..dollarPrice();
      var report = calc.monthlyPositionReport();
      var aux = report.toString().split('\n');
      aux.removeAt(2); // remove line with Printed: xxxxxxxx
      var out = r'''
Monthly Position Report
As of date: 2020-05-29

 term  isone_energy_4000_da_lmp_5x16   total
Jan21                         16,000  16,000
Feb21                         16,000  16,000
Mar21                         18,400  18,400
total                         50,400        ''';
      expect(aux.join('\n'), out);
    });
  });

//  group('Elec calc cdf tests ISONE, 2 legs', () {
//    ElecCalculatorCfd c2;
//    setUp(() async {
//      c2 = ElecCalculatorCfd(
//          curveIdClient: curveIdClient, forwardMarksClient: forwardMarksClient);
//      await c2.fromJson(_calc2());
//    });
//    test('fromJson', () {
//      expect(c2.asOfDate, Date(2020, 5, 29, location: UTC));
//      expect(c2.term, Term.parse('Jan21-Mar21', UTC));
//      var _term = Term.parse('Jan21-Mar21', location);
//      var _months = _term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
//      expect(c2.legs.length, 2);
//      var leg1 = c2.legs.first;
//      expect(leg1.quantity, TimeSeries<num>.from(_months, [50, 50, 50]));
//      expect(leg1.fixPrice, TimeSeries<num>.from(_months, [0, 0, 0]));
//      expect(leg1.floatingPrice,
//          TimeSeries<num>.from(_months, [58.25, 55.75, 40.0]));
//      var leg2 = c2.legs[1];
//      expect(leg2.bucket, IsoNewEngland.bucketOffpeak);
//    });
//    test('price it', () {
//      expect(c2.legs[1].price.toStringAsFixed(2), '44.20');
//      expect(c2.dollarPrice().round(), 5103466);
//    });
//    test('flat report', () {
//      var report = c2.flatReport();
//      var aux = report.toString().split('\n');
//      aux.removeAt(2); // remove line with Printed: xxxxxxxx
//      var out = r'''
//Flat Report
//As of date: 2020-05-29
//
// term                   curveId   bucket  nominalQuantity  forwardPrice       value
//Jan21                       USD                        -0          1.00         -$0
//Feb21                       USD                        -0          1.00         -$0
//Mar21                       USD                        -0          1.00         -$0
//Jan21                       USD                        -0          1.00         -$0
//Feb21                       USD                        -0          1.00         -$0
//Mar21                       USD                        -0          1.00         -$0
//
// term                   curveId   bucket  nominalQuantity  forwardPrice       value
//Jan21  isone_energy_4000_da_lmp     5x16           16,000         58.25    $932,000
//Feb21  isone_energy_4000_da_lmp     5x16           16,000         55.75    $892,000
//Mar21  isone_energy_4000_da_lmp     5x16           18,400         40.00    $736,000
//Jan21  isone_energy_4000_da_lmp  Offpeak           21,200         50.00  $1,059,994
//Feb21  isone_energy_4000_da_lmp  Offpeak           17,600         47.80    $841,286
//Mar21  isone_energy_4000_da_lmp  Offpeak           18,750         34.25    $642,186
//
//Value: $5,103,466
//''';
//      expect(aux.join('\n'), out);
//    });
//    test('position report', () {
//      var report = c2.monthlyPositionReport();
//      var aux = report.toString().split('\n');
//      aux.removeAt(2); // remove line with Printed: xxxxxxxx
//      var out = r'''
//Monthly Position Report
//As of date: 2020-05-29
//
// term  isone_energy_4000_da_lmp_5x16  isone_energy_4000_da_lmp_Offpeak   total
//Jan21                         16,000                            21,200  37,200
//Feb21                         16,000                            17,600  33,600
//Mar21                         18,400                            18,750  37,150
//total                         50,400                            57,550        ''';
//      expect(aux.join('\n'), out);
//    });
//  });
}

void main() async {
  await initializeTimeZones();
  await tests('http://localhost:8080/');
}
