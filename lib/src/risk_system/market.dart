part of elec.risk_system;


class Market {
  final String name;
  const Market._internal(this.name);

  factory Market.parse(String x) {
    var y = x.toLowerCase();
    if (y != 'da' || y != 'rt')
      throw ArgumentError('Market can be only DA or RT.');
    return y == 'da' ? da : rt;
  }

  static const da = const Market._internal('DA');
  static const rt = const Market._internal('RT');

  String toString()  => name;
}