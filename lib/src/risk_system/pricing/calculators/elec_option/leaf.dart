library risk_system.pricing.calculators.elec_option.leaf;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/financial/black_scholes/black_scholes.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/leaf.dart';
import 'package:elec/src/time/last_trading_day.dart';

class LeafElecOption extends LeafBase {
  LeafElecOption({
    this.asOfDate,
    this.buySell,
    this.callPut,
    this.month,
    this.quantity,
    this.riskFreeRate,
    this.strike,
    this.underlyingPrice,
    this.volatility,
    this.fixPrice,
    this.hours,
  }) : expirationDate = lastBusinessDayPrior(month) {
    _bs = BlackScholes(
        type: callPut,
        strike: strike,
        expirationDate: expirationDate,
        asOfDate: asOfDate,
        underlyingPrice: underlyingPrice,
        volatility: volatility,
        riskFreeRate: riskFreeRate);
  }

  final BuySell buySell;
  final Month month;
  final num quantity;
  final num underlyingPrice;
  final num strike;
  final CallPut callPut;
  final num volatility;
  final Date asOfDate;
  final num riskFreeRate;
  final Date expirationDate;

  final num fixPrice;

  /// number of hours in this period
  final int hours;

  BlackScholes _bs;

  /// The option price
  num price() => _bs.value();

  /// The delta of the option
  num delta() => _bs.delta();

  @override
  num dollarPrice() =>
      buySell.sign * hours * quantity * (_bs.value() - fixPrice);
}
