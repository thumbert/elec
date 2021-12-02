library risk_system.trade_status;



class TradeStatus {
  final String name;
  const TradeStatus._internal(this.name);

  static final _allowed = <String>{}
    ..addAll([
      'live',
      'closed',
    ]);

  factory TradeStatus.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y)) {
      throw ArgumentError('Invalid trade status.');
    }
    late TradeStatus out;
    switch (y) {
      case 'live': out = live; break;
      case 'closed': out = closed; break;
    }
    return out;
  }

  static const live = TradeStatus._internal('live');
  static const closed = TradeStatus._internal('closed');

  @override
  String toString()  => name;
}