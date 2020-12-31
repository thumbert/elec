library elec.risk_system.pricing.calculators.base.calculator_base;

import 'package:elec/elec.dart';

import 'calculator_base.dart';
import 'leaf.dart';

abstract class CommodityLeg extends CalculatorBase {
  Bucket bucket;

  /// Leg leaves
  List<Leaf> leaves;

  /// Fair value for this commodity leg.
  /// Get the quantity weighted floating price for this leg.
  /// Needs [leaves] to be populated.
  num price();

  Map<String, dynamic> toJson();
}
