import 'dart:math' show min, max;
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'index_swap.dart';
import 'index_option.dart';
import 'daily_temperature_option.dart';

mixin CappedValue {
  /// Maximum payoff for this instrument over the entire term.  Should always
  /// be a positive.  Limits both the loss and the gain in the deal.
  late num maxPayoff;

  num cappedValue(num value) {
    if (maxPayoff <= 0) throw ArgumentError('maxPayoff needs to be => 0');
    if (value > 0) {
      value = min(value, maxPayoff);
    } else {
      value = max(value, -maxPayoff);
    }
    return value;
  }
}

abstract class WeatherInstrument extends Object with CappedValue {
  late BuySell buySell;
  late num quantity;
  late Interval term;

  /// A monthly timeseries, or a one element timeseries corresponding to the
  /// entire term for the fixed leg of a swap, or the option strike.
  late TimeSeries<num> strike;

  /// Calculate the payoff (value without the premium).
  /// at the time frequency you have the strike.
  /// Return a monthly timeseries if the strike is monthly, or a one element
  /// time series if the strike is one value for the entire term.
  TimeSeries<num> settlementValue();

  /// total realized deal value excluding the premium (floating leg only.)
  num value();

  /// optional label
  String? name;

  /// three letter airport code, needed for historical valuation
  String? airportCode;

  /// Daily UTC temperature series to value the weather instrument.
  late TimeSeries<num> temperature;

  /// for serialization
  Map<String, dynamic> toMap();

  static const indexOptionInstruments = <String>{
    'CDD call',
    'CDD put',
    'HDD call',
    'HDD put',
  };

  /// Parse a deal from a [Map].
  ///
  static WeatherInstrument fromJson(Map<String, dynamic> x) {
    String instrument = x['instrumentType'];
    if (instrument == 'CDD swap' || instrument == 'HDD swap') {
      return IndexSwap.fromJson(x);
    } else if (indexOptionInstruments.contains(instrument)) {
      return IndexOption.fromJson(x);
    } else if ({'Daily T call', 'Daily T put'}.contains(x['instrumentType'])) {
      return DailyTemperatureOption.fromJson(x);
    } else {
      throw ArgumentError(
          'Instrument ${x['instrumentType']} not yet supported');
    }
  }
}
