part of elec.risk_system;

class TimeAggregation {
  final String name;
  const TimeAggregation._internal(this.name);

  static var _allowed = <String>{
    'hourly',
    'daily',
    'monthly',
    'yearly',
    'byInterval',
  };

  factory TimeAggregation.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y))
      throw ArgumentError('Invalid time aggregation value $x');
    TimeAggregation out;
    switch (y) {
      case 'hourly':
        out = hourly;
        break;
      case 'daily':
        out = daily;
        break;
      case 'monthly':
        out = monthly;
        break;
      case 'yearly':
        out = yearly;
        break;
      case 'byInterval':
        out = byInterval;
        break;  
    }
    return out;
  }

  static const hourly = const TimeAggregation._internal('hourly');
  static const daily = const TimeAggregation._internal('daily');
  static const monthly = const TimeAggregation._internal('monthly');
  static const yearly = const TimeAggregation._internal('yearly');
  static const byInterval = const TimeAggregation._internal('byInterval');
  
  String toString() => name;
}
