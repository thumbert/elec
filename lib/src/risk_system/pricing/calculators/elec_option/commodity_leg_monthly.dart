import 'package:dama/dama.dart' as dama;
import 'package:date/date.dart';
import 'package:elec/calculators/elec_daily_option.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/commodity_leg.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/leaf.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/time_period.dart';

/// TODO:  this commodity leg monthly shouldn't have LeafElecOption as a type!
/// but LeafElecMonthly.

class CommodityLegMonthly extends CommodityLegBase<LeafElecOption> {
  /// A commodity leg with monthly granularity.
  CommodityLegMonthly({
    this.curveId,
    Bucket/*!*/ bucket,
    this.quantity,
    this.fixPrice,
    this.tzLocation,
  }) {
    this.bucket = bucket;
  }

  String/*!*/ curveId;
  String cashOrPhys;
  Location/*!*/ tzLocation;

  TimeSeries<num/*!*/>/*!*/ quantity;
  TimeSeries<num/*!*/>/*!*/ fixPrice;
  TimeSeries<num> underlyingPrice;

  /// A commodity leg with monthly granularity.
  CommodityLegMonthly.fromJson(Map<String, dynamic> x) {
    // time zone of the curve, may be different than the calc
    if (x['tzLocation'] == null) {
      throw ArgumentError('Json input is missing the key tzLocation');
    }
    tzLocation = getLocation(x['tzLocation']);

    // these 3 must come from the calculator
    if (x['asOfDate'] == null) {
      throw ArgumentError('Json input is missing the key asOfDate');
    }
    asOfDate = Date.parse(x['asOfDate']);
    if (x['term'] == null) {
      throw ArgumentError('Json input is missing the key term');
    }
    term = Term.parse(x['term'], tzLocation);
    if (x['buy/sell'] == null) {
      throw ArgumentError('Json input is missing the key buy/sell');
    }
    buySell = BuySell.parse(x['buy/sell']);

    // below is leg info only
    if (x['curveId'] == null) {
      throw ArgumentError('Json input is missing the key curveId');
    }
    curveId = (x['curveId'] as String).toLowerCase();
    x.putIfAbsent('cash/physical', () => 'cash');
    cashOrPhys = (x['cash/physical'] as String).toLowerCase();
    if (x['bucket'] == null) {
      throw ArgumentError('Json input is missing the key bucket');
    }
    bucket = Bucket.parse(x['bucket']);

    /// set the quantity schedule and determine the timePeriod
    var qValue = x['quantity']['value'];
    if (qValue == null) {
      throw ArgumentError('Json input is missing the quantity/value key');
    }
    if (qValue is num) {
      var months = term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
      quantity = TimeSeries.fill(months, qValue);
    } else if (qValue is List) {
      quantity = parseSeries(qValue.cast<Map<String, dynamic>>(), tzLocation);
    }

    /// get the fixPrice
    var months = term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
    if (x.containsKey('fixPrice')) {
      var pValue = x['fixPrice']['value'];
      if (pValue is num) {
        fixPrice = TimeSeries.fill(months, pValue);
      } else if (pValue is List) {
        fixPrice = parseSeries(pValue.cast<Map<String, dynamic>>(), tzLocation);
      }
    } else {
      // if fixPrice is not specified
      fixPrice = TimeSeries.fill(months, 0.0);
    }
  }

  /// Fair value for this commodity leg.
  /// Needs [leaves] to be populated.
  @override
  num price() => 0;

  /// Return [true] if the calculator has custom quantity, i.e.
  /// not the same value for all time intervals.
  bool get hasCustomQuantity {
    if (quantity.values.toSet().length == 1) {
      return false;
    }
    return true;
  }

  /// Return [true] if the calculator has custom prices,
  bool get hasCustomFixPrice {
    if (fixPrice.values.toSet().length == 1) {
      return false;
    }
    return true;
  }

  /// Make the leaves for this leg.  One leaf per month.
  void makeLeaves() {}

  /// Serialize it
  @override
  Map<String, dynamic> toJson() {
    var q, fp;

    if (!hasCustomQuantity) {
      q = {'value': quantity.first.value};
    } else {
      q = {'value': serializeSeries(quantity)};
    }

    if (!hasCustomFixPrice) {
      fp = {'value': fixPrice.first.value};
    } else {
      fp = {'value': serializeSeries(fixPrice)};
    }

    return <String, dynamic>{
      'curveId': curveId,
      'tzLocation': tzLocation.name,
      'cash/physical': cashOrPhys,
      'bucket': bucket.toString(),
      'quantity': q,
      'fixPrice': fp,
    };
  }

  /// if custom fixPrice, what to show on the screen in the UI
  num showFixPrice() {
    var months = term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
    var hours = months.map((month) => bucket.countHours(month));
    return dama.weightedMean(fixPrice.values, hours);
  }

  /// if custom quantities, what to show on the screen in the UI
  num showQuantity() {
    var months = term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
    var hours = months.map((month) => bucket.countHours(month));
    return dama.weightedMean(quantity.values, hours);
  }

  /// what to show on the screen in the UI for the underlying price
  num showUnderlyingPrice() {
    var months = term.interval.splitLeft((dt) => Month.fromTZDateTime(dt));
    var hours = months.map((month) => bucket.countHours(month));
    return dama.weightedMean(underlyingPrice.values, hours);
  }

  /// Make a copy
  // CommodityLegMonthly copyWith({
  //   String curveId,
  //   Bucket bucket,
  //   TimePeriod timePeriod,
  //   TimeSeries<num> quantity,
  //   TimeSeries<num> fixPrice,
  //   Location tzLocation,
  //   Date asOfDate,
  //   Term term,
  //   BuySell buySell,
  // }) =>
  //     CommodityLegMonthly(
  //         curveId: curveId ?? this.curveId,
  //         bucket: bucket ?? this.bucket,
  //         quantity: quantity ?? this.quantity,
  //         fixPrice: fixPrice ?? this.fixPrice,
  //         tzLocation: tzLocation ?? this.tzLocation)
  //       ..asOfDate = asOfDate ?? this.asOfDate
  //       ..term = term ?? this.term
  //       ..buySell = buySell ?? this.buySell;

  /// Input [xs] is a monthly series.
  /// Each element is one of the following formats
  /// ```
  ///   {'month': '2020-03', 'value': 50.1}
  /// ```
  static TimeSeries<num> parseSeries(
      Iterable<Map<String, dynamic>> xs, Location location) {
    var ts = TimeSeries<num>();
    Interval Function(Map<String, dynamic>) parser;
    if (xs.first.keys.contains('month')) {
      parser = (e) => Month.parse(e['month'], location: location);
    } else {
      throw ArgumentError('Only months are allowed, got ${xs.first}');
    }
    for (var e in xs) {
      ts.add(IntervalTuple(parser(e), e['value'] as num/*!*/));
    }
    return ts;
  }

  /// The opposite of _parseSeries
  static List<Map<String, dynamic>> serializeSeries(TimeSeries<num> xs) {
    Map<String, dynamic> Function(IntervalTuple) fun;
    if (xs.first.interval is Month) {
      fun = (e) =>
          {'month': (e.interval as Month).toIso8601String(), 'value': e.value};
    }
    return [for (var x in xs) fun(x)];
  }
}
