library test.financial.trade_test;

import 'dart:ffi';

import 'package:date/date.dart';
import 'package:elec/risk_system.dart' hide Trade;
import 'package:elec/src/financial/trading_strategy/portfolio.dart';
import 'package:table/table_base.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void setData() {
  marketPriceData[(Date.utc(2022, 1, 7), 'TTF')] = 22.10;
  marketPriceData[(Date.utc(2022, 1, 19), 'TTF')] = 20.94;
  marketVolData[(Date.utc(2022, 1, 7), 'TTFVOL', 50.0)] = 1.75;
  marketVolData[(Date.utc(2022, 1, 19), 'TTFVOL', 50.0)] = 1.75;
}

void tests() {
  group('Instrument pricing', () {
    test('A TTF gas futures trade', () {
      var trade = TradeLeg(
          instrument: Futures(name: 'TTF', contractMonth: Month.utc(2023, 1)),
          tradeDate: Date.utc(2022, 1, 6),
          buySell: BuySell.sell,
          price: 29.0,
          quantity: 50 * 744,
          uom: Unit.mwh);
      var value = trade.value(Date.utc(2022, 1, 7));
      expect(value.toStringAsFixed(4), '256680.0000');
    });
    test('A TTF gas option trade', () {
      final instrument = MonthlyGasOption(
          name: 'TTFOPT',
          contractMonth: Month.utc(2023, 1),
          type: CallPut.call,
          strike: 50,
          underlyingName: 'TTF',
          volatilityName: 'TTFVOL');
      var leg = TradeLeg(
          instrument: instrument,
          tradeDate: Date.utc(2022, 1, 6),
          buySell: BuySell.buy,
          price: 8.25,
          quantity: 50 * 744,
          uom: Unit.mwh);
      var instrumentValue = instrument.price(Date.utc(2022, 1, 19));
      var value = leg.value(Date.utc(2022, 1, 19));
      expect(instrumentValue.toStringAsFixed(4), '8.9171');
      expect(value.toStringAsFixed(4), '24815.6742');
    });
  });
}

class DeltaHedging {
  DeltaHedging(
      {required this.initialPortfolio,
      required this.hedgeInstruments,
      required this.tresholdDelta});

  Portfolio initialPortfolio;
  List<Instrument> hedgeInstruments;
  final num tresholdDelta;

  List<Map<String, dynamic>> report = <Map<String, dynamic>>[];
  late Portfolio portfolio;

  ///
  void run(List<Date> days) {
    report.clear();
    portfolio = Portfolio(trades: initialPortfolio.trades);
    for (var day in days) {
      report.add({
        'date': day,
        'portfolio': portfolio,
        'value': portfolio.value(day),
        'positions': portfolio.delta(day),
      });
    }
  }
}

void deltaHedgingStrategy() {
  // initial portfolio, long call option + short the underlying
  var portfolio = Portfolio(trades: [
    Trade(legs: [
      TradeLeg(
          instrument: MonthlyGasOption(
              name: 'TTFOPT',
              contractMonth: Month.utc(2023, 1),
              type: CallPut.call,
              strike: 50,
              underlyingName: 'TTF',
              volatilityName: 'TTFVOL'),
          tradeDate: Date.utc(2022, 1, 6),
          buySell: BuySell.buy,
          price: 8.25,
          quantity: 100 * 744,
          uom: Unit.mwh),
    ]),
    // Trade(legs: [
    //   TradeLeg(
    //       instrument: Futures(name: 'TTF', contractMonth: Month.utc(2023, 1)),
    //       tradeDate: Date.utc(2022, 1, 6),
    //       buySell: BuySell.sell,
    //       price: 29.0,
    //       quantity: 50 * 744,
    //       uom: Unit.mwh),
    // ]),
  ]);

  var strategy = DeltaHedging(
      initialPortfolio: portfolio,
      hedgeInstruments: [
        Futures(name: 'TTF', contractMonth: Month.utc(2023, 1)),
      ],
      tresholdDelta: 20 * 744);
  strategy.run([Date.utc(2022, 1, 7), Date.utc(2022, 1, 19)]);

  ///
  print(Table.from(strategy.report.map((e) => {
        'date': e['date'],
        'value': (e['value'] as num).round(),
      })));
}

Future<void> main() async {
  initializeTimeZones();
  setData();
  // tests();

  deltaHedgingStrategy();
}
