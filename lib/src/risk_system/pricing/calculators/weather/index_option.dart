library risk_system.pricing.calculators.weather.index_option;

import 'dart:math' as math;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'cdd_hdd.dart';
import 'weather_instrument.dart';

class CddOption extends WeatherInstrument with IndexOption {
  CddOption(
      {required BuySell buySell,
      required Interval term,
      required num quantity,
      required TimeSeries<num> strike,
      num maxPayoff = double.infinity,
      required CallPut callPut,
      String? airportCode,
      num premium = 0}) {
    super.buySell = buySell;
    super.cddHdd = CddHdd.cdd;
    super.term = term;
    super.quantity = quantity;
    super.strike = strike;
    super.maxPayoff = maxPayoff;
    super.callPut = callPut;
    super.airportCode = airportCode;
    super.premium = premium;
    name = '$term $strike ${cddHdd.toString()} ${callPut.toString()} option';
  }
}

class HddOption extends WeatherInstrument with IndexOption {
  HddOption(
      {required BuySell buySell,
      required Interval term,
      required num quantity,
      required TimeSeries<num> strike,
      num maxPayoff = double.infinity,
      required CallPut callPut,
      String? airportCode,
      num premium = 0}) {
    super.buySell = buySell;
    super.cddHdd = CddHdd.hdd;
    super.term = term;
    super.quantity = quantity;
    super.strike = strike;
    super.maxPayoff = maxPayoff;
    super.callPut = callPut;
    super.airportCode = airportCode;
    super.premium = premium;
    name = '$term $strike ${cddHdd.toString()} ${callPut.toString()} option';
  }
}

mixin IndexOption on WeatherInstrument {
  late CddHdd cddHdd;

  late CallPut callPut;

  /// Option premium
  late num premium;

  /// Calculate the daily CDD or HDD index
  TimeSeries<num> dailyIndex() {
    return TimeSeries.fromIterable(temperature
        .window(term)
        .map((e) => IntervalTuple(e.interval, cddHdd.payoff(e.value))));
  }

  /// Calculate option payoff (value without the premium).
  /// at the frequency you have the strike.
  /// Return a monthly timeseries if the strike is monthly, or a one element
  /// time series if the strike is one value for the entire term.
  /// For intra-month calculations, the strike gets prorated.
  ///
  @override
  TimeSeries<num> settlementValue() {
    var dIndex = dailyIndex();
    var grp = <Interval, TimeSeries<num>>{};
    for (var e in strike) {
      grp[e.interval] = TimeSeries.fromIterable(dIndex.window(e.interval));
    }

    var out = TimeSeries<num>();
    for (var entry in grp.entries) {
      var dayCount =
          entry.key.splitLeft((dt) => Date.fromTZDateTime(dt)).length;
      var multiplier = 1 / dayCount;
      var _strike = multiplier * strike.observationContains(entry.key).value;
      var index = entry.value.sum();
      var n = entry.value.length;
      num value;
      if (callPut == CallPut.call) {
        value = buySell.sign * quantity * math.max(index - _strike * n, 0);
      } else if (callPut == CallPut.put) {
        value = buySell.sign * quantity * math.max(_strike * n - index, 0);
      } else {
        throw ArgumentError('Unimplemented $callPut');
      }
      out.add(IntervalTuple(entry.key, value));
    }
    return out;
  }

  /// Total value of the CDD/HDD index for the term.
  /// Return nan if there is no data
  num cumulativeIndex() {
    if (dailyIndex().isEmpty) return double.nan;
    return dailyIndex().values.reduce((a, b) => a + b);
  }

  /// Value of the swap for the entire term
  @override
  num value() {
    var sValue = settlementValue();
    if (sValue.isEmpty) return double.nan;
    return settlementValue().sum();
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'buySell': buySell.toString(),
      'cddHdd': cddHdd.toString(),
      'callPut': callPut.toString(),
      'quantity': quantity,
      'strike': strike,
      'term': term.toString(),
      'maxPayoff': maxPayoff,
      if (airportCode != null) 'airportCode': airportCode,
      'name': name,
    };
  }

  static WeatherInstrument fromJson(Map<String, dynamic> x) {
    String instrument = x['instrumentType'];
    if (!WeatherInstrument.indexOptionInstruments.contains(instrument)) {
      throw ArgumentError('Wrong instrument ${x['instrumentType']}');
    }
    var cddHdd = CddHdd.parse(instrument.substring(0, 3));
    var buySell = BuySell.parse(x['buySell']);
    var quantity = x['quantity'] as num;
    var term = Term.parse(x['term'], UTC).interval;
    var strike = TimeSeries<num>();

    /// The value of the 'strike' key can be either a number
    /// or a TimeSeries as a monthly map.
    if (x['strike'] is num) {
      strike = TimeSeries<num>()..add(IntervalTuple(term, x['strike']));
    } else {
      // it's a map {'Jun20': 139, 'Jul20': 340}
      strike = TimeSeries<num>();
      for (var entry in (x['strike'] as Map).entries) {
        strike.add(
            IntervalTuple(Term.parse(entry.key, UTC).interval, entry.value));
      }
    }
    var maxPayoff = double.maxFinite;
    if (x.containsKey('maxPayoff')) {
      if (x['maxPayoff'] is num) {
        maxPayoff = x['maxPayoff'];
      }
    }
    var callPut = CallPut.parse(instrument.substring(4));
    var premium = x['premium'] ?? 0;

    String? airportCode;
    if (x.containsKey('airportCode')) {
      airportCode = (x['airportCode'] as String).toUpperCase();
    }
    if (cddHdd == CddHdd.cdd) {
      return CddOption(
        buySell: buySell,
        term: term,
        quantity: quantity,
        strike: strike,
        maxPayoff: maxPayoff,
        callPut: callPut,
        premium: premium,
      )..airportCode = airportCode;
    } else if (cddHdd == CddHdd.hdd) {
      return HddOption(
        buySell: buySell,
        term: term,
        quantity: quantity,
        strike: strike,
        maxPayoff: maxPayoff,
        callPut: callPut,
        premium: premium,
      )..airportCode = airportCode;
    } else {
      throw StateError('Unsupported index $cddHdd');
    }
  }
}
