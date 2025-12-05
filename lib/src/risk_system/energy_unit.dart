class Unit {
  final String name;
  const Unit._internal(this.name);

  static final _allowed = <String>{}
    ..addAll([
      'mwh',
      'mmbtu',
      'bbl',
    ]);

  factory Unit.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y)) {
      throw ArgumentError('Can\'t parse $x for energy unit.');
    }
    late Unit out;
    switch (y) {
      case 'mwh': out = mwh; break;
      case 'mmbtu': out = mmbtu; break;
      case 'bbl': out = bbl; break;
    }
    return out;
  }

  static const mwh = Unit._internal('MWh');
  static const mmbtu = Unit._internal('MMBTU');
  static const bbl = Unit._internal('BBL');

  @override
  String toString()  => name;
}