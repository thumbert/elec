part of elec.calculators.elec_swap;

/// One leaf per period (month or day).
class LeafElecSwap extends Leaf {
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
