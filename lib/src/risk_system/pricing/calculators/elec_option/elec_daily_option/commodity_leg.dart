part of elec.calculators.elec_daily_option;

class CommodityLeg extends CommodityLegMonthly {
  CommodityLeg(
      {required String curveId,
      required Bucket bucket,
      required TimeSeries<num> quantity,
      required TimeSeries<num> fixPrice,
      required Location tzLocation,
      required this.callPut,
      required this.strike,
      required this.priceAdjustment,
      required this.volatilityAdjustment})
      : super(
            curveId: curveId,
            bucket: bucket,
            tzLocation: tzLocation,
            quantity: quantity,
            fixPrice: fixPrice) {
    // this.curveId = curveId;
    // this.bucket = bucket;
    // this.tzLocation = tzLocation;
    // this.quantity = quantity;
  }

  late String volatilityCurveId;

  late CallPut callPut;

  /// The strike of the option as a timeseries.  Often, all values are the same.
  late TimeSeries<num> strike;

  /// The [asOfDate] value of the underlying as a monthly timeseries.
  late TimeSeries<num> priceAdjustment;

  /// The [asOfDate] value of the volatility as a monthly timeseries.
  late TimeSeries<num> volatility;

  /// For clarification, values are as treated as numbers, e.g. a 5% adjustment
  /// is entered as 0.05.
  late TimeSeries<num> volatilityAdjustment;

  /// The [asOfDate] value of the interest rate as a monthly timeseries.
  late TimeSeries<num> interestRate;

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
  CommodityLeg.fromJson(Map<String, dynamic> x) : super.fromJson(x) {
    if (!x.containsKey('call/put')) {
      throw ArgumentError('Input needs to have \'call/put\' key.');
    }
    callPut = CallPut.parse(x['call/put']);

    var months = term.interval.splitLeft((dt) => Month.containing(dt));

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

  /// Make the leaves for this leg.  One leaf per month.
  @override
  void makeLeaves() {
    leaves = <LeafElecOption>[];
    var months = term.interval
        .withTimeZone(tzLocation)
        .splitLeft((dt) => Month.containing(dt));
    for (var i = 0; i < months.length; i++) {
      var _uPrice = underlyingPrice[i].value + priceAdjustment[i].value;
      var _volatility = volatility[i].value + volatilityAdjustment[i].value;
      var hours = bucket.countHours(months[i]);
      leaves.add(LeafElecOption(
        asOfDate: asOfDate,
        buySell: buySell,
        callPut: callPut,
        month: months[i],
        quantityTerm: quantity[i].value * hours,
        riskFreeRate: interestRate[i].value,
        strike: strike[i].value,
        underlyingPrice: _uPrice,
        volatility: _volatility,
        fixPrice: fixPrice[i].value,
      ));
    }
  }

  /// Calculate the fair value for this commodity leg.
  /// The quantity weighted option price of this leg.
  @override
  num price() {
    num hpq = 0; // hours * quantity * optionPrice
    num hq = 0; // hours * quantity
    for (var leaf in leaves) {
      hpq += leaf.quantityTerm * leaf.price();
      hq += leaf.quantityTerm;
    }
    return hpq / hq;
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

  /// Make a copy
  CommodityLeg copyWith({
    String? curveId,
    Bucket? bucket,
    TimeSeries<num>? quantity,
    TimeSeries<num>? fixPrice,
    Location? tzLocation,
    CallPut? callPut,
    TimeSeries<num>? strike,
    TimeSeries<num>? priceAdjustment,
    TimeSeries<num>? volatilityAdjustment,
  }) =>
      CommodityLeg(
        curveId: curveId ?? this.curveId,
        bucket: bucket ?? this.bucket,
        quantity: quantity ?? this.quantity,
        fixPrice: fixPrice ?? this.fixPrice,
        tzLocation: tzLocation ?? this.tzLocation,
        callPut: callPut ?? this.callPut,
        strike: strike ?? this.strike,
        priceAdjustment: priceAdjustment ?? this.priceAdjustment,
        volatilityAdjustment: volatilityAdjustment ?? this.volatilityAdjustment,
      )
        ..asOfDate = asOfDate
        ..term = term
        ..buySell = buySell;
}
