part of risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

class _BaseCfd {
  CurveIdClient curveIdClient;
  ForwardMarks forwardMarksClient;

  /// the keys are the curveId, data comes from marks/curve_ids collection
  Cache<String, Map<String, dynamic>> curveIdCache;

  /// The keys of the cache are tuples (asOfDate,curveId)
  Cache<Tuple2<Date, String>, TimeSeries<Map<Bucket, num>>> forwardMarksCache;

  //_BaseCfd();

  Date _asOfDate;

  /// Does not need local timezone.  UTC timezone is fine.
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

  /// Return monthly, daily or hourly prices
  Future<TimeSeries<num>> getForwardMarks(Date asOfDate, Bucket bucket,
      String curveId, TimePeriod timePeriod) async {
    timePeriod ??= TimePeriod.hour;
    var aux = await forwardMarksCache.get(Tuple2(asOfDate, curveId));
    var location = aux.first.interval.start.location;
    var ts = HourlySchedule.fromTimeSeries(TimeSeries.fromIterable(aux))
        .toHourly(term.interval.withTimeZone(location));
    var res = TimeSeries.fromIterable(
        ts.where((obs) => bucket.containsHour(obs.interval)));
    if (timePeriod == TimePeriod.month) {
      res = toMonthly(res, mean);
    } else if ( timePeriod == TimePeriod.day) {
      res = toDaily(res, mean);
    }
    return res;
  }

  Future<TimeSeries<Map<Bucket, num>>> _fwdMarksLoader(
      Tuple2<Date, String> tuple) async {
    var aux = await curveIdCache.get(tuple.item2);
    var location = getLocation(aux['tzLocation']);
    return forwardMarksClient.getMonthlyForwardCurve(tuple.item2, tuple.item1,
        tzLocation: location);
  }

  Future<Map<String, dynamic>> _curveIdLoader(String curveId) =>
      curveIdClient.getCurveId(curveId);
}
