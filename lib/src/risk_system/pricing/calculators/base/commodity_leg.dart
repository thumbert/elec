library elec.risk_system.pricing.calculators.base.calculator_base;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'leaf.dart';

abstract class CommodityLegBase<L extends LeafBase> {
  late Date asOfDate;
  late Term term;
  late BuySell buySell;
  late Bucket bucket;

  /// Leg leaves
  late List<L> leaves;

  /// Fair value for this commodity leg.
  /// Get the quantity weighted floating price for this leg.
  /// Needs [leaves] to be populated.
  num price();

  Map<String, dynamic> toJson();
}
