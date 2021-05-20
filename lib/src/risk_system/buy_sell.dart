part of elec.risk_system;

class BuySell {
  final int sign;
  const BuySell._internal(this.sign);

  BuySell.fromSign(this.sign) {
    if (sign != 1 && sign != -1) {
      throw ArgumentError('Invalid sign value $sign');
    }
  }

  factory BuySell.parse(String x) {
    var y = x.toLowerCase();
    if (y != 'buy' && y != 'sell') {
      throw ArgumentError('Can\'t parse $x for BuySell.');
    }
    return y == 'buy' ? buy : sell;
  }

  static const buy = BuySell._internal(1);
  static const sell = BuySell._internal(-1);

  @override
  String toString() => sign == 1 ? 'Buy' : 'Sell';

  @override
  bool operator ==(dynamic other) {
    if (other is! BuySell) return false;
    var bs = other;
    return bs.sign == sign;
  }

  @override
  int get hashCode => sign;
}
