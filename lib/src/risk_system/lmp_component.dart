part of '../../risk_system.dart';

class LmpComponent {
  final String name;
  const LmpComponent._internal(this.name);

  static const energy = LmpComponent._internal('energy');
  static const lmp = LmpComponent._internal('lmp');
  static const congestion = LmpComponent._internal('congestion');
  static const loss = LmpComponent._internal('loss');
  static const lossPercent = LmpComponent._internal('loss%');

  factory LmpComponent.parse(String x) {
    var y = x.toLowerCase();
    if (y == 'energy') {
      return energy;
    } else if (y == 'lmp') {
      return lmp;
    } else if (y == 'congestion' || y == 'mcc') {
      return congestion;
    } else if (y == 'loss' || y == 'mcl' || y == 'mlc') {
      return loss;
    } else if (y == 'loss%') {
      return lossPercent;
    } else {
      throw ArgumentError('Can\'t parse $x as an LMP component.');
    }
  }

  String shortName() {
    switch (this) {
      case LmpComponent.energy:
        return 'energy';
      case LmpComponent.lmp:
        return 'lmp';
      case LmpComponent.congestion:
        return 'mcc';
      case LmpComponent.loss:
        return 'mlc';
      case LmpComponent.lossPercent:
        return 'loss%';
      case _:
        throw StateError('Unrecognized LMP component: $this');  
    }
  }

  @override
  String toString() => name;
}
