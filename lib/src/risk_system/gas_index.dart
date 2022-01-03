part of elec.risk_system;

class GasIndex {
  final String _name;
  const GasIndex._internal(this._name);

  static final _allowed = <String, GasIndex>{
    'iferc': iferc,
    'if': iferc,
    'gasdaily': gasDaily,
    'gd': gasDaily,
    'gdd': gasDaily,
    'gdm': gasDaily,
    'physical': physical,
    'phys': physical,
  };

  factory GasIndex.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.keys.contains(y)) {
      throw ArgumentError('Can\'t parse $x for a GasProduct.');
    }
    return _allowed[y]!;
  }

  static const iferc = GasIndex._internal('IFerc');
  static const gasDaily = GasIndex._internal('GasDaily');
  static const physical = GasIndex._internal('Physical');

  @override
  String toString() => _name;
}
