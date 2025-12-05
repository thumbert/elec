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
    return LeafElecOption(
        asOfDate: asOfDate ?? this.asOfDate,
        buySell: buySell ?? this.buySell,
        callPut: callPut ?? this.callPut,
        month: month ?? this.month,
        quantityTerm: quantityTerm ?? this.quantityTerm,
        riskFreeRate: riskFreeRate ?? this.riskFreeRate,
        strike: strike ?? this.strike,
        underlyingPrice: underlyingPrice ?? this.underlyingPrice,
        volatility: volatility ?? this.volatility,
        fixPrice: fixPrice ?? this.fixPrice);
  }
}
