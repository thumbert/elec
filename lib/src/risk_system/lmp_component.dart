part of elec.risk_system;


class LmpComponent {
  final String name;
  const LmpComponent._internal(this.name);

  static var _allowed = Set<String>()
    ..addAll([
      'energy',
      'lmp',
      'congestion',
      'loss',
    ]);

  static const energy = const LmpComponent._internal('energy');
  static const lmp = const LmpComponent._internal('lmp');
  static const congestion = const LmpComponent._internal('congestion');
  static const loss = const LmpComponent._internal('loss');

  factory LmpComponent.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y))
      throw ArgumentError('Can\'t parse $x as an LMP component.');

    LmpComponent out;
    if (y == 'energy') {
      out = energy;
    } else if (y == 'lmp') {
      out = lmp;
    } else if (y == 'congestion') {
      out = congestion;
    } else if (y == 'loss') {
      out = loss;
    }

    return out;
  }



  String toString()  => name;
}