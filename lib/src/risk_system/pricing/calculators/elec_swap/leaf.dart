import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/leaf.dart';

/// One leaf per period (month or day).
class LeafElecSwap extends LeafBase {
  BuySell buySell;
  Interval interval;
  num quantity;
  num fixPrice;
  num floatingPrice;

  /// number of hours in this period
  int hours;

  LeafElecSwap(this.buySell, this.interval, this.quantity, this.fixPrice,
      this.floatingPrice, this.hours);

  @override
  num dollarPrice() {
    return buySell.sign * hours * quantity * (floatingPrice - fixPrice);
  }
}
