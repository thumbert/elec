library temperature.temperature_swap;

import 'dart:async';
import 'package:http/http.dart';
import 'dart:math' show max, min;
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'lib_temperature_data.dart';
import '../common_enums.dart';

enum IndexType { cdd, hdd }

/// Calculate the HDD index: max(65-T,0)
num hdd(num temperature) => max(65 - temperature, 0);
/// Calculate the CDD index: max(T-65,0)
num cdd(num temperature) => max(temperature - 65, 0);

final Map _sign = {BuySell.buy: 1, BuySell.sell: -1};

abstract class WeatherInstrument {
  BuySell buySell;
  num quantity;
  String airportCode;
  Interval term;
  num value(List<num> index);
}

class TemperatureSwap implements WeatherInstrument {
  BuySell buySell;
  IndexType indexType;
  num quantity;
  num strike;
  Interval term;
  /// limits both the loss and the gain
  num maxPayoff;
  String airportCode;

  Function _function;
  num _nDays;

  /// A daily temperature swap (usually a monthly term, but may be a seasonal
  /// term too.)
  /// <br>[indexType] CDD or HDD.
  /// <br>[quantity] the tick size.
  /// <br>[maxPayoff] limits the positive payoff.
  /// <br>[maxLoss] limits the negative payoff
  TemperatureSwap(this.buySell, this.term, this.indexType, this.quantity,
      this.strike, this.airportCode, {this.maxPayoff}) {
    switch (indexType) {
      case IndexType.cdd:
        _function = cdd;
        break;
      case IndexType.hdd:
        _function = hdd;
        break;
      default:
        throw 'Unknown indexType!';
    }
    if (maxPayoff < 0)
      throw new ArgumentError('maxPayoff needs to be > 0');

    /// calculate the number of days in the term
    _nDays = new TimeIterable(new Date.fromTZDateTime(term.start),
        new Date.fromTZDateTime(term.end).subtract(1))
        .toList()
        .length;
  }

  /// Value the temperature swap if you know the daily temperature
  num value(List<num> index) {
    if (_nDays != index.length)
      throw 'Index doesn\'t have complete data for the term ' + term.toString();
    num cumulativeIndex = index
        .map((num temperature) => _function(temperature))
        .reduce((a, b) => a + b);
    return payoff(cumulativeIndex);
  }
  
  /// Value the temperature swap if you know the cumulative index.
  num payoff(num cumulativeIndex) {
    var value = _sign[buySell] * quantity * (cumulativeIndex - strike);
    if (maxPayoff != null) {
      if (value > 0) {
        value = min(value, maxPayoff);
      } else {
        value = max(value, -maxPayoff);
      }
    }
    return value;
  }
}


/// Historical valuation of this weather instrument.  To save clobbering the
/// DB, you can pass in the historical temperatures.
Future<Map> historicalValuation(WeatherInstrument instrument,
    {TimeSeries hData, Client client}) async {
  hData ??= await getDailyHistoricalTemperature(instrument.airportCode,
      instrument.term, client: client);

  var temps = hData.window(instrument.term).map((e) => e.value);

  return {
    'value': instrument.value(temps),
    'temperature': temps,
  };
}


