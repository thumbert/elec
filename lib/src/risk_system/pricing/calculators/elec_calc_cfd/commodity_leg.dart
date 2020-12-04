part of elec.calculators;

// import 'package:date/date.dart';
// import 'package:elec/elec.dart';
// import 'package:elec/risk_system.dart';
// import 'package:timezone/timezone.dart';
// import 'cfd_base.dart';

class CommodityLeg extends _BaseCfd {
  String curveId;
  String cashOrPhys;
  Bucket bucket;
  Location tzLocation;

  /// The time period of the leg which applies to all the leaves.  It is set at
  /// the lower time period of quantity and fixPrice.  For example, if quantity
  /// is [TimePeriod.month] and fixPrice is [TimePeriod.hour], the timePeriod
  /// for the leg is set to [TimePeriod.hour].
  ///
  TimePeriod timePeriod;

  /// An hourly time series.
  TimeSeries<num> hourlyFloatingPrice;

  /// If you have a custom quantity, only intervals included in the
  /// [term] are valid.
  HourlySchedule quantitySchedule;
  HourlySchedule fixPriceSchedule;

  CommodityLeg({
    this.curveId,
    this.bucket,
    this.timePeriod,
    this.quantitySchedule,
    this.fixPriceSchedule,
    this.tzLocation,
  }) {
    fixPriceSchedule ??= HourlySchedule.filled(0);
  }

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
    _asOfDate = Date.parse(x['asOfDate']);
    if (x['term'] == null) {
      throw ArgumentError('Json input is missing the key term');
    }
    _term = Term.parse(x['term'], tzLocation);
    if (x['buy/sell'] == null) {
      throw ArgumentError('Json input is missing the key buy/sell');
    }
    _buySell = BuySell.parse(x['buy/sell']);

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
      quantitySchedule = HourlySchedule.fromTimeSeriesWithBucket(aux);
      // quantitySchedule = ForwardCurve.fromIterable(aux).toHourly();
      if (aux.first.interval is Month) {
        timePeriod = TimePeriod.month;
      } else if (aux.first.interval is Date) {
        timePeriod = TimePeriod.day;
      } else if (aux.first.interval is Hour) {
        timePeriod = TimePeriod.hour;
      }
    }

    /// set the fixPrice schedule and lower the timePeriod if needed
    if (x.containsKey('fixPrice')) {
      var pValue = x['fixPrice']['value'];
      if (pValue is num) {
        fixPriceSchedule = HourlySchedule.filled(pValue);
      } else if (pValue is List) {
        var aux = _parseSeries(
            qValue.cast<Map<String, dynamic>>(), tzLocation, bucket);
        fixPriceSchedule = HourlySchedule.fromTimeSeriesWithBucket(aux);
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

  /// Leg leaves
  List<Leaf> leaves;

  /// Fair value for this commodity leg.
  /// Get the quantity weighted floating price for this leg.
  /// Needs [leaves] to be populated.
  num price() {
    num hpq = 0; // hours * quantity * floatingPrice
    num hq = 0; // hours * quantity
    for (var leaf in leaves) {
      hpq += leaf.hours * leaf.quantity * leaf.floatingPrice;
      hq += leaf.hours * leaf.quantity;
    }
    return hpq / hq;
  }

  /// Get the [floatingPrice] at the period of the leg.
  TimeSeries<num> get floatingPrice {
    if (timePeriod == TimePeriod.month) {
      return toMonthly(hourlyFloatingPrice, mean);
    } else {
      throw UnimplementedError('Not implemented ${timePeriod}');
    }
  }

  /// Get the leg quantity as a timeseries
  TimeSeries<num> get quantity {
    var _term = term.interval.withTimeZone(tzLocation);
    if (timePeriod == TimePeriod.month) {
      return quantitySchedule.toMonthly(_term, mean);
    } else {
      throw UnimplementedError('Not implemented ${timePeriod}');
    }
  }

  /// Get the leg quantity as an hourly timeseries.
  TimeSeries<num> get hourlyQuantity {
    var _term = term.interval.withTimeZone(tzLocation);
    return quantitySchedule.toHourly(_term);
  }

  /// Get the leg quantity as a timeseries
  TimeSeries<num> get fixPrice {
    var _term = term.interval.withTimeZone(tzLocation);
    if (timePeriod == TimePeriod.month) {
      return fixPriceSchedule.toMonthly(_term, mean);
    } else {
      throw UnimplementedError('Not implemented ${timePeriod}');
    }
  }

  /// Get the leg fixPrice as an hourly timeseries.
  TimeSeries<num> get hourlyFixPrice {
    var _term = term.interval.withTimeZone(tzLocation);
    return fixPriceSchedule.toHourly(_term);
  }

  /// Make the leaves for this leg.  One leaf per period.
  void makeLeaves() {
    leaves = <Leaf>[];
    if (timePeriod == TimePeriod.month) {
      var months = term.interval
          .withTimeZone(tzLocation)
          .splitLeft((dt) => Month.fromTZDateTime(dt));
      var _quantityM = toMonthly(hourlyQuantity, mean);
      var _fixPriceM = toMonthly(hourlyFixPrice, mean);
      var _floatingPriceM = toMonthly(hourlyFloatingPrice, mean);
      for (var month in months) {
        var _quantity = _quantityM.observationAt(month).value;
        var _fixPrice = _fixPriceM.observationAt(month).value;
        var _floatPrice = _floatingPriceM.observationAt(month).value;
        var hours = bucket.countHours(month);
        leaves.add(
            Leaf(buySell, month, _quantity, _fixPrice, _floatPrice, hours));
      }
    } else {
      /// TODO: continue me
      throw UnimplementedError('Not implemented ${timePeriod}');
    }
  }

  /// serialize it
  Map<String, dynamic> toJson() {
    var q, fp;

    /// check if all values are the same, then return simplified form
    if (quantity.values.toSet().length == 1) {
      q = {'value': quantity.values.first};
    } else {
      q = _serializeSeries(quantity);
    }

    if (fixPrice.values.toSet().length == 1) {
      fp = {'value': fixPrice.values.first};
    } else {
      fp = _serializeSeries(fixPrice);
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

  /// Make a copy
  CommodityLeg copy() => CommodityLeg(
      curveId: curveId,
      bucket: bucket,
      timePeriod: timePeriod,
      quantitySchedule: quantitySchedule,
      fixPriceSchedule: fixPriceSchedule,
      tzLocation: tzLocation)
    ..asOfDate = asOfDate
    ..term = term
    ..buySell = buySell;

  /// if custom quantities, what to show on the screen in the UI
  num showQuantity() {
    var aux = hourlyQuantity.values.toSet();
    if (aux.length == 1) {
      return aux.first;
    }
    return 1.0;
  }

  /// if custom fixPrice, what to show on the screen in the UI
  num showFixPrice() {
    var aux = hourlyFixPrice.values.toSet();
    if (aux.length == 1) {
      return aux.first;
    }
    return 1.0;
  }
}

/// Input [xs] can be a hourly, daily, or monthly series.  Only ISO formats are
/// supported.
TimeSeries<Map<Bucket, num>> _parseSeries(
    Iterable<Map<String, dynamic>> xs, Location location, Bucket bucket) {
  var ts = TimeSeries<Map<Bucket, num>>();
  Interval Function(Map<String, dynamic>) parser;
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
