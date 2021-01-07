library risk_system.pricing.calculators.elec_option.leaf;

import 'package:date/date.dart';
import 'package:elec/calculators.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/financial/black_scholes/black_scholes.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/calculator_base.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/leaf.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/commodity_leg_monthly.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/cache_provider.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

class LeafElecOption extends Leaf {
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
  }) {
    // _bs = BlackScholes(type: callPut, )
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

  BlackScholes _bs;

  @override
  num dollarPrice() {}
}
