import 'dart:math';

class CddHdd implements Comparable<CddHdd> {
  final String name;
  final num Function(num) payoff;
  final int value;

  static num _cdd(num temperature) => max(temperature - 65, 0);
  static num _hdd(num temperature) => max(65 - temperature, 0);

  const CddHdd._internal(this.name, this.payoff, this.value);

  factory CddHdd.parse(String x) {
    var y = x.toLowerCase();
    if (y != 'cdd' && y != 'hdd') {
      throw ArgumentError('Can\'t parse $x for IndexType.');
    }
    return y == 'cdd' ? cdd : hdd;
  }

  static const cdd = CddHdd._internal('Cdd', _cdd, 0);
  static const hdd = CddHdd._internal('Hdd', _hdd, 1);

  @override
  String toString() => name;

  @override
  int compareTo(CddHdd other) => value.compareTo(other.value);
}
