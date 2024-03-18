part of '../../risk_system.dart';

class NodeType {
  final String _name;
  const NodeType._internal(this._name);

  static final _allowed = <String, NodeType>{
    'hub': hub,
    'interface': interface,
    'zone': zone,
    'gen': gen,
    'generation': gen,
    'generator': gen,
    'load': load,
  };

  factory NodeType.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.keys.contains(y)) {
      throw ArgumentError('Unrecognized NodeType $x.');
    }
    return _allowed[y]!;
  }

  static const hub = NodeType._internal('hub');
  static const interface = NodeType._internal('interface');
  static const zone = NodeType._internal('zone');
  static const gen = NodeType._internal('gen');
  static const load = NodeType._internal('load');

  @override
  String toString() => _name;

  @override
  bool operator ==(Object other) {
    if (other is! NodeType) return false;
    return other._name == _name;
  }

  @override
  int get hashCode => _name.hashCode;
}
