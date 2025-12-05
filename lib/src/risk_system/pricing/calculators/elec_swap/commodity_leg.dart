
import 'package:dama/stat/descriptive/summary.dart';
import 'package:elec/calculators.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/commodity_leg.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/leaf.dart';
import 'package:elec/time.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';


class CommodityLeg extends CommodityLegBase<LeafElecSwap> {
  CommodityLeg({
    required this.curveId,
    required this.bucket,
    required this.timePeriod,
    required this.quantitySchedule,
    this.fixPriceSchedule,
    required this.tzLocation,
  }) {
    fixPriceSchedule ??= HourlySchedule.filled(0);
  }


  late String curveId;
  String? cashOrPhys;
  @override
  late Bucket bucket;
  late Location tzLocation;

  /// The time period of the leg which applies to all the leaves.  It is set at
  /// the lower time period of quantity and fixPrice.  For example, if quantity
  /// is [TimePeriod.month] and fixPrice is [TimePeriod.hour], the timePeriod
  /// for the leg is set to [TimePeriod.hour].
  ///
  late TimePeriod timePeriod;

  /// An hourly time series.
  late TimeSeries<num> hourlyFloatingPrice;

  /// If you have a custom quantity, only intervals included in the
  /// [term] are valid.
  late HourlySchedule quantitySchedule;
  late HourlySchedule? fixPriceSchedule;


  /// Support hourly, daily and monthly quantities/fixPrices.
  /// Method is async because it uses [curveIdCache] and [forwardMarksCache].
  CommodityLeg.fromJson(Map<String, dynamic> x) {
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
      timePeriod = TimePeriod.month;
      quantitySchedule = HourlySchedule.filled(qValue);
    } else if (qValue is List) {
      var aux =
          _parseSeries(qValue.cast<Map<String, dynamic>>(), tzLocation, bucket);
      quantitySchedule =
          HourlySchedule.fromForwardCurve(PriceCurve.fromIterable(aux));
      timePeriod = getTimePeriod(aux.first.interval);
    }

