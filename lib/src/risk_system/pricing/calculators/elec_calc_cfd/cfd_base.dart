part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

class _BaseCfd {
  CurveIdClient curveIdClient;
  ForwardMarks forwardMarksClient;

  /// the keys are the curveId, data comes from marks/curve_ids collection
  Cache<String, Map<String, dynamic>> curveIdCache;

  /// The keys of the cache are tuples (asOfDate,curveId).
  /// for daily and monthly marks
  Cache<Tuple2<Date, String>, TimeSeries<Map<Bucket, num>>> forwardMarksCache;

  /// A cache for hourly settlement data, if available.  It makes sense for
  /// energy curves, but what do you do for other service types (LSCPR for
  /// example)?
  /// Cache key is curveId.
  Cache<String, TimeSeries<num>> settlementPricesCache;

  /// A cache for hourly shape curves
  Cache<Tuple2<Date, String>, HourlySchedule> hourlyShapeCache;

  Date _asOfDate;

  /// The pricing date.  It does not need a timezone.  UTC timezone is fine.
  Date get asOfDate => _asOfDate;
  set asOfDate(Date date) {
    _asOfDate = date;
  }

  BuySell _buySell;
  BuySell get buySell => _buySell;
  set buySell(BuySell buySell) {
    _buySell = buySell;
  }

  Term _term;
  Term get term => _term;
  set term(Term term) {
    _term = term;
  }

  /// Communicate an error with the UI.
  String error = '';

  var legs = <CommodityLeg>[];

  /// Get daily and monthly marks for a given curveId and bucket.
  /// LMP curves will also use an hourly shape curve to support non-standard
  /// buckets.
  ///
  /// Return a timeseries of hourly prices.
  Future<TimeSeries<num>> getFloatingPrice(Bucket bucket, String curveId) async {
    var curveDetails = await curveIdCache.get(curveId);
    var fwdMark = await forwardMarksCache.get(Tuple2(asOfDate, curveId));

    var location = fwdMark.first.interval.start.location;
    var _term = term.interval.withTimeZone(location);
    var ts = HourlySchedule.fromTimeSeriesWithBucket(fwdMark).toHourly(_term);
    var res = TimeSeries.fromIterable(
        ts.where((obs) => bucket.containsHour(obs.interval)));

    error = res.isEmpty
        ? 'No prices found in the Db for curve $curveId and bucket $bucket'
        : '';

    if (curveDetails.containsKey('hourlyShapeCurveId')) {
      /// get the hourly shaping curve
      var hSchedule = await hourlyShapeCache
          .get(Tuple2(asOfDate, curveDetails['hourlyShapeCurveId']));
      var hShapeMultiplier =
          hSchedule.toHourly(term.interval.withTimeZone(location));
      /// multiply each hour by the shape factor
      res = res * hShapeMultiplier;
    }

    /// Check if you need to add settlement prices
    var startDate = Date.fromTZDateTime(fwdMark.first.interval.start);
    if (term.startDate.isBefore(startDate)) {
      /// need to get settlement data
      var settlementData = await settlementPricesCache.get(curveId);
      if (term.interval.start.isBefore(settlementData.first.interval.start)) {
        // Clear the settlement cache if term start is earlier than existing
        // term.  This only gets executed once, for the first leg.
        await settlementPricesCache.invalidateAll();
        settlementData = await settlementPricesCache.get(curveId);
      }
      res = TimeSeries<num>()..addAll([
        ...settlementData.where((e) => bucket.containsHour(e.interval)),
        ...res,
      ]);
    }

    return res;
  }

  /// Populate fwdMarksCache given the asOfDate and the curveId.
  Future<TimeSeries<Map<Bucket, num>>> _fwdMarksLoader(
      Tuple2<Date, String> tuple) async {
    var aux = await curveIdCache.get(tuple.item2);
    var location = getLocation(aux['tzLocation']);
    return forwardMarksClient.getMonthlyForwardCurve(tuple.item2, tuple.item1,
        tzLocation: location);
  }

  /// Populate the settlementPricesCache given the deal term and the curveId.
  Future<TimeSeries<num>> _settlementPricesLoader(String curveId) async {
    var curveDetails = await curveIdCache.get(curveId);
    var location = getLocation(curveDetails['tzLocation']);
    var settlementSymbol = curveDetails['settlementSymbol'];
    return TimeSeries<num>();
  }


  /// Cache the HourlySchedule associated with this hourly shape.
  Future<HourlySchedule> _hourlyShapeLoader(Tuple2<Date, String> tuple) async {
    var aux = await curveIdCache.get(tuple.item2);
    var location = getLocation(aux['tzLocation']);
    var hs = await forwardMarksClient.getHourlyShape(tuple.item2, tuple.item1,
        tzLocation: location);
    return HourlySchedule.fromHourlyShape(hs);
  }

  Future<Map<String, dynamic>> _curveIdLoader(String curveId) {
//    print('in curve loader');
    return curveIdClient.getCurveId(curveId);
  }

}
