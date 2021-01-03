library elec.risk_system.pricing.calculators.base.calculator_base;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'cache_provider.dart';
import 'commodity_leg.dart';

abstract class CalculatorBase<Leg extends CommodityLegBase> {
  /// A collection of caches for different market and curve data.
  CacheProvider cacheProvider;

  Date _asOfDate;

  /// The pricing date.  It does not need a timezone.  UTC timezone is fine.
  Date get asOfDate => _asOfDate;
  set asOfDate(Date date) {
    _asOfDate = date;
    // push it into the legs
    for (var leg in legs) {
      leg.asOfDate = asOfDate;
    }
  }

  BuySell _buySell;
  BuySell get buySell => _buySell;
  set buySell(BuySell buySell) {
    _buySell = buySell;
    // push it into the legs
    for (var leg in legs) {
      leg.buySell = buySell;
    }
  }

  Term _term;
  Term get term => _term;
  set term(Term term) {
    _term = term;
    // push it into the legs
    for (var leg in legs) {
      leg.term = term;
    }
  }

  List<Leg> _legs;
  List<Leg> get legs => _legs ?? <Leg>[];
  set legs(List<Leg> xs) {
    _legs = <Leg>[];
    for (var x in xs) {
      x.term = term;
      x.asOfDate = asOfDate;
      x.buySell = buySell;
      _legs.add(x);
    }
  }

  /// Get the market data and make the leaves
  Future<void> build();

  /// Calculate the value of this calculator
  num dollarPrice() {
    var value = 0.0;
    for (var leg in legs) {
      for (var leaf in leg.leaves) {
        value += leaf.dollarPrice();
      }
    }
    return value;
  }

  /// Communicate an error with the UI.
  String error = '';

  /// Calculator comments.  Useful for UI.
  String comments = '';

  /// What to show in the UI for details.  Each calculator implements it.
  String showDetails() => '';

  /// What to serialize to Mongo.
  Map<String, dynamic> toJson();
}
