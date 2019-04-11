part of elec.risk_system;


class BuySell {
  final int sign;
  const BuySell._internal(this.sign);

  factory BuySell.parse(String x) {
    var y = x.toLowerCase();
    if (y != 'buy' && y != 'sell')
      throw ArgumentError('Can\'t parse $x for BuySell.');
    return y == 'buy' ? buy : sell;
  }

  static const buy = const BuySell._internal(1);
  static const sell = const BuySell._internal(-1);

  String toString()  => sign == 1 ? 'Buy' : 'Sell';
}