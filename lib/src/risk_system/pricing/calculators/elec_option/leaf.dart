library risk_system.pricing.calculators.elec_option.leaf;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/financial/black_scholes/black_scholes.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/leaf.dart';
import 'package:elec/src/time/last_trading_day.dart';

class LeafElecOption extends LeafBase {
  LeafElecOption({
    required this.asOfDate,
    required this.buySell,
    required this.callPut,
    required this.month,
    required this.quantityTerm,
    required this.riskFreeRate,
    required this.strike,
    required this.underlyingPrice,
    required this.volatility,
    required this.fixPrice,
  }) : expirationDate = lastBusinessDayBefore(month.startDate) {
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

  /// the notional volume for the option, in MWh
  final num quantityTerm;
  final num underlyingPrice;
  final num strike;
  final CallPut callPut;
  final num volatility;
  final Date asOfDate;
  final num riskFreeRate;
  final Date expirationDate;

  final num fixPrice;

  late BlackScholes _bs;

  /// The option price
  num price() => _bs.value();

  /// The delta of the option
  num delta() => _bs.delta();

  /// The gamma of the option
  num gamma() => _bs.gamma();

  /// The vega of the option
  num vega() => _bs.vega();

  @override
  num dollarPrice() => buySell.sign * quantityTerm * (_bs.value() - fixPrice);

  LeafElecOption copyWith({
    Date? asOfDate,
    BuySell? buySell,
    CallPut? callPut,
    Month? month,
    num? quantityTerm,
    num? riskFreeRate,
    num? strike,
    num? underlyingPrice,
    num? volatility,
    num? fixPrice,
  }) {
    var _asOfDate = asOfDate ?? this.asOfDate;
    var _buySell = buySell ?? this.buySell;
    var _callPut = callPut ?? this.callPut;
    var _month = month ?? this.month;
    var _quantityTerm = quantityTerm ?? this.quantityTerm;
    var _riskFreeRate = riskFreeRate ?? this.riskFreeRate;
    var _strike = strike ?? this.strike;
    var _underlyingPrice = underlyingPrice ?? this.underlyingPrice;
    var _volatility = volatility ?? this.volatility;
    var _fixPrice = fixPrice ?? this.fixPrice;

    return LeafElecOption(
        asOfDate: _asOfDate,
        buySell: _buySell,
        callPut: _callPut,
        month: _month,
        quantityTerm: _quantityTerm,
        riskFreeRate: _riskFreeRate,
        strike: _strike,
        underlyingPrice: _underlyingPrice,
        volatility: _volatility,
        fixPrice: _fixPrice);
  }
}
