
import 'package:elec/elec.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/cache_provider.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/client/dalmp.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:elec_server/client/marks/forward_marks.dart';
import 'package:http/http.dart';
import 'package:more/cache.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

class CacheProvider extends CacheProviderBase {

  /// The keys of the cache are tuples (asOfDate,curveId).
  /// for daily and monthly marks.  The timeseries data is hourly!
  late Cache<(Date, String), TimeSeries<num>> forwardMarksCache;

  /// A cache for hourly settlement data, if available.  It makes sense for
  /// energy curves, but what do you do for other service types (LSCPR for
  /// example)?
  /// Cache key contains the curveId, e.g. isone_energy_4000_da_lmp.
  late Cache<(Term, String), TimeSeries<num>> settlementPricesCache;

  /// A cache for hourly shape curves, e.g. isone_energy_4000_hourlyshape.
  late Cache<(Date, String), TimeSeries<num>> hourlyShapeCache;

  CacheProvider();

  /// An example of a CacheProvider implementation
  CacheProvider.test(
      {Client? client, String rootUrl = 'http://localhost:8080'}) {
    client ??= Client();
    var curveIdClient = CurveIdClient(client, rootUrl: rootUrl);
    var forwardMarksClient = ForwardMarks(client, rootUrl: rootUrl);
    var daLmpClient = DaLmp(client, rootUrl: rootUrl);

    /// Populate fwdMarksCache given the asOfDate and the curveId.
    Future<TimeSeries<num>> fwdMarksLoader((Date, String) tuple) async {
      var aux = await curveDetailsCache.get(tuple.$2);
      var location = getLocation(aux['tzLocation']);
      var marks = await forwardMarksClient
          .getForwardCurve(tuple.$2, tuple.$1, tzLocation: location);
      return marks.toHourly();
    }

    /// Populate the settlementPricesCache given the deal term and the curveId.
    /// For now, only support ISONE DA LMPs
    Future<TimeSeries<num>> settlementPricesLoader(
        (Term, String) tuple) async {
      var curveDetails = await curveDetailsCache.get(tuple.$2);
      var ptid = curveDetails['ptid'] as int;
      var start = tuple.$1.startDate;
      var end = tuple.$1.endDate;
      return await daLmpClient.getHourlyLmp(Iso.newEngland, ptid, LmpComponent.lmp, start, end);
    }

    /// Cache the HourlySchedule associated with this hourly shape.
    /// tuple.item2 = 'isone_energy_4000_hourlyshape'
    Future<TimeSeries<num>> hourlyShapeLoader(
        (Date, String) tuple) async {
      var aux = await curveDetailsCache.get(tuple.$2);
      var location = getLocation(aux['tzLocation']);
      var hs = await forwardMarksClient.getHourlyShape(tuple.$2, tuple.$1,
          tzLocation: location);
      return hs.toHourly();
    }

    /// Loader for [curveIdCache] with all curveDetails
    Future<Map<String, dynamic>> curveIdLoader(String curveId) {
      return curveIdClient.getCurveId(curveId);
    }

    curveDetailsCache =
        Cache<String, Map<String, dynamic>>.lru(loader: curveIdLoader);
    forwardMarksCache = Cache<(Date, String), TimeSeries<num>>.lru(
        loader: fwdMarksLoader);
    hourlyShapeCache = Cache<(Date, String), TimeSeries<num>>.lru(
        loader: hourlyShapeLoader);
    settlementPricesCache = Cache<(Term, String), TimeSeries<num>>.lru(
        loader: settlementPricesLoader);
  }
}
