
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/cache_provider.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:elec_server/client/marks/forward_marks.dart';
import 'package:http/http.dart';
import 'package:more/cache.dart';
import 'package:timezone/timezone.dart';

class CacheProvider extends CacheProviderBase {
  /// The keys of the cache are tuples (asOfDate, curveId).
  /// For monthly price marks and the discount rate.  The timeseries data
  /// is monthly.
  late Cache<(Date, String), PriceCurve> forwardMarksCache;

  /// The keys of the cache are tuples (asOfDate, volatilityCurveId).
  late Cache<(Date, String), VolatilitySurface> volSurfaceCache;

  CacheProvider();

  /// An example of a CacheProvider implementation
  CacheProvider.test(
      {Client? client, String rootUrl = 'http://localhost:8080'}) {
    client ??= Client();
    var curveIdClient = CurveIdClient(client, rootUrl: rootUrl);
    var forwardMarksClient = ForwardMarks(client, rootUrl: rootUrl);

    /// Populate fwdMarksCache given the asOfDate and the curveId.
    Future<PriceCurve> fwdMarksLoader((Date, String) tuple) async {
      var aux = await curveDetailsCache.get(tuple.$2);
      var location = getLocation(aux['tzLocation']);
      var marks = await forwardMarksClient
          .getForwardCurve(tuple.$2, tuple.$1, tzLocation: location);
      return marks.monthlyComponent();
    }

    /// Populate volSurfaceCache given the asOfDate and the volatility curveId.
    Future<VolatilitySurface> volSurfaceLoader(
        (Date, String) tuple) async {
      var aux = await curveDetailsCache.get(tuple.$2);
      var location = getLocation(aux['tzLocation']);
      return forwardMarksClient.getVolatilitySurface(tuple.$2, tuple.$1,
          tzLocation: location);
    }

    /// Loader for [curveIdCache] with all curveDetails
    Future<Map<String, dynamic>> curveIdLoader(String curveId) {
      return curveIdClient.getCurveId(curveId);
    }

    curveDetailsCache =
        Cache<String, Map<String, dynamic>>.lru(loader: curveIdLoader);
    forwardMarksCache =
        Cache<(Date, String), PriceCurve>.lru(loader: fwdMarksLoader);
    volSurfaceCache = Cache<(Date, String), VolatilitySurface>.lru(
        loader: volSurfaceLoader);
  }
}
