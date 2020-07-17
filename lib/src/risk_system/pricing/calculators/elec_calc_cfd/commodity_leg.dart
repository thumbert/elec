part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

class CommodityLeg {
  String curveId;
  String cashOrPhys;
  Bucket bucket;
  Location tzLocation;
  Map<String, dynamic> curveDetails;

  TimePeriod timePeriod;

  /// Can be monthly, daily or hourly time series
  TimeSeries<num> quantity;
  TimeSeries<num> fixPrice;
  TimeSeries<num> floatingPrice;

  ElecCalculatorCfd calculator;

  CommodityLeg(this.calculator);

  /// Leg leaves
  List<Leaf> leaves;

  /// Fair value for this commodity leg
  num _price;


  /// Get the quantity weighted floating price for this leg.
  /// Needs [leaves] to be populated.
  num get price {
    if (_price == null) {
      num hpq = 0; // hours * quantity * floatingPrice
      num hq = 0; // hours * quantity
      for (var leaf in leaves) {
        hpq += leaf.hours * leaf.quantity * leaf.floatingPrice;
        hq += leaf.hours * leaf.quantity;
      }
      _price = hpq / hq;
    }
    return _price;
  }

  /// Make the leaves for this leg.  Needs [floatingPrice].
  /// One leaf per period.
  void makeLeaves() {
    leaves = <Leaf>[];
    if (timePeriod == TimePeriod.month) {
      var months = calculator.term.interval
          .withTimeZone(tzLocation)
          .splitLeft((dt) => Month.fromTZDateTime(dt));
      for (var month in months) {
        var _quantity = quantity.observationAt(month).value;
        var _fixPrice = fixPrice.observationAt(month).value;
        var _floatPrice = floatingPrice.observationAt(month).value;
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
    tzLocation = getLocation(curveDetails['tzLocation']);
    cashOrPhys = (x['cash/physical'] as String).toLowerCase();
    if (x['bucket'] == null) {
      throw ArgumentError('Json input is missing the key bucket');
    }
    bucket = Bucket.parse(x['bucket']);

    /// quantities are specified as a List of {'month': '2020-01', 'value': 40.0}
    quantity = _parseSeries(x['quantity'], tzLocation);

    if (x.containsKey('fixPrice')) {
      /// fix prices are specified as a List of {'month': '2020-01', 'value': 40.0}
      fixPrice = _parseSeries(x['fixPrice'], tzLocation);
    } else {
      fixPrice = TimeSeries.fill(quantity.intervals, 0.0);
    }

    /// establish the time period for the leg
    var _keys = ((x['quantity'] as List).first as Map).keys;
    if (_keys.contains('month')) {
      timePeriod = TimePeriod.month;
    } else if (_keys.contains('date')) {
      timePeriod = TimePeriod.day;
    } else if (_keys.contains('hourBeginning')) {
      timePeriod = TimePeriod.hour;
    } else {
      throw ArgumentError('Leg quantity does\'t contain one of accepted time'
          'periods: month, date, hourBeginning');
    }

    /// get the floating price from the cache
    floatingPrice = await calculator.getFloatingPrice(bucket, curveId,
        timePeriod);
  }


  /// serialize it
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'curveId': curveId,
      'cash/physical': cashOrPhys,
      'bucket': bucket.toString(),
      'quantity': _serializeSeries(quantity),
      'fixPrice': _serializeSeries(fixPrice),
    };
  }

  /// if custom quantities, what to show on the screen in the UI
  num showQuantity() {
    var aux = quantity.values.toSet();
    if (aux.length == 1) {
      return aux.first;
    }
    return 1.0;
  }

  /// if custom fixPrice, what to show on the screen in the UI
  num showFixPrice() {
    var aux = fixPrice.values.toSet();
    if (aux.length == 1) {
      return aux.first;
    }
    return 1.0;
  }

}
