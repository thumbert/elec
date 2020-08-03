part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

class _BaseCfd {

  /// A collection of caches for different market and curve data.
  CacheProvider cacheProvider;

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
    var curveDetails = await cacheProvider.curveIdCache.get(curveId);
    var fwdMark = await cacheProvider.forwardMarksCache.get(Tuple2(asOfDate, curveId));

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
      var hSchedule = await cacheProvider.hourlyShapeCache
          .get(Tuple2(asOfDate, curveDetails['hourlyShapeCurveId']));
      var hShapeMultiplier =
          hSchedule.toHourly(term.interval.withTimeZone(location));
      /// multiply each hour by the shape factor
      res = res * hShapeMultiplier;
    }

    /// Check if you need to add settlement prices
    var startDate = Date.fromTZDateTime(fwdMark.first.interval.start);
    if (term.startDate.isBefore(startDate)) {
      /// need to get settlement data, return all hours of the term
      var settlementData = await cacheProvider
          .settlementPricesCache.get(Tuple2(term, curveId));
      if (term.interval.start.isBefore(settlementData.first.interval.start)) {
        // Clear the settlement cache if term start is earlier than existing
        // term.  This only gets executed once, for the first leg.
        await cacheProvider.settlementPricesCache.invalidateAll();
        settlementData = await cacheProvider.settlementPricesCache
            .get(Tuple2(term, curveId));
      }
      /// select only the bucket you need
      var sData = settlementData.where((e) => bucket.containsHour(e.interval));
      /// put it together
      res = TimeSeries<num>()..addAll([
        ...sData,
        ...res.window(Interval(sData.last.interval.end, term.interval.end)),
      ]);
    }

    return res;
  }


}

