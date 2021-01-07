library risk_system.pricing.calculators.elec_daily_option;

import 'package:date/date.dart';
import 'package:elec/calculators.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/calculator_base.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/commodity_leg_monthly.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/cache_provider.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

class CommodityLegDailyOption extends CommodityLegMonthly {
  CommodityLegDailyOption(
      {String curveId,
      Bucket bucket,
      TimeSeries<num> quantity,
      TimeSeries<num> fixPrice,
      Location tzLocation,
      this.callPut,
      this.strike,
      this.priceAdjustment,
      this.volatilityAdjustment}) {
    this.curveId = curveId;
    this.bucket = bucket;
    this.tzLocation = tzLocation;
    this.quantity = quantity;
    this.fixPrice = fixPrice;
    this.fixPrice ??= TimeSeries.fill(quantity.intervals, 0);
  }

  CallPut callPut;
  TimeSeries<num> strike;

  /// The [asOfDate] value of the underlying as a monthly timeseries.
  TimeSeries<num> underlyingPrice;
  TimeSeries<num> priceAdjustment;

  /// For clarification, values are as treated as numbers, e.g. a 5% adjustment
  /// is entered as 0.05.
  TimeSeries<num> volatilityAdjustment;

  /// Initialize from a Map.
  ///```
  ///         {
  ///           'curveId': 'isone_energy_4000_da_lmp',
  ///           'tzLocation': 'America/New_York',
  ///           'bucket': '5x16',
  ///           'quantity': {
  ///             'value': [
  ///               {'month': '2021-01', 'value': 50.0},
  ///               {'month': '2021-02', 'value': 50.0},
  ///             ]
  ///           },
  ///           'call/put': 'call',
  ///           'strike': {'value': 100.0},
  ///           'priceAdjustment': {'value': 0},
  ///           'volatilityAdjustment': {'value': 0},
  ///           'fixPrice': {
  ///             'value': [
  ///               {'month': '2021-01', 'value': 3.10},
  ///               {'month': '2021-02', 'value': 3.10},
  ///             ]
  ///           },
  ///         }
  ///```
  CommodityLegDailyOption.fromJson(Map<String, dynamic> x) : super.fromJson(x) {
    if (!x.containsKey('call/put')) {
      throw ArgumentError('Input needs to have \'call/put\' key.');
    }
    callPut = CallPut.parse(x['call/put']);

    var months = term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));

    // read the strike info
    var vStrike = x['strike']['value'];
    if (vStrike == null) {
      throw ArgumentError('Json input is missing the strike/value key');
    }
    if (vStrike is num) {
      strike = TimeSeries.fill(months, vStrike);
    } else if (vStrike is List) {
      strike = CommodityLegMonthly.parseSeries(
          vStrike.cast<Map<String, dynamic>>(), tzLocation);
    }

    // read the price adjustment
    if (!x.containsKey('priceAdjustment')) {
      priceAdjustment = TimeSeries.fill(months, 0);
    } else {
      var pAdj = x['priceAdjustment']['value'];
      if (pAdj is num) {
        priceAdjustment = TimeSeries.fill(months, pAdj);
      } else if (pAdj is List) {
        priceAdjustment = CommodityLegMonthly.parseSeries(
            pAdj.cast<Map<String, dynamic>>(), tzLocation);
      }
    }

    // read the vol adjustment
    if (!x.containsKey('volatilityAdjustment')) {
      volatilityAdjustment = TimeSeries.fill(months, 0);
    } else {
      var vAdj = x['volatilityAdjustment']['value'];
      if (vAdj is num) {
        volatilityAdjustment = TimeSeries.fill(months, vAdj);
      } else if (vAdj is List) {
        volatilityAdjustment = CommodityLegMonthly.parseSeries(
            vAdj.cast<Map<String, dynamic>>(), tzLocation);
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var out = super.toJson();
    out['call/put'] = callPut.toString();

    if (strike.values.toSet().length == 1) {
      out['strike'] = {'value': strike.values.first};
    } else {
      out['strike'] = {'value': CommodityLegMonthly.serializeSeries(strike)};
    }

    if (priceAdjustment.values.toSet().length == 1) {
      var pAdj = priceAdjustment.values.first;
      if (pAdj != 0) {
        out['priceAdjustment'] = {'value': pAdj};
      }
    } else {
      // only serialize if there is a non zero adjustment
      out['priceAdjustment'] = {
        'value': CommodityLegMonthly.serializeSeries(priceAdjustment)
      };
    }

    if (volatilityAdjustment.values.toSet().length == 1) {
      var vAdj = volatilityAdjustment.values.first;
      if (vAdj != 0) {
        out['volatilityAdjustment'] = {'value': vAdj};
      }
    } else {
      // only serialize if there is a non zero adjustment
      out['volatilityAdjustment'] = {
        'value': CommodityLegMonthly.serializeSeries(priceAdjustment)
      };
    }

    return out;
  }
}
