part of elec.calculators;

enum TimePeriod { month, day, hour }

class ElecSwapCalculator extends CalculatorBase {
  ElecSwapCalculator(
      {Date asOfDate,
      Term term,
      BuySell buySell,
      List<CommodityLeg> legs,
      CacheProvider cacheProvider}) {
    this.asOfDate = asOfDate;
    this.term = term;
    this.buySell = buySell;
    this.legs = legs ?? super.legs;
    // these 3 properties are needed for the legs
    for (var leg in this.legs) {
      leg.asOfDate = asOfDate;
      leg.term = term;
      leg.buySell = buySell;
    }
    this.cacheProvider = cacheProvider;
  }

  /// The recommended way to initialize from a template.  See tests.
  /// Still needs [cacheProvider] to be set.
  ElecSwapCalculator.fromJson(Map<String, dynamic> x) {
    if (x['calculatorType'] != 'elec_swap') {
      throw ArgumentError('Json input needs a key calculatorType = elec_swap');
    }

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
      e['asOfDate'] = x['asOfDate'];
      e['term'] = x['term'];
      e['buy/sell'] = x['buy/sell'];
      var leg = CommodityLeg.fromJson(e);
      legs.add(leg);
    }
  }

  /// Return [true] if the calculator has custom quantities and prices, i.e.
  /// not the same value for all time intervals.
  bool hasCustom() {
    var res = false;
    for (var leg in legs) {
      if (leg.timePeriod != TimePeriod.month) return true;
    }
    return res;
  }

  /// After you make a change to the calculator that affects the floating price,
  /// you need to rebuild it before repricing it.
  ///
  /// If you change the term, the pricing date, any of the leg buckets, etc.
  /// It is a brittle design, because people may forget to call it.
  Future<void> build() async {
    for (var leg in legs) {
      var curveDetails = await cacheProvider.curveIdCache.get(leg.curveId);
      leg.tzLocation = getLocation(curveDetails['tzLocation']);
      leg.hourlyFloatingPrice = await getFloatingPrice(leg.bucket, leg.curveId);
      leg.makeLeaves();
    }
  }

  /// Get the total dollar value of this calculator.
  /// Need to build() the calculator first.
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

  @override
  String showDetails() {
    var table = <Map<String, dynamic>>[];
    for (var leg in legs) {
      for (var leaf in leg.leaves) {
        table.add({
          'term': leaf.interval.toString(),
          'curveId': leg.curveId,
          'bucket': leg.bucket.toString(),
          'nominalQuantity':
              _fmtQty.format(buySell.sign * leaf.quantity * leaf.hours),
          'forwardPrice': _fmtCurrency4.format(leaf.floatingPrice),
          'value': _fmtCurrency0.format(
              buySell.sign * leaf.quantity * leaf.hours * leaf.floatingPrice),
        });
      }
      // table.add(emptyRow);
    }
    var _tbl = Table.from(table, options: {
      'columnSeparation': '  ',
    });
    return _tbl.toString();
  }

  /// TODO: implement a copyWith() method.

  /// Serialize it.  Don't serialize 'asOfDate' or 'floatingPrice' info.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'calculatorType': 'elec_swap',
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [for (var leg in legs) leg.toJson()],
    };
  }

  static final _fmtQty = NumberFormat.currency(symbol: '', decimalDigits: 0);
  static final _fmtCurrency0 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _fmtCurrency4 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 4);
}

// var _emptyRow = Map.fromIterables(
//     ['term', 'curveId', 'bucket', 'nominalQuantity', 'forwardPrice', 'value'],
//     ['', '', '', '', '', '']);
