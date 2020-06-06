part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;


class CommodityLeg extends _BaseCfd {
  CurveId curveId;
  String cashOrPhys;
  Bucket bucket;

  /// Can be monthly, daily or hourly time series
  TimeSeries<num> quantity;
  TimeSeries<num> fixPrice;
  TimeSeries<num> floatingPrice;

  /// Leg leaves
  List<Leaf> leaves;

  /// Fair value for this commodity leg
  num _price;


  /// Get the quantity weighted floating price for this leg.
  /// Needs [leaves] to be populated.
  num get price {
    if (_price == null) {
      num hpq = 0; // hours * quantity * floatingPrice
      num hq = 0;  // hours * quantity
      for (var leaf in leaves) {
        hpq += leaf.hours * leaf.quantity * leaf.floatingPrice;
        hq += leaf.hours * leaf.quantity;
      }
      _price = hpq/hq;
    }
    return _price;
  }

  /// Get the [floatingPrice] from a provider if not passed in during
  /// construction.
  Future<TimeSeries<num>> getFloatingPrice() async {
    if (floatingPrice == null) {
      var aux = await _dataProvider.getForwardCurveForBucket(curveId, bucket, asOfDate);
      floatingPrice = TimeSeries.fromIterable(aux.timeseries.window(term.interval));
    }
    return floatingPrice;
  }

  /// Make the leaves for this leg.  Needs [floatingPrice].
  /// One leaf per period.
  void makeLeaves() {
    leaves = <Leaf>[];
    if (timePeriod == TimePeriod.month) {
      for (var qty in quantity) {
        Month month = qty.interval;
        var _fixPrice = fixPrice.observationAt(month).value;
        var _floatPrice = floatingPrice.observationAt(month).value;
        var hours = bucket.countHours(month);
        leaves.add(Leaf(buySell, qty.interval, qty.value, _fixPrice,
            _floatPrice, hours));
      }
    } else {
      /// TODO: continue me
      throw UnimplementedError('Not implemented $timePeriod');
    }
  }


  /// need to support hourly, daily and monthly quantities/fixPrices
  CommodityLeg.fromJson(Map<String,dynamic> x) {
    if (x['curveId'] == null) {
      throw ArgumentError('Input needs to have key curveId');
    }
    curveId = CurveId(x['curveId'] as String);
    cashOrPhys = x['cash/physical'];
    if (x['bucket'] == null) {
      throw ArgumentError('Input needs to have key bucket');
    }
    bucket = Bucket.parse(x['bucket']);
    /// quantities are specified as a List of {'month': '2020-01', 'value': 40.0}
    quantity = _parseSeries(x['quantity'], bucket.location);
    /// prices are specified as a List of {'month': '2020-01', 'value': 40.0}
    fixPrice = _parseSeries(x['fixPrice'], bucket.location);

    /// establish the time period for the series
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
  }

  /// serialize it
  Map<String,dynamic> toJson() {
    return <String,dynamic>{
      'curveId': curveId.name,
      'cash/physical': cashOrPhys,
      'bucket': bucket.toString(),
      'quantity': _serializeSeries(quantity),
      'fixPrice': _serializeSeries(fixPrice),
    };
  }

}
