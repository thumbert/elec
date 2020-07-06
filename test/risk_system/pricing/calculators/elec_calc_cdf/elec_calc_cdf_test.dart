library test.risk_system.pricing.elec_calc_cdf_test;

import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/elec_calc_cfd.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';


/// Monthly quantities and prices, ISONE
Map<String,dynamic> _calc1() =>  <String,dynamic>{
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
      'showQuantity': 50,
      'fixPrice': [
        {'month': '2021-01', 'value': 50.5},
        {'month': '2021-02', 'value': 50.5},
        {'month': '2021-03', 'value': 50.5},
      ],
      'showFixPrice': 50.5,
      'floatingPrice': [
        {'month': '2021-01', 'value': 58.25},
        {'month': '2021-02', 'value': 55.75},
        {'month': '2021-03', 'value': 40.00},
      ],
    }
  ],
};

void tests(String rootUrl) async {
  group('Elec calc cdf tests ISONE, 1 leg:', () {
    var location = getLocation('America/New_York');
    var curveDetails = <String,Map<String,dynamic>>{};
    var curveIdClient = CurveIdClient(Client(), rootUrl: rootUrl);
    setUp(() async {
      var _aux = await curveIdClient.getCurveIds(['isone_energy_4000_da_lmp']);
      curveDetails = { for (var x in _aux) x['curveId']: x};
      ElecCalculatorCfd.curveDetails = curveDetails;
    });
    test('fromJson', () {
      var calc = ElecCalculatorCfd.fromJson(_calc1());
      expect(calc.asOfDate, Date(2020, 5, 29, location: UTC));
      expect(calc.term, Term.parse('Jan21-Mar21', UTC));
      var _term = Term.parse('Jan21-Mar21', location);
      var _months = _term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
      expect(calc.legs.length, 1);
      var leg = calc.legs.first;
      expect(leg.quantity, TimeSeries<num>.from(_months, [50, 50, 50]));
      expect(leg.fixPrice, TimeSeries<num>.from(_months, [50.5, 50.5, 50.5]));
      expect(leg.floatingPrice, TimeSeries<num>.from(_months, [58.25, 55.75, 40.0]));
    });
    test('toJson (don\'t serialize the floatingPrice and asOfDate)', () {
      var aux = _calc1();
      ((aux['legs'] as List).first as Map).remove('floatingPrice');
      aux.remove('asOfDate');
      var calc = ElecCalculatorCfd.fromJson(_calc1());
      var out = calc.toJson();
      expect(out, aux);
    });
    test('price it', () {
      var calc = ElecCalculatorCfd.fromJson(_calc1());
      var leg = calc.legs.first;
      expect(leg.price.toStringAsFixed(2), '50.79');
      expect(calc.dollarPrice().round(), 14800);
    });
    test('flat report', () {
      var calc = ElecCalculatorCfd.fromJson(_calc1());
      var report = calc.flatReport();
      var aux = report.toString().split('\n');
      aux.removeAt(2);  // remove line with Printed: xxxxxxxx
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
      var calc = ElecCalculatorCfd.fromJson(_calc1());
      var report = calc.monthlyPositionReport();
      var aux = report.toString().split('\n');
      aux.removeAt(2);  // remove line with Printed: xxxxxxxx
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
  
}

void main() async {
  await initializeTimeZones();
  await tests('http://localhost:8080/');
}
