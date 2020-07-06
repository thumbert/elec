part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;


class CommodityLeg extends _BaseCfd {
  String curveId;
  String cashOrPhys;
  Bucket bucket;
  Location tzLocation;
  Map<String,dynamic> curveDetails;

  /// Can be monthly, daily or hourly time series
  TimeSeries<num> quantity;
  TimeSeries<num> fixPrice;
  TimeSeries<num> floatingPrice;

  /// if custom quantities or fixPrice, what to show on the screen in the UI
  num showQuantity, showFixPrice;

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
    curveId = (x['curveId'] as String).toLowerCase();
    tzLocation = getLocation(x['tzLocation']);
    cashOrPhys = (x['cash/physical'] as String).toLowerCase();
    if (x['bucket'] == null) {
      throw ArgumentError('Input needs to have key bucket');
    }
    bucket = Bucket.parse(x['bucket'])..location = tzLocation;
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

    if (x.containsKey('showQuantity')) {
      showQuantity = x['showQuantity'];
    } else {
      var aux = quantity.values.toSet();
      if (aux.length == 1) {
        showQuantity = aux.first;
      } else {
        throw ArgumentError('Quantity is customized.  Please set showQuantity.');
      }
    }
    if (x.containsKey('showFixPrice')) {
      showFixPrice = x['showFixPrice'];
    } else {
      var aux = fixPrice.values.toSet();
      if (aux.length == 1) {
        showFixPrice = aux.first;
      } else {
        throw ArgumentError('FixPrice is customized.  Please set showFixPrice.');
      }
    }
  }

  /// serialize it
  Map<String,dynamic> toJson() {
    return <String,dynamic>{
      'curveId': curveId,
      'cash/physical': cashOrPhys,
      'bucket': bucket.toString(),
      'quantity': _serializeSeries(quantity),
      'showQuantity': showQuantity,
      'fixPrice': _serializeSeries(fixPrice),
      'showFixPrice': showFixPrice,
    };
  }

}
