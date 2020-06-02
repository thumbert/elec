part of elec.risk_system;


class LmpComponent {
  final String name;
  const LmpComponent._internal(this.name);

  static const energy = LmpComponent._internal('energy');
  static const lmp = LmpComponent._internal('lmp');
  static const congestion = LmpComponent._internal('congestion');
  static const loss = LmpComponent._internal('loss');

  factory LmpComponent.parse(String x) {
    var y = x.toLowerCase();
    if (y == 'energy') {
      return energy;
    } else if (y == 'lmp') {
      return lmp;
    } else if (y == 'congestion') {
      return congestion;
    } else if (y == 'loss') {
      return loss;
    } else {
      throw ArgumentError('Can\'t parse $x as an LMP component.');
    }
  }

  @override
  String toString()  => name;
}