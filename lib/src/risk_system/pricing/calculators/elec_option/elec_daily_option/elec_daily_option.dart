library risk_system.pricing.calculators.elec_daily_option;

import 'package:date/date.dart';
import 'package:elec/calculators.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/calculator_base.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/cache_provider.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/commodity_leg_monthly.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/elec_daily_option/commodity_leg_daily_option.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/cache_provider.dart';
import 'package:timezone/timezone.dart';

class ElecDailyOption
    extends CalculatorBase<CommodityLegDailyOption, CacheProviderElecOption> {
  ElecDailyOption(
      {Date asOfDate,
      Term term,
      BuySell buySell,
      List<CommodityLegDailyOption> legs,
      CacheProviderElecOption cacheProvider}) {
    this.asOfDate = asOfDate;
    this.term = term;
    this.buySell = buySell;
    this.legs = legs ?? super.legs;
    // these 3 properties are needed for the legs
    for (var leg in this.legs) {
      leg.asOfDate = asOfDate;
      leg.term = term;
      leg.buySell = buySell;
    }
    this.cacheProvider = cacheProvider;
  }

  /// The recommended way to initialize from a template.  See tests.
  /// Still needs [cacheProvider] to be set.
  ElecDailyOption.fromJson(Map<String, dynamic> x) {
    if (x['calculatorType'] != 'elec_daily_option') {
      throw ArgumentError(
          'Json input needs a key calculatorType = elec_daily_option');
    }
    if (x['term'] == null) {
      throw ArgumentError('Json input is missing the key term');
    }
    term = Term.parse(x['term'], UTC);
    if (x['asOfDate'] == null) {
      // if asOfDate is not specified, it means today
      x['asOfDate'] = Date.today().toString();
    }
    asOfDate = Date.parse(x['asOfDate'], location: UTC);
    if (x['buy/sell'] == null) {
      throw ArgumentError('Json input is missing the key buy/sell');
    }
    buySell = BuySell.parse(x['buy/sell']);
    comments = x['comments'] ?? '';

    if (x['legs'] == null) {
      throw ArgumentError('Json input is missing the key: legs');
    }

    legs = <CommodityLegDailyOption>[];
    var _aux = x['legs'] as List;
    for (Map<String, dynamic> e in _aux) {
      e['asOfDate'] = x['asOfDate'];
      e['term'] = x['term'];
      e['buy/sell'] = x['buy/sell'];
      var leg = CommodityLegDailyOption.fromJson(e);
      legs.add(leg);
    }
  }

  @override
  Future<void> build() async {
    for (var leg in legs) {
      var curveDetails = await cacheProvider.curveDetailsCache.get(leg.curveId);
      leg.tzLocation = getLocation(curveDetails['tzLocation']);
      // leg.hourlyFloatingPrice = await getFloatingPrice(leg.bucket, leg.curveId);
      leg.makeLeaves();
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'calculatorType': 'elec_daily_option',
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [for (var leg in legs) leg.toJson()],
    };
  }
}
