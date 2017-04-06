library temperature.temperature_swap;

import 'dart:math' show max, min;
import 'package:date/date.dart';

enum IndexType { CDD, HDD }
enum BuySell { Buy, Sell }

num hdd(num temperature) => max(65 - temperature, 0);
num cdd(num temperature) => max(temperature - 65, 0);
final Map _sign = {BuySell.Buy: 1, BuySell.Sell: -1};

abstract class WeatherInstrument {
  num value(List<num> index);
}

class TemperatureSwap implements WeatherInstrument {
  final BuySell buySell;
  final IndexType indexType;
  final num quantity;
  final num strike;
  final Interval term;
  final num maxPayoff;

  Function _function;
  num _nDays;

  /// A daily temperature swap (usually a monthly term, but may be a seasonal
  /// term too.)
  /// <br>[indexType] CDD or HDD.
  /// <br>[quantity] the tick size.
  /// <br>[maxPayoff] limits the positive payoff.  The downside is not limited.
  TemperatureSwap(this.buySell, this.term, this.indexType, this.quantity,
      this.strike, this.maxPayoff) {
    switch (indexType) {
      case IndexType.CDD:
        _function = cdd;
        break;
      case IndexType.HDD:
        _function = hdd;
        break;
      default:
        throw 'Unknown indexType!';
    }

    /// calculate the number of days in the term
    _nDays = new TimeIterable(new Date.fromDateTime(term.start),
        new Date.fromDateTime(term.end).subtract(1))
        .toList()
        .length;
  }

  /// Value the temperature swap
  num value(List<num> index) {
    if (_nDays != index.length)
      throw 'Index doesn\'t have complete data for the term ' + term.toString();
    num cumIndex = index
        .map((num temperature) => _function(temperature))
        .reduce((a, b) => a + b);
    return _sign[buySell] * quantity * min(cumIndex - strike, maxPayoff);
  }
}

