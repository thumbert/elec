library risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/flat_report.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/monthly_position_report.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

part 'commodity_leg.dart';
part 'leaf.dart';

enum TimePeriod {month, day, hour}

class _BaseCfd {
  Date asOfDate;
  BuySell buySell;
  Term term;
  TimePeriod timePeriod;
}

class ElecCalculatorCfd extends _BaseCfd {
  String comments;
  List<CommodityLeg> legs;

  /// all the data from marks/curve_ids; the key is the curveId.
  static Map<String,Map<String,dynamic>> curveDetails;

  ElecCalculatorCfd();

  /// The recommended way to initialize.  See tests.
  ElecCalculatorCfd.fromJson(Map<String, dynamic> x) {
    if (x['term'] == null) {
      throw ArgumentError('Input needs to have key term');
    }
    term = Term.parse(x['term'], UTC);
    if (x['asOfDate'] == null) {
      throw ArgumentError('Input needs to have key asOfDate');
    }
    asOfDate = Date.parse(x['asOfDate'], location: UTC);
    if (x['buy/sell'] == null) {
      throw ArgumentError('Input needs to have key buy/sell');
    }
    buySell = BuySell.parse(x['buy/sell']);
    comments = x['comments'] ?? '';

    if (x['legs'] == null) {
      throw ArgumentError('Input needs to have key legs');
    }

    legs = <CommodityLeg>[];
    var _aux = x['legs'] as List;
    for (Map<String,dynamic> e in _aux) {
      // inject the tzLocation.
      e['tzLocation'] = curveDetails[e['curveId']]['tzLocation'] as String;
      var leg = CommodityLeg.fromJson(e)
        ..asOfDate = asOfDate
        ..buySell = buySell
        ..term = term;
      if (e.containsKey('floatingPrice')) {
        /// if you pass the floatingPrice to the commodity leg directly
        leg.floatingPrice = _parseSeries(e['floatingPrice'], leg.tzLocation);
        leg.makeLeaves();
      } /// else you have to give the calculator a [dataProvider]
      legs.add(leg);
    }
  }

  /// Return [true] if the calculator has custom quantities and prices, i.e.
  /// not the same value for all time intervals.
  bool hasCustom() {
    var res = false;
    for (var leg in legs) {
      if (leg.quantity.values.toSet().length != 1) return true;
      if (leg.fixPrice.values.toSet().length != 1) return true;
    }
    return res;
  }

  /// Get the total dollar value of this calculator.
  num dollarPrice() {
    var value = 0.0;
    for (var leg in legs) {
      for (var leaf in leg.leaves) {
        value += leaf.dollarPrice();
      }
    }
    return value;
  }

  Report flatReport() => FlatReportElecCfd(this);

  Report monthlyPositionReport() => MonthlyPositionReportElecCfd(this);

  /// Serialize it.  Don't serialize 'asOfDate' or 'floatingPrice' info.
  Map<String,dynamic> toJson() {
    return <String,dynamic>{
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [ for (var leg in legs) leg.toJson() ],
    };
  }

}



final DateFormat _isoFmt = DateFormat('yyyy-MM');

/// Input [xs] can be a hourly, daily, or monthly series.  Only ISO formats are
/// supported.
TimeSeries<num> _parseSeries(Iterable<Map<String,dynamic>> xs, Location location) {
  var ts = TimeSeries<num>();
  Interval Function(Map<String,dynamic>) parser;
  if (xs.first.keys.contains('month')) {
    parser = (e) => Month.parse(e['month'], location: location, fmt: _isoFmt);
  } else if (xs.first.keys.contains('date')) {
    parser = (e) => Date.parse(e['date'], location: location);
  } else if (xs.first.keys.contains('hourBeginning')) {
    parser = (e) => Hour.beginning(TZDateTime.parse(location, e['hourBeginning']));
  }
  for (var e in xs) {
    ts.add(IntervalTuple(parser(e), e['value'] as num));
  }
  return ts;
}

List<Map<String,dynamic>> _serializeSeries(TimeSeries<num> xs) {
  Map<String,dynamic> Function(IntervalTuple) fun;
  if (xs.first.interval is Month) {
    fun = (e) => {'month': (e.interval as Month).toIso8601String(), 'value': e.value};
  } else if (xs.first.interval is Date) {
    fun = (e) => {'date': (e.interval as Date).toString(), 'value': e.value};
  } else if (xs.first.interval is Hour) {
    fun = (e) => {'hourBeginning': (e.interval as Hour).start.toIso8601String(), 'value': e.value};
  }
  return [ for (var x in xs) fun(x) ];
}
