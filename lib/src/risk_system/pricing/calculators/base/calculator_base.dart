library elec.risk_system.pricing.calculators.base.calculator_base;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'cache_provider.dart';
import 'commodity_leg.dart';

class CalculatorBase {
  CalculatorBase();

  // factory CalculatorBase.fromJson(Map<String, dynamic> x) {
  //   if (x['calculatorType'] == 'elec_swap') {
  //     return ElecSwapCalculator.fromJson(x);
  //   } else {
  //     throw ArgumentError('Unsupported calculator type ${x['calculatorType']}');
  //   }
  // }

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

  List<CommodityLeg> _legs;
  List<CommodityLeg> get legs => _legs ?? <CommodityLeg>[];
  set legs(List<CommodityLeg> xs) {
    _legs = <CommodityLeg>[];
    for (var x in xs) {
      x.term = term;
      x.asOfDate = asOfDate;
      x.buySell = buySell;
      _legs.add(x);
    }
  }

  /// Communicate an error with the UI.
  String error = '';

  /// Calculator comments.  Useful for UI.
  String comments = '';

  /// What to show in the UI for details.  Each calculator implements it.
  String showDetails() => '';
}
