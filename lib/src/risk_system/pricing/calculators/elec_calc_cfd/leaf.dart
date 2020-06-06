part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

/// One leaf per period.
class Leaf {
  BuySell buySell;
  Interval interval;
  num quantity;
  num fixPrice;
  num floatingPrice;
  /// number of hours in this period
  int hours;

  Leaf(this.buySell, this.interval, this.quantity, this.fixPrice,
      this.floatingPrice, this.hours);

  num dollarPrice() {
    return buySell.sign * hours * quantity * (floatingPrice - fixPrice);
  }
}
