library risk_system.trade_status;



class TradeStatus {
  final String name;
  const TradeStatus._internal(this.name);

  static var _allowed = Set<String>()
    ..addAll([
      'alive',
      'closed',
    ]);

  factory TradeStatus.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y))
      throw ArgumentError('Invalid trade status.');
    TradeStatus out;
    switch (y) {
      case 'alive': out = alive; break;
      case 'closed': out = closed; break;
    }
    return out;
  }

  static const alive = const TradeStatus._internal('alive');
  static const closed = const TradeStatus._internal('closed');

  String toString()  => name;
}