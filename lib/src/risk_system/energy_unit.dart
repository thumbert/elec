part of elec.risk_system;


class Unit {
  final String name;
  const Unit._internal(this.name);

  static var _allowed = Set<String>()
    ..addAll([
      'mwh',
      'mmbtu',
      'bbl',
    ]);

  factory Unit.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y))
      throw ArgumentError('Can\'t parse $x for energy unit.');
    Unit out;
    switch (y) {
      case 'mwh': out = mwh; break;
      case 'mmbtu': out = mmbtu; break;
      case 'bbl': out = bbl; break;
    }
    return out;
  }

  static const mwh = const Unit._internal('MWh');
  static const mmbtu = const Unit._internal('MMBTU');
  static const bbl = const Unit._internal('BBL');

  String toString()  => name;
}