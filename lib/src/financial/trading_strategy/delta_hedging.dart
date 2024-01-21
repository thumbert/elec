library financial.trading_strategy.delta_hedging;

import 'package:date/date.dart';
import 'package:elec/src/financial/trading_strategy/portfolio.dart';
import 'package:elec/src/financial/trading_strategy/trading_strategy.dart';

class DeltaHedging extends TradingStrategy {
  DeltaHedging(
      {required this.initialPortfolio,
      required this.hedgeInstruments,
      required this.tresholdDelta});

  Portfolio initialPortfolio;
  List<Instrument> hedgeInstruments;
  final num tresholdDelta;

  ///
  void run(List<Date> days) {
    for (var day in days) {
      // calculate portfolio delta
      // var delta = 
    }

  }

  /// When net portfolio delta
  // Portfolio
}
