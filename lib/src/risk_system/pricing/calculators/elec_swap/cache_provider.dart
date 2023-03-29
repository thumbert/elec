part of elec.calculators.elec_swap;

class CacheProvider extends CacheProviderBase {

  /// The keys of the cache are tuples (asOfDate,curveId).
  /// for daily and monthly marks.  The timeseries data is hourly!
  late Cache<Tuple2<Date, String>, TimeSeries<num>> forwardMarksCache;

  /// A cache for hourly settlement data, if available.  It makes sense for
  /// energy curves, but what do you do for other service types (LSCPR for
  /// example)?
  /// Cache key contains the curveId, e.g. isone_energy_4000_da_lmp.
  late Cache<Tuple2<Term, String>, TimeSeries<num>> settlementPricesCache;

  /// A cache for hourly shape curves, e.g. isone_energy_4000_hourlyshape.
  late Cache<Tuple2<Date, String>, TimeSeries<num>> hourlyShapeCache;

  CacheProvider();

  /// An example of a CacheProvider implementation
  CacheProvider.test(
      {Client? client, String rootUrl = 'http://localhost:8080'}) {
    client ??= Client();
    var curveIdClient = CurveIdClient(client, rootUrl: rootUrl);
    var forwardMarksClient = ForwardMarks(client, rootUrl: rootUrl);
    var daLmpClient = DaLmp(client, rootUrl: rootUrl);

    /// Populate fwdMarksCache given the asOfDate and the curveId.
    Future<TimeSeries<num>> _fwdMarksLoader(Tuple2<Date, String> tuple) async {
      var aux = await curveDetailsCache.get(tuple.item2);
      var location = getLocation(aux['tzLocation']);
      var marks = await forwardMarksClient
          .getForwardCurve(tuple.item2, tuple.item1, tzLocation: location);
      return marks.toHourly();
    }

    /// Populate the settlementPricesCache given the deal term and the curveId.
    /// For now, only support ISONE DA LMPs
    Future<TimeSeries<num>> _settlementPricesLoader(
        Tuple2<Term, String> tuple) async {
      var curveDetails = await curveDetailsCache.get(tuple.item2);
      var ptid = curveDetails['ptid'] as int;
      var start = tuple.item1.startDate;
      var end = tuple.item1.endDate;
      return await daLmpClient.getHourlyLmp(Iso.newEngland, ptid, LmpComponent.lmp, start, end);
    }

    /// Cache the HourlySchedule associated with this hourly shape.
    /// tuple.item2 = 'isone_energy_4000_hourlyshape'
    Future<TimeSeries<num>> _hourlyShapeLoader(
        Tuple2<Date, String> tuple) async {
      var aux = await curveDetailsCache.get(tuple.item2);
      var location = getLocation(aux['tzLocation']);
      var hs = await forwardMarksClient.getHourlyShape(tuple.item2, tuple.item1,
          tzLocation: location);
      return hs.toHourly();
    }

    /// Loader for [curveIdCache] with all curveDetails
    Future<Map<String, dynamic>> _curveIdLoader(String curveId) {
      return curveIdClient.getCurveId(curveId);
    }

    curveDetailsCache =
        Cache<String, Map<String, dynamic>>.lru(loader: _curveIdLoader);
    forwardMarksCache = Cache<Tuple2<Date, String>, TimeSeries<num>>.lru(
        loader: _fwdMarksLoader);
    hourlyShapeCache = Cache<Tuple2<Date, String>, TimeSeries<num>>.lru(
        loader: _hourlyShapeLoader);
    settlementPricesCache = Cache<Tuple2<Term, String>, TimeSeries<num>>.lru(
        loader: _settlementPricesLoader);
  }
}
