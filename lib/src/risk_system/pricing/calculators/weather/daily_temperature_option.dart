import 'dart:math' show max;
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'weather_instrument.dart';

class DailyTemperatureOption extends WeatherInstrument {
  DailyTemperatureOption(
      {required BuySell buySell,
      required Interval term,
      required num quantity,
      required TimeSeries<num> strike,
      num maxPayoff = double.infinity,
      required this.callPut,
      String? airportCode,
      this.premium = 0}) {
    super.buySell = buySell;
    super.term = term;
    super.quantity = quantity;
    super.strike = strike;
    super.maxPayoff = maxPayoff;
    super.airportCode = airportCode;
    name = '$term $strike daily ${callPut.toString()} option';
  }

  num premium;
  CallPut callPut;

  @override
  TimeSeries<num> settlementValue() {
    var ts = TimeSeries<num>();
    var temps = temperature.window(term);
    for (var temp in temps) {
      var strike0 = strike.observationContains(temp.interval).value;
      num value;
      if (callPut == CallPut.call) {
        value = max(temp.value - strike0, 0);
      } else if (callPut == CallPut.put) {
        value = max(strike0 - temp.value, 0);
      } else {
        throw ArgumentError('Unknown $callPut');
      }
      ts.add(IntervalTuple(temp.interval, buySell.sign * quantity * value));
    }
    return ts;
  }

  /// Total value of this option over the term, including the premium
  @override
  num value() {
    var sValue = settlementValue();
    if (sValue.isEmpty) return double.nan;
    var payoff = settlementValue().sum();
    return payoff - buySell.sign * premium;
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'buySell': buySell,
      'callPut': callPut,
      'quantity': quantity,
      'strike': strike,
      'term': term,
      'maxPayoff': maxPayoff,
      'premium': premium,
      'airportCode': airportCode,
      'name': name,
    };
  }

  /// Construct this option from a Map
  static DailyTemperatureOption fromJson(Map<String, dynamic> x) {
    String instrument = x['instrumentType'];
    if (instrument != 'Daily T call' || instrument != 'Daily T put') {
      throw ArgumentError('Wrong instrument ${x['instrumentType']}');
    }

    if (!x.containsKey('buySell')) {
      throw ArgumentError('Missing buySell key');
    }
    var buySell = BuySell.parse(x['buySell']);

    x['callPut'] = (x['instrumentType'] as String).replaceAll('Daily T ', '');
    var callPut = CallPut.parse(x['callPut']);

    if (!x.containsKey('quantity')) {
      throw ArgumentError('Missing quantity key');
    }
    var quantity = x['quantity'];

    if (!x.containsKey('strike')) {
      throw ArgumentError('Missing strike key');
    }
    var strike = x['strike'];

    if (!x.containsKey('term')) {
      throw ArgumentError('Missing term key');
    }
    var term = parseTerm(x['term'])!;

    num maxPayoff;
    if (x.containsKey('maxPayoff') && x['maxPayoff'] == 'NA') {
      maxPayoff = double.infinity;
    } else {
      maxPayoff = x.putIfAbsent('maxPayoff', () => double.infinity);
    }
    var premium = x['premium'] ?? 0.0;
    String? airportCode;
    if (x.containsKey('airportCode')) {
      airportCode = (x['airportCode'] as String).toUpperCase();
    }

    String name;
    if (x.containsKey('name')) {
      /// if there is a custom name
      name = x['name'];
    } else {
      name = '$term ${strike}F daily ${callPut.toString()}';
    }

    if (callPut == CallPut.call) {
      return DailyTemperatureOption(
          buySell: buySell,
          term: term,
          quantity: quantity,
          strike: strike,
          maxPayoff: maxPayoff,
          callPut: CallPut.call,
          premium: premium)
        ..airportCode = airportCode
        ..name = name;
    } else if (callPut == CallPut.put) {
      return DailyTemperatureOption(
          buySell: buySell,
          term: term,
          quantity: quantity,
          strike: strike,
          maxPayoff: maxPayoff,
          callPut: CallPut.put,
          premium: premium)
        ..airportCode = airportCode
        ..name = name;
    } else {
      throw StateError('Unsupported type $callPut');
    }
  }
}
