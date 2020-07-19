part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

class _BaseCfd {
  CurveIdClient curveIdClient;
  ForwardMarks forwardMarksClient;

  /// the keys are the curveId, data comes from marks/curve_ids collection
  Cache<String, Map<String, dynamic>> curveIdCache;

  /// The keys of the cache are tuples (asOfDate,curveId).
  /// for daily and monthly marks
  Cache<Tuple2<Date, String>, TimeSeries<Map<Bucket, num>>> forwardMarksCache;
  /// for hourly shape curves
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


  var legs = <CommodityLeg>[];

  /// Get daily and monthly marks.  LMP curves will also get hourly shape curve.
  /// Return monthly, daily or hourly prices.  The frequency is determined by
  /// the [timePeriod] argument, which is set by the leg quantity timeseries
  /// granularity.
  Future<TimeSeries<num>> getFloatingPrice(Bucket bucket,
      String curveId, TimePeriod timePeriod) async {
    timePeriod ??= TimePeriod.hour;
    var fwdMark = await forwardMarksCache.get(Tuple2(asOfDate, curveId));
    var curveDetails = await curveIdCache.get(curveId);

    var location = fwdMark.first.interval.start.location;
    var ts = HourlySchedule.fromTimeSeries(fwdMark)
        .toHourly(term.interval.withTimeZone(location));
    var res = TimeSeries.fromIterable(
        ts.where((obs) => bucket.containsHour(obs.interval)));

    if (curveDetails.containsKey('hourlyShapeCurveId')) {
      /// get the hourly shaping curve
      var hSchedule = await hourlyShapeCache.get(Tuple2(asOfDate,
          curveDetails['hourlyShapeCurveId']));
      var hShapeMultiplier = hSchedule.toHourly(term.interval.withTimeZone(location));
      /// multiply each hour by the shape factor
      res = res * hShapeMultiplier;
    }

    if (timePeriod == TimePeriod.month) {
      res = toMonthly(res, mean);
    } else if ( timePeriod == TimePeriod.day) {
      res = toDaily(res, mean);
    }
    return res;
  }

  Future<TimeSeries<Map<Bucket,num>>> _fwdMarksLoader(
      Tuple2<Date, String> tuple) async {
    var aux = await curveIdCache.get(tuple.item2);
    var location = getLocation(aux['tzLocation']);
    return forwardMarksClient.getMonthlyForwardCurve(tuple.item2, tuple.item1,
        tzLocation: location);
  }

  /// Decided to cache the HourlySchedule associated with this hourly shape.
  Future<HourlySchedule> _hourlyShapeLoader(Tuple2<Date, String> tuple) async {
    var aux = await curveIdCache.get(tuple.item2);
    var location = getLocation(aux['tzLocation']);
    var hs = await forwardMarksClient.getHourlyShape(tuple.item2, tuple.item1,
        tzLocation: location);
    return HourlySchedule.fromHourlyShape(hs);
  }


  Future<Map<String, dynamic>> _curveIdLoader(String curveId) =>
      curveIdClient.getCurveId(curveId);
}
