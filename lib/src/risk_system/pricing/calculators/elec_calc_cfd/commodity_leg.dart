part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

class CommodityLeg {
  String curveId;
  String region;
  String serviceType;
  String curveName;
  String cashOrPhys;
  Bucket bucket;
  Location tzLocation;

  /// The time period of the leg which applies to all the leaves.  It is set at
  /// the lower time period of quantity and fixPrice.  For example, if quantity
  /// is [TimePeriod.month] and fixPrice is [TimePeriod.hour], the timePeriod
  /// for the leg is set to [TimePeriod.hour].
  ///
  TimePeriod timePeriod;

  /// An hourly time series
  TimeSeries<num> hourlyFloatingPrice;

  /// If you have a custom quantity, only intervals included in the
  /// [term] are valid.
  HourlySchedule quantitySchedule;
  HourlySchedule fixPriceSchedule;

  ElecCalculatorCfd calculator;

  CommodityLeg(this.calculator);

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
    var term = calculator.term.interval.withTimeZone(tzLocation);
    if (timePeriod == TimePeriod.month) {
      return quantitySchedule.toMonthly(term, mean);
    } else {
      throw UnimplementedError('Not implemented ${timePeriod}');
    }
  }

  /// Get the leg quantity as an hourly timeseries.
  TimeSeries<num> get hourlyQuantity {
    var term = calculator.term.interval.withTimeZone(tzLocation);
    return quantitySchedule.toHourly(term);
  }

  /// Get the leg quantity as a timeseries
  TimeSeries<num> get fixPrice {
    var term = calculator.term.interval.withTimeZone(tzLocation);
    if (timePeriod == TimePeriod.month) {
      return fixPriceSchedule.toMonthly(term, mean);
    } else {
      throw UnimplementedError('Not implemented ${timePeriod}');
    }
  }


  /// Get the leg fixPrice as an hourly timeseries.
  TimeSeries<num> get hourlyFixPrice {
    var term = calculator.term.interval.withTimeZone(tzLocation);
    return fixPriceSchedule.toHourly(term);
  }

  /// Make the leaves for this leg.  One leaf per period.
  void makeLeaves() {
    leaves = <Leaf>[];
    if (timePeriod == TimePeriod.month) {
      var months = calculator.term.interval
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
        leaves.add(Leaf(calculator.buySell, month, _quantity, _fixPrice,
            _floatPrice, hours));
      }
    } else {
      /// TODO: continue me
      throw UnimplementedError('Not implemented ${timePeriod}');
    }
  }

  /// Support hourly, daily and monthly quantities/fixPrices.
  /// Method is async because it uses [curveIdCache] and [forwardMarksCache].
  void fromJson(Map<String, dynamic> x) async {
    if (x['curveId'] == null) {
      throw ArgumentError('Json input is missing the key curveId');
    }
    curveId = (x['curveId'] as String).toLowerCase();
    var curveDetails = await calculator.curveIdCache.get(curveId);
    region = curveDetails['region'];
    serviceType = curveDetails['serviceType'];
    curveName = curveDetails['curve'];
    tzLocation = getLocation(curveDetails['tzLocation']);
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
      var aux = _parseSeries(qValue.cast<Map<String, dynamic>>(), tzLocation, bucket);
      quantitySchedule = HourlySchedule.fromTimeSeries(aux);
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
        var aux = _parseSeries(qValue.cast<Map<String, dynamic>>(), tzLocation, bucket);
        fixPriceSchedule = HourlySchedule.fromTimeSeries(aux);
        if (aux.first.interval is Date &&
            timePeriod != TimePeriod.hour) {
          timePeriod = TimePeriod.day;
        } else if (aux.first.interval is Hour) {
          timePeriod = TimePeriod.hour;
        }
      }
    } else {
      fixPriceSchedule = HourlySchedule.filled(0.0);
    }
    
    
    /// get the floating price from the cache
    hourlyFloatingPrice = await calculator.getFloatingPrice(bucket, curveId);
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
      'cash/physical': cashOrPhys,
      'bucket': bucket.toString(),
      'quantity': q,
      'fixPrice': fp,
    };
  }

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

final DateFormat _monthFmt = DateFormat('yyyy-MM');

/// Input [xs] can be a hourly, daily, or monthly series.  Only ISO formats are
/// supported.
TimeSeries<Map<Bucket,num>> _parseSeries(
    Iterable<Map<String, dynamic>> xs, Location location, Bucket bucket) {
  var ts = TimeSeries<Map<Bucket,num>>();
  Interval Function(Map<String, dynamic>) parser;
  if (xs.first.keys.contains('month')) {
    parser = (e) => Month.parse(e['month'], location: location, fmt: _monthFmt);
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

