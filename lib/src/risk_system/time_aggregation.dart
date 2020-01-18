part of elec.risk_system;

class TimeAggregation {
  final String name;
  const TimeAggregation._internal(this.name);

  static final _allowed = <String>{
    'hour',
    'day',
    'month',
    'year',
    'term',
  };

  factory TimeAggregation.parse(String x) {
    var y = x.toLowerCase();
    if (!_allowed.contains(y)) {
      throw ArgumentError('Invalid time aggregation value $x');
    }
    TimeAggregation out;
    switch (y) {
      case 'hour':
        out = hour;
        break;
      case 'day':
        out = day;
        break;
      case 'month':
        out = month;
        break;
      case 'year':
        out = year;
        break;
      case 'term':
        out = term;
        break;  
    }
    return out;
  }

  static const hour = TimeAggregation._internal('hour');
  static const day = TimeAggregation._internal('day');
  static const month = TimeAggregation._internal('month');
  static const year = TimeAggregation._internal('year');
  static const term = TimeAggregation._internal('term');
  
  @override
  String toString() => name;
}
