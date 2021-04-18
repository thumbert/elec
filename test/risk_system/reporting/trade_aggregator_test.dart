library test.risk_system.reporting.trade_aggregator_test;

import 'package:date/date.dart';
import 'package:elec/src/risk_system/reporting/trade_aggregator.dart';
import 'package:table/table.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';

void tests() async {
  group('Trade aggregator:', () {
    var location = getLocation('America/New_York');
    test('Check splitting of Flat bucket trade into Peak/Offpeak trades', () {
      var trades = <Map<String,dynamic>>[
        {'buy/sell': 'buy', 'term': 'Jan20-Dec20', 'bucket': 'flat', 'mw': 25, 'price': 39.60},
      ];
      var aggregationTerm = Interval(TZDateTime(location, 2020), TZDateTime(location, 2021));
      var ta = SimpleTradeAggregator(trades, aggregationTerm);
      var mw = ta.aggregate(AggregationVariable.mw);
      expect(mw.length, 24);
      var tbl = reshape(mw, ['month'], ['bucket'], 'mw', fill: 0);
      expect(tbl.length, 12);
//      tbl.forEach(print);
    });


    test('Check aggregation of two trades', () {
      var trades = <Map<String,dynamic>>[
        {'buy/sell': 'buy', 'term': 'Jan20-Dec20', 'bucket': 'flat', 'mw': 25, 'price': 39.60},
        {'buy/sell': 'buy', 'term': 'Jul20-Aug20', 'bucket': 'offpeak', 'mw': 10, 'price': 28.50},
      ];
      var aggregationTerm = Interval(TZDateTime(location, 2020), TZDateTime(location, 2021));
      var ta = SimpleTradeAggregator(trades, aggregationTerm);
      var mw = ta.aggregate(AggregationVariable.mw);
      expect(mw.length, 24);
      var tbl = reshape(mw, ['month'], ['bucket'], 'mw', fill: 0);
      expect(tbl.length, 12);
//      tbl.forEach(print);
      var mwOff = List.generate(12, (i) => i == 6 || i == 7 ? 35 : 25);
      expect(tbl.map((e) => e['Offpeak']).toList(), mwOff);
    });


    test('Check aggregation of buy and sell trades', () {
      var trades = <Map<String,dynamic>>[
        {'buy/sell': 'buy', 'term': 'Jan20-Dec20', 'bucket': 'flat', 'mw': 25, 'price': 39.60},
        {'buy/sell': 'sell', 'term': 'Jul20-Aug20', 'bucket': 'offpeak', 'mw': 10, 'price': 28.50},
      ];
      var aggregationTerm = Interval(TZDateTime(location, 2020), TZDateTime(location, 2021));
      var ta = SimpleTradeAggregator(trades, aggregationTerm);
      var mw = ta.aggregate(AggregationVariable.mw);
      expect(mw.length, 24);
      var tbl = reshape(mw, ['month'], ['bucket'], 'mw', fill: 0);
      expect(tbl.length, 12);
//      tbl.forEach(print);
      var mwOff = List.generate(12, (i) => i == 6 || i == 7 ? 15 : 25);
      expect(tbl.map((e) => e['Offpeak']).toList(), mwOff);
    });


    test('Check non overlapping, out of order trades', () {
      var trades = <Map<String,dynamic>>[
        {'buy/sell': 'buy', 'term': 'Jul20-Aug20', 'bucket': 'offpeak', 'mw': 10, 'price': 28.50},
        {'buy/sell': 'buy', 'term': 'Oct19-Dec19', 'bucket': 'flat', 'mw': 25, 'price': 44.60},
      ];
      var aggregationTerm = Interval(TZDateTime(location, 2019, 10, 1),
          TZDateTime(location, 2021));
      var ta = SimpleTradeAggregator(trades, aggregationTerm);
      var mw = ta.aggregate(AggregationVariable.mw);
      //mw.forEach(print);
      expect(mw.length, 30);
      var tbl = reshape(mw, ['month'], ['bucket'], 'mw', fill: 0);
      expect(tbl.length, 15);
//      tbl.forEach(print);
      var mwOff = List.generate(15, (i) {
        if (i < 3) {
          return 25;
        } else if (i >= 9 && i < 11) {
          return 10;
        } else {
          return 0;
        }
      });
      expect(tbl.map((e) => e['Offpeak']).toList(), mwOff);
    });

  });
}


void main() async {
  initializeTimeZones();
  tests();
}