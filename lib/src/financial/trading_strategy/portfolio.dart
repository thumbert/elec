library financial.trading_strategy.portfolio.dart;

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/financial/black_scholes/black_scholes.dart';
import 'package:more/comparator.dart';

/// All dates are UTC
Map<(Date, String), num> marketPriceData = <(Date, String), num>{};
Map<(Date, String, num), num> marketVolData = <(Date, String, num), num>{};

sealed class Instrument {
  late String name;
  late Month contractMonth;
  num price(Date asOfDate);
  num delta(Date asOfDate);
}

class Futures extends Instrument {
  Futures({required String name, required Month contractMonth}) {
    this.name = name;
    this.contractMonth = contractMonth;
  }
  @override
  num price(Date asOfDate) {
    if (!marketPriceData.containsKey((asOfDate, name))) {
      throw StateError('No market data for $asOfDate $name');
    }
    return marketPriceData[(asOfDate, name)]!;
  }

  @override
  num delta(Date asOfDate) {
    return 1.0;
  }
}

class MonthlyGasOption extends Instrument {
  MonthlyGasOption({
    required String name,
    required Month contractMonth,
    required this.type,
    required this.strike,
    required this.underlyingName,
    required this.volatilityName,
  }) {
    this.name = name;
    this.contractMonth = contractMonth;
    expirationDate = contractMonth.startDate.subtract(2); // FIXME
  }

  final CallPut type;
  final num strike;
  final String underlyingName;
  final String volatilityName;

  late Date expirationDate;
  Date? _asOfDate;
  BlackScholes? _blackScholes;

  /// use the Black formula to calculate the option price
  @override
  num price(Date asOfDate) {
    var underlyingPrice = marketPriceData[(asOfDate, underlyingName)]!;
    var volatility = marketVolData[(asOfDate, volatilityName, strike)]!;
    if (asOfDate != _asOfDate) {
      _blackScholes = BlackScholes(
          type: type,
          strike: strike,
          expirationDate: expirationDate,
          asOfDate: asOfDate,
          underlyingPrice: underlyingPrice,
          volatility: volatility,
          riskFreeRate: 0);
      _asOfDate = asOfDate;
    }
    return _blackScholes!.value();
  }

  @override
  num delta(Date asOfDate) {
    var underlyingPrice = marketPriceData[(asOfDate, underlyingName)]!;
    var volatility = marketVolData[(asOfDate, volatilityName, strike)]!;
    if (asOfDate != _asOfDate) {
      _blackScholes = BlackScholes(
          type: type,
          strike: strike,
          expirationDate: expirationDate,
          asOfDate: asOfDate,
          underlyingPrice: underlyingPrice,
          volatility: volatility,
          riskFreeRate: 0);
      _asOfDate = asOfDate;
    }
    return _blackScholes!.delta();
  }
}

class TradeLeg {
  TradeLeg(
      {required this.instrument,
      required this.tradeDate,
      required this.buySell,
      required this.price,
      required this.quantity,
      required this.uom});
  final Instrument instrument;
  final Date tradeDate;
  final BuySell buySell;
  final num price;
  final num quantity;
  final Unit uom;

  num value(Date asOfDate) {
    if (asOfDate.isBefore(tradeDate)) {
      throw StateError(
          'Pricing date $asOfDate can\'t be before trade date $tradeDate');
    }
    late num res;
    switch (instrument) {
      case Futures():
        res = buySell.sign * quantity * (instrument.price(asOfDate) - price);
      case MonthlyGasOption():
        res = buySell.sign * quantity * (instrument.price(asOfDate) - price);
    }
    return res;
  }

  /// Calculate the deltas for this [instrument] and
  /// [contractMonth].  Can be several underliers.
  List<(String, Month, num)> delta(Date asOfDate) {
    switch (instrument) {
      case Futures():
        var res =
            buySell.sign * quantity * (instrument.price(asOfDate) - price);
        return [(instrument.name, instrument.contractMonth, res)];
      case MonthlyGasOption():
        var res =
            buySell.sign * quantity * (instrument.price(asOfDate) - price);
        return [(instrument.name, instrument.contractMonth, res)];
    }
  }
}

class Trade {
  /// A trade has multiple [TradeLeg]s.
  Trade({required this.legs});
  final List<TradeLeg> legs;

  num value(Date asOfDate) {
    num res = 0.0;
    for (var leg in legs) {
      res += leg.value(asOfDate);
    }
    return res;
  }

  /// Calculate the delta of this trade as of a given date.
  /// Can be multiple months, multiple instruments.
  List<(String, Month, num)> delta(Date asOfDate) {
    var out = legs.expand((leg) => leg.delta(asOfDate)).toList();
    var byInstument =
        naturalComparable<String>.onResultOf(((String, Month, num) e) => e.$1);
    var byMonth = naturalComparable<Interval>.onResultOf(
        ((String, Month, num) e) => e.$2);
    var ordering = byInstument.thenCompare(byMonth);
    ordering.sort(out);
    return out;
  }
}

class Portfolio {
  Portfolio({required this.trades});

  final List<Trade> trades;

  num value(Date asOfDate) {
    num res = 0.0;
    for (var trade in trades) {
      res += trade.value(asOfDate);
    }
    return res;
  }

  /// Calculate the delta of this portfolio
  List<(String, Month, num)> delta(Date asOfDate) {
    var aux = trades.expand((trade) => trade.delta(asOfDate)).toList();
    // Aggregate same instrument and month
    var groups = groupBy(aux, (e) => (e.$1, e.$2));
    var out = <(String, Month, num)>[];
    for (var group in groups.keys) {
      var value = groups[group]!.map((e) => e.$3).sum;
      out.add((group.$1, group.$2, value));
    }
    return out;
  }
}
