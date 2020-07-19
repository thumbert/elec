library risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

import 'package:dama/dama.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/flat_report.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/monthly_position_report.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:elec/src/time/hourly_schedule.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:elec_server/client/marks/forward_marks.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import 'package:more/cache.dart';

part 'cfd_base.dart';
part 'commodity_leg.dart';
part 'leaf.dart';

enum TimePeriod { month, day, hour }

class ElecCalculatorCfd extends _BaseCfd {
  String comments;

  /// all the data from marks/curve_ids; the key is the curveId.
//  Map<String, Map<String, dynamic>> curveDetails;

  ElecCalculatorCfd(
      {CurveIdClient curveIdClient, ForwardMarks forwardMarksClient}) {
    this.curveIdClient = curveIdClient;
    this.forwardMarksClient = forwardMarksClient;
    curveIdCache =
        Cache<String, Map<String, dynamic>>.lru(loader: _curveIdLoader);
    forwardMarksCache =
        Cache<Tuple2<Date, String>, TimeSeries<Map<Bucket, num>>>.lru(
            loader: _fwdMarksLoader);
    hourlyShapeCache = Cache<Tuple2<Date, String>, HourlySchedule>.lru(
        loader: _hourlyShapeLoader);

  }

  /// The recommended way to initialize from a template.  See tests.
  /// Method is async because it uses [curveIdCache] and [forwardMarksCache].
  void fromJson(Map<String, dynamic> x) async {
    if (x['term'] == null) {
      throw ArgumentError('Json input is missing the key term');
    }
    term = Term.parse(x['term'], UTC);
    if (x['asOfDate'] == null) {
      throw ArgumentError('Json input is missing the key asOfDate');
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

    legs = <CommodityLeg>[];
    var _aux = x['legs'] as List;
    for (Map<String, dynamic> e in _aux) {
      var leg = CommodityLeg(this);
      await leg.fromJson(e);
      leg.makeLeaves();
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

  /// After you make a change to the calculator that affects the floating price,
  /// you need to rebuild it before repricing it.
  /// TODO: Can I call it updateFloatingPrice?
  ///
  /// If you change the term, the pricing date, any of the leg buckets, etc.
  /// It is a brittle design, because people may forget to call it.
  void build() async {
    for (var leg in legs) {
      leg.floatingPrice =
          await getFloatingPrice(leg.bucket, leg.curveId, leg.timePeriod);
      leg.makeLeaves();
    }
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
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [for (var leg in legs) leg.toJson()],
    };
  }
}

final DateFormat _isoFmt = DateFormat('yyyy-MM');

/// Input [xs] can be a hourly, daily, or monthly series.  Only ISO formats are
/// supported.
TimeSeries<num> _parseSeries(
    Iterable<Map<String, dynamic>> xs, Location location) {
  var ts = TimeSeries<num>();
  Interval Function(Map<String, dynamic>) parser;
  if (xs.first.keys.contains('month')) {
    parser = (e) => Month.parse(e['month'], location: location, fmt: _isoFmt);
  } else if (xs.first.keys.contains('date')) {
    parser = (e) => Date.parse(e['date'], location: location);
  } else if (xs.first.keys.contains('hourBeginning')) {
    parser =
        (e) => Hour.beginning(TZDateTime.parse(location, e['hourBeginning']));
  }
  for (var e in xs) {
    ts.add(IntervalTuple(parser(e), e['value'] as num));
  }
  return ts;
}

List<Map<String, dynamic>> _serializeSeries(TimeSeries<num> xs) {
  Map<String, dynamic> Function(IntervalTuple) fun;
  if (xs.first.interval is Month) {
    fun = (e) =>
        {'month': (e.interval as Month).toIso8601String(), 'value': e.value};
  } else if (xs.first.interval is Date) {
    fun = (e) => {'date': (e.interval as Date).toString(), 'value': e.value};
  } else if (xs.first.interval is Hour) {
    fun = (e) => {
          'hourBeginning': (e.interval as Hour).start.toIso8601String(),
          'value': e.value
        };
  }
  return [for (var x in xs) fun(x)];
}
