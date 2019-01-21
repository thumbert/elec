part of elec.risk_system;

class Commodity {
  final String shortName;
  final String longName;

  static var _allowed = Set<String>()
    ..addAll([
      'pwr',
      'energy',
      'ng',
      'natural gas',
      'fo2',
      'fuel oil #2',
      'fo6',
      'fuel oil #6',
    ]);

  const Commodity._internal(this.shortName, this.longName);

  static const energy = const Commodity._internal('Pwr', 'Energy');
  static const ng = const Commodity._internal('Ng', 'Natual Gas');
  static const fo2 = const Commodity._internal('Fo2', 'Fuel Oil #2');
  static const fo6 = const Commodity._internal('Fo6', 'Fuel Oil #6');

  factory Commodity.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y))
      throw ArgumentError('Can\'t parse $x as a Commodity.');

    Commodity out;
    if (y == 'pwr' || y == 'energy') {
      out = energy;
    } else if (y == 'ng' || y == 'natural gas') {
      out = ng;
    } else if (y == 'fo2' || y == 'fuel oil #2') {
      out = fo2;
    } else if (y == 'fo6' || y == 'fuel oil #6') {
      out = fo6;
    }

    return out;
  }

}
