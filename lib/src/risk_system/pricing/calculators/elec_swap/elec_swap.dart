part of elec.calculators.elec_swap;

class ElecSwapCalculator
    extends CalculatorBase<CommodityLegElecSwap, CacheProviderElecSwap> {
  ElecSwapCalculator(
      {Date asOfDate,
      Term term,
      BuySell buySell,
      List<CommodityLegElecSwap> legs,
      CacheProviderElecSwap cacheProvider}) {
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
      // if asOfDate is not specified, it means today
      x['asOfDate'] = Date.today().toString();
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

    legs = <CommodityLegElecSwap>[];
    var _aux = x['legs'] as List;
    for (Map<String, dynamic> e in _aux) {
      e['asOfDate'] = x['asOfDate'];
      e['term'] = x['term'];
      e['buy/sell'] = x['buy/sell'];
      var leg = CommodityLegElecSwap.fromJson(e);
      legs.add(leg);
    }
  }

  /// After you make a change to the calculator that affects the floating price,
  /// you need to rebuild it before repricing it.
  ///
  /// If you change the term, the pricing date, any of the leg buckets, etc.
  /// It is a brittle design, because people may forget to call it.
  @override
  Future<void> build() async {
    for (var leg in legs) {
      var curveDetails = await cacheProvider.curveDetailsCache.get(leg.curveId);
      leg.tzLocation = getLocation(curveDetails['tzLocation']);
      leg.hourlyFloatingPrice = await getFloatingPrice(leg.bucket, leg.curveId);
      leg.makeLeaves();
    }
  }

  /// Get the total dollar value of this calculator.
  /// Need to build() the calculator first.
  // @override
  // num dollarPrice() {
  //   var value = 0.0;
  //   for (var leg in legs) {
  //     for (var leaf in leg.leaves) {
  //       value += leaf.dollarPrice();
  //     }
  //   }
  //   return value;
  // }

  Report flatReport() => FlatReportElecCfd(this);

  Report monthlyPositionReport() => MonthlyPositionReportElecCfd(this);

  @override
  String showDetails() {
    var table = <Map<String, dynamic>>[];
    for (var leg in legs) {
      for (LeafElecSwap leaf in leg.leaves) {
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
  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'calculatorType': 'elec_swap',
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [for (var leg in legs) leg.toJson()],
    };
  }

  /// Get daily and monthly marks for a given curveId and bucket.
  /// LMP curves will also use an hourly shape curve to support non-standard
  /// buckets.
  ///
  /// Return a timeseries of hourly prices, for only the hours of interest.
  Future<TimeSeries<num>> getFloatingPrice(
      Bucket bucket, String curveId) async {
    CacheProviderElecSwap cp = cacheProvider;
    var curveDetails = await cp.curveDetailsCache.get(curveId);
    var fwdMarks = await cp.forwardMarksCache.get(Tuple2(asOfDate, curveId));

    var location = fwdMarks.first.interval.start.location;
    var _term = term.interval.withTimeZone(location);
    var res = TimeSeries.fromIterable(fwdMarks
        .window(_term)
        .where((obs) => bucket.containsHour(obs.interval)));

    error = res.isEmpty
        ? 'No prices found in the Db for curve $curveId and bucket $bucket'
        : '';

    if (curveDetails.containsKey('hourlyShapeCurveId')) {
      /// get the hourly shaping curve if needed
      var hSchedule = await cp.hourlyShapeCache
          .get(Tuple2(asOfDate, curveDetails['hourlyShapeCurveId']));
      var hShapeMultiplier = TimeSeries.fromIterable(
          hSchedule.window(term.interval.withTimeZone(location)));

      /// multiply each hour by the shape factor
      res = res * hShapeMultiplier;
    }

    /// Check if you need to add settlement prices
    var startDate = Date.fromTZDateTime(fwdMarks.first.interval.start);
    if (term.startDate.isBefore(startDate)) {
      /// need to get settlement data, return all hours of the term
      var settlementData =
          await cp.settlementPricesCache.get(Tuple2(term, curveId));
      if (term.interval.start.isBefore(settlementData.first.interval.start)) {
        // Clear the settlement cache if term start is earlier than existing
        // term.  This only gets executed once, for the first leg.
        await cp.settlementPricesCache.invalidateAll();
        settlementData =
            await cp.settlementPricesCache.get(Tuple2(term, curveId));
      }

      /// select only the bucket you need
      var sData = settlementData.where((e) => bucket.containsHour(e.interval));

      /// put it together
      res = TimeSeries<num>()
        ..addAll([
          ...sData,
          ...res.window(Interval(sData.last.interval.end, term.interval.end)),
        ]);
    }

    return res;
  }

  static final _fmtQty = NumberFormat.currency(symbol: '', decimalDigits: 0);
  static final _fmtCurrency0 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _fmtCurrency4 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 4);
}