    /// set the fixPrice schedule and lower the timePeriod
    if (x.containsKey('fixPrice')) {
      var pValue = x['fixPrice']['value'];
      if (pValue is num) {
        fixPriceSchedule = HourlySchedule.filled(pValue);
      } else if (pValue is List) {
        var aux = _parseSeries(
            pValue.cast<Map<String, dynamic>>(), tzLocation, bucket);
        fixPriceSchedule =
            HourlySchedule.fromForwardCurve(PriceCurve.fromIterable(aux));

        /// lower the timePeriod if needed
        if (aux.first.interval is Date && timePeriod != TimePeriod.hour) {
          timePeriod = TimePeriod.day;
        } else if (aux.first.interval is Hour) {
          timePeriod = TimePeriod.hour;
        }
      }
    } else {
      fixPriceSchedule = HourlySchedule.filled(0.0);
    }
  }

  /// What to do with the quantitySchedule and the fixPriceSchedule when
  /// you change the term on a calculator.  How to do you extend them?
  /// Ignore this for now.
  // @override
  // set term(Term term) {
  //   // What to do with the quantitySchedule and the fixPriceSchedule when
  //   // you change the term on a calculator.  How to do you extend them?
  // }

  /// Fair value for this commodity leg.
  /// Get the quantity weighted floating price for this leg.
  /// Needs [leaves] to be populated.
  @override
  num price() {
    num hpq = 0; // hours * quantity * floatingPrice
    num hq = 0; // hours * quantity
    for (var leaf in leaves) {
      hpq += leaf.hours * leaf.quantity * leaf.floatingPrice;
      hq += leaf.hours * leaf.quantity;
    }
    return hpq / hq;
  }

  /// Get the [floatingPrice] at the period of the leg (monthly, daily, hourly.)
  TimeSeries<num> floatingPrice() {
    if (timePeriod == TimePeriod.month) {
      return toMonthly(hourlyFloatingPrice, mean);
    } else {
      throw UnimplementedError('Not implemented $timePeriod');
    }
  }

  /// Get the leg quantity as a timeseries at the period of the leg (monthly,
  /// daily, hourly.)
  TimeSeries<num> quantity() {
    var termL = term.interval.withTimeZone(tzLocation);
    if (timePeriod == TimePeriod.month) {
      var aux = quantitySchedule.toHourly(termL);
      return toMonthly(aux, mean);
    } else {
      throw UnimplementedError('Not implemented $timePeriod');
    }
  }

  /// Get the leg quantity as an hourly timeseries.
  TimeSeries<num?> hourlyQuantity() {
    var termL = term.interval.withTimeZone(tzLocation);
    return quantitySchedule.toHourly(termL);
  }

  /// Get the leg fixPrice as a timeseries
  TimeSeries<num> fixPrice() {
    var termL = term.interval.withTimeZone(tzLocation);
    if (timePeriod == TimePeriod.month) {
      var aux = fixPriceSchedule!.toHourly(termL);
      return toMonthly(aux, mean);
    } else {
      throw UnimplementedError('Not implemented $timePeriod');
    }
  }

  /// Get the leg fixPrice as an hourly timeseries.
  TimeSeries<num?> hourlyFixPrice() {
    var term0 = term.interval.withTimeZone(tzLocation);
    return fixPriceSchedule!.toHourly(term0);
  }

  /// Return [true] if the calculator has custom quantity, i.e.
  /// not the same value for all time intervals.
  bool get hasCustomQuantity {
    if (quantitySchedule is HourlyScheduleFilled) {
      return false;
    }
    return true;
  }

  /// Return [true] if the calculator has custom prices,
  bool get hasCustomFixPrice {
    if (fixPriceSchedule is HourlyScheduleFilled) {
      return false;
    }
    return true;
  }

  /// Make the leaves for this leg.  One leaf per period.
  void makeLeaves() {
    leaves = <LeafElecSwap>[];
    if (timePeriod == TimePeriod.month) {
      var months = term.interval
          .withTimeZone(tzLocation)
          .splitLeft((dt) => Month.containing(dt));
      var quantityM = toMonthly(hourlyQuantity() as TimeSeries<num>, mean);
      var fixPriceM = toMonthly(hourlyFixPrice() as TimeSeries<num>, mean);
      var floatingPriceM = toMonthly(hourlyFloatingPrice, mean);
      for (var month in months) {
        var quantity = quantityM.observationAt(month).value;
        var fixPrice = fixPriceM.observationAt(month).value;
        var floatPrice = floatingPriceM.observationAt(month).value;
        var hours = bucket.countHours(month);
        leaves.add(LeafElecSwap(
            buySell, month, quantity, fixPrice, floatPrice, hours));
      }
    } else {
      throw UnimplementedError('Not implemented $timePeriod');
    }
  }

  /// Serialize it
  @override
  Map<String, dynamic> toJson() {
    late Map<String, dynamic> q, fp;

    if (!hasCustomQuantity) {
      q = {'value': (quantitySchedule as HourlyScheduleFilled).value};
    } else {
      q = {'value': _serializeSeries(quantity())};
    }

    if (!hasCustomFixPrice) {
      fp = {'value': (fixPriceSchedule as HourlyScheduleFilled).value};
    } else {
      fp = {'value': _serializeSeries(fixPrice())};
    }

    return <String, dynamic>{
      'curveId': curveId,
      'tzLocation': tzLocation.name,
      'cash/physical': cashOrPhys ?? 'cash',
      'bucket': bucket.toString(),
      'quantity': q,
      'fixPrice': fp,
    };
  }

  /// What quantities to show on the screen in the UI.
  num showQuantity() {
    if (quantitySchedule is HourlyScheduleFilled) {
      return (quantitySchedule as HourlyScheduleFilled).value;
    }
    return 1.0;
  }

  /// if custom fixPrice, what to show on the screen in the UI
  num showFixPrice() {
    if (!hasCustomFixPrice) {
      return (fixPriceSchedule as HourlyScheduleFilled).value;
    }
    return 1.0;
  }

  /// Make a copy
  CommodityLeg copyWith({
    String? curveId,
    Bucket? bucket,
    TimePeriod? timePeriod,
    HourlySchedule? quantitySchedule,
    HourlySchedule? fixPriceSchedule,
    Location? tzLocation,
    Date? asOfDate,
    Term? term,
    BuySell? buySell,
  }) =>
      CommodityLeg(
          curveId: curveId ?? this.curveId,
          bucket: bucket ?? this.bucket,
          timePeriod: timePeriod ?? this.timePeriod,
          quantitySchedule: quantitySchedule ?? this.quantitySchedule,
          fixPriceSchedule: fixPriceSchedule ?? this.fixPriceSchedule,
          tzLocation: tzLocation ?? this.tzLocation)
        ..asOfDate = asOfDate ?? this.asOfDate
        ..term = term ?? this.term
        ..buySell = buySell ?? this.buySell;
}

/// Input [xs] can be a hourly, daily, or monthly series.  Only ISO formats are
/// supported.  Each element is one of the following formats
/// ```
///   {'month': '2020-03', 'value': 50.1}
///   {'date': '2020-03-05', 'value': 50.1}
///   {'hourBeginning': '2002-02-27T14:00:00-0500', 'value': 50.1}
/// ```
TimeSeries<Map<Bucket, num>> _parseSeries(
    Iterable<Map<String, dynamic>> xs, Location location, Bucket bucket) {
  var ts = TimeSeries<Map<Bucket, num>>();
  late Interval Function(Map<String, dynamic>) parser;
  if (xs.first.keys.contains('month')) {
    parser = (e) => Month.parse(e['month'], location: location);
  } else if (xs.first.keys.contains('date')) {
    parser = (e) => Date.parse(e['date'], location: location);
  } else if (xs.first.keys.contains('hourBeginning')) {
    parser =
        (e) => Hour.beginning(TZDateTime.parse(location, e['hourBeginning']));
  }
  for (var e in xs) {
    ts.add(IntervalTuple(parser(e), {bucket: e['value'] as num}));
  }
  return ts;
}

///
List<Map<String, dynamic>> _serializeSeries(TimeSeries<num> xs) {
  late Map<String, dynamic> Function(IntervalTuple) fun;
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
