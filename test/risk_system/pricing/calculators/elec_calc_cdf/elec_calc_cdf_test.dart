library test.risk_system.pricing.elec_calc_cdf_test;

import 'package:date/date.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cdf/elec_calc_cdf.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

/// Monthly quantities and prices, ISONE
var _calc1 =  <String,dynamic>{
  'term': 'Jan21-Feb21',
  'asOfDate': '2020-05-22',
  'buy/sell': 'buy',
  'comments': 'a simple calculator for winter times',
  'legs': [
    {
      'region': 'isone',
      'serviceType': 'energy',
      'location': 'mass hub',
      'market': 'da',
      'cash/physical': 'cash',
      'bucket': '5x16',
      'quantity': [
        {'month': '2021-01', 'value': 50},
        {'month': '2021-02', 'value': 50},
      ],
      'fixPrice': [
        {'month': '2021-01', 'value': 58.25},
        {'month': '2021-02', 'value': 57.05},
      ],
    }
  ],
};


void tests() async {
  group('Elec calc cdf tests ISONE:', () {
    var location = getLocation('US/Eastern');
    test('fromJson/toJson one leg, Jan21-Feb21', () {
      var calc = ElecCalculatorCfd.fromJson(_calc1);
      expect(calc.asOfDate, Date(2020, 5, 22, location: UTC));
      expect(calc.term, Term.parse('Jan21-Feb21', UTC));
      var _term = Term.parse('Jan21-Feb21', location);
      var _months = _term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
      expect(calc.legs.length, 1);
      var leg = calc.legs.first;
      expect(leg.quantity, TimeSeries<num>.from(_months, [50, 50]));
      expect(leg.fixPrice, TimeSeries<num>.from(_months, [58.25, 57.05]));
    });
  });
  
}

void main() async {
  await initializeTimeZones();
}
