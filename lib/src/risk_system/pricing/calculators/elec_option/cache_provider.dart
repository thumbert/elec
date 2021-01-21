// library risk_system.pricing.calculators.elec_option.elec_option.cache_provider;
//

part of elec.calculators.elec_daily_option;

class CacheProviderElecOption extends CacheProviderBase {
  /// The keys are the curveId, data comes from marks/curve_ids collection
  @override
  Cache<String, Map<String, dynamic>> curveDetailsCache;

  /// The keys of the cache are tuples (asOfDate, curveId).
  /// For monthly price marks and the discount rate.  The timeseries data
  /// is monthly.
  Cache<Tuple2<Date, String>, PriceCurve> forwardMarksCache;

  /// The keys of the cache are tuples (asOfDate, volatilityCurveId).
  Cache<Tuple2<Date, String>, VolatilitySurface> volSurfaceCache;

  CacheProviderElecOption();

  /// An example of a CacheProvider implementation
  CacheProviderElecOption.test(
      {Client client, String rootUrl = 'http://localhost:8080/'}) {
    client ??= Client();
    var curveIdClient = CurveIdClient(client, rootUrl: rootUrl);
    var forwardMarksClient = ForwardMarks(client, rootUrl: rootUrl);

    /// Populate fwdMarksCache given the asOfDate and the curveId.
    Future<PriceCurve> _fwdMarksLoader(Tuple2<Date, String> tuple) async {
      var aux = await curveDetailsCache.get(tuple.item2);
      var location = getLocation(aux['tzLocation']);
      var marks = await forwardMarksClient
          .getForwardCurve(tuple.item2, tuple.item1, tzLocation: location);
      return marks.monthlyComponent();
    }

    /// Populate volSurfaceCache given the asOfDate and the volatility curveId.
    Future<VolatilitySurface> _volSurfaceLoader(
        Tuple2<Date, String> tuple) async {
      var aux = await curveDetailsCache.get(tuple.item2);
      var location = getLocation(aux['tzLocation']);
      return forwardMarksClient.getVolatilitySurface(tuple.item2, tuple.item1,
          tzLocation: location);
    }

    /// Loader for [curveIdCache] with all curveDetails
    Future<Map<String, dynamic>> _curveIdLoader(String curveId) {
      return curveIdClient.getCurveId(curveId);
    }

    curveDetailsCache =
        Cache<String, Map<String, dynamic>>.lru(loader: _curveIdLoader);
    forwardMarksCache =
        Cache<Tuple2<Date, String>, PriceCurve>.lru(loader: _fwdMarksLoader);
    volSurfaceCache = Cache<Tuple2<Date, String>, VolatilitySurface>.lru(
        loader: _volSurfaceLoader);
  }
}
