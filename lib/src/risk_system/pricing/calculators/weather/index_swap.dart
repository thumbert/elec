library risk_system.pricing.calculators.weather.index_swap;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/weather/cdd_hdd.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'weather_instrument.dart';

class CddSwap extends WeatherInstrument with IndexSwap {
  CddSwap(
      {required BuySell buySell,
      required Interval term,
      required num quantity,
      required TimeSeries<num> strike,
      num maxPayoff = double.infinity}) {
    super.buySell = buySell;
    super.cddHdd = CddHdd.cdd;
    super.term = term;
    super.quantity = quantity;
    super.strike = strike;
    super.maxPayoff = maxPayoff;
    name = '$term $strike CDD swap';
  }
}

class HddSwap extends WeatherInstrument with IndexSwap {
  HddSwap(
      {required BuySell buySell,
      required Interval term,
      required num quantity,
      required TimeSeries<num> strike,
      num maxPayoff = double.infinity}) {
    super.buySell = buySell;
    super.cddHdd = CddHdd.hdd;
    super.term = term;
    super.quantity = quantity;
    super.strike = strike;
    super.maxPayoff = maxPayoff;
    name = '$term $strike HDD swap';
  }
}

mixin IndexSwap on WeatherInstrument {
  late CddHdd cddHdd;

  /// Calculate the daily CDD or HDD index
  TimeSeries<num> dailyIndex() {
    return TimeSeries.fromIterable(temperature
        .window(term)
        .map((e) => IntervalTuple(e.interval, cddHdd.payoff(e.value))));
  }

  /// Calculates the value assuming the strike realizes ratably over the term
  /// or month.
  @override
  TimeSeries<num> settlementValue() {
    var dIndex = dailyIndex();
    Map<Interval?, TimeSeries<num>> grp;
    if (strike.length > 1) {
      grp = dIndex
          .splitByIndex((interval) => Month.fromTZDateTime(interval.start));
    } else {
      grp = {term: dIndex};
    }
    var out = TimeSeries<num>();
    for (var entry in grp.entries) {
      var days = entry.key!.splitLeft((dt) => Date.fromTZDateTime(dt)).length;
      var multiplier = 1 / days;
      var _strike = multiplier * strike.observationContains(entry.key!).value;
      out.addAll(entry.value.map((obs) => IntervalTuple(
          obs.interval, buySell.sign * quantity * (obs.value - _strike))));
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
    if (instrument != 'CDD swap' || instrument != 'HDD swap') {
      throw ArgumentError('Wrong instrument ${x['instrumentType']}');
    }
    var cddHdd = CddHdd.parse(instrument.substring(0, 3));
    var buySell = BuySell.parse(x['buySell']);
    var quantity = x['quantity'] as num;
    var term = Term.parse(x['term'], UTC).interval;
    var strike = TimeSeries<num>();

    /// The value of 'strike' key can be either a number
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
    var airportCode = (x['airportCode'] as String).toUpperCase();
    if (cddHdd == CddHdd.cdd) {
      return CddSwap(
          buySell: buySell,
          term: term,
          quantity: quantity,
          strike: strike,
          maxPayoff: maxPayoff)
        ..airportCode = airportCode;
    } else if (cddHdd == CddHdd.hdd) {
      return HddSwap(
          buySell: buySell,
          term: term,
          quantity: quantity,
          strike: strike,
          maxPayoff: maxPayoff)
        ..airportCode = airportCode;
    } else {
      throw StateError('Unsupported index $cddHdd');
    }
  }
}
