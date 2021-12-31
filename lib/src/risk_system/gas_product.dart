part of elec.risk_system;

class GasProduct {
  final String _name;
  const GasProduct._internal(this._name);

  static final _allowed = <String, GasProduct>{
    'iferc': iferc,
    'if': iferc,
    'gasdaily': gasDaily,
    'gd': gasDaily,
    'gdd': gasDaily,
    'gdm': gasDaily,
    'physical': physical,
    'phys': physical,
  };

  factory GasProduct.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.keys.contains(y)) {
      throw ArgumentError('Can\'t parse $x for a GasProduct.');
    }
    return _allowed[y]!;
  }

  static const iferc = GasProduct._internal('IFerc');
  static const gasDaily = GasProduct._internal('GasDaily');
  static const physical = GasProduct._internal('Physical');

  @override
  String toString() => _name;
}
