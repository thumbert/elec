library risk_system.pricing.calculators.base.cache_provider;

import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/common_enums.dart';
import 'package:elec/src/time/hourly_schedule.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import 'package:more/cache.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:elec_server/client/marks/forward_marks.dart';

class CacheProvider {
  /// The keys are the curveId, data comes from marks/curve_ids collection
  Cache<String, Map<String, dynamic>> curveIdCache;

  /// The keys of the cache are tuples (asOfDate,curveId).
  /// for daily and monthly marks
  Cache<Tuple2<Date, String>, TimeSeries<Map<Bucket, num>>> forwardMarksCache;

  /// A cache for hourly settlement data, if available.  It makes sense for
  /// energy curves, but what do you do for other service types (LSCPR for
  /// example)?
  /// Cache key is curveId.
  Cache<Tuple2<Term,String>, TimeSeries<num>> settlementPricesCache;

  /// A cache for hourly shape curves
  Cache<Tuple2<Date, String>, HourlySchedule> hourlyShapeCache;

  CacheProvider();

  /// An example of a CacheProvider implementation
  CacheProvider.test({Client client, String rootUrl = 'http://localhost:8080/'}) {
    client ??= Client();
    var curveIdClient = CurveIdClient(client, rootUrl: rootUrl);
    var forwardMarksClient = ForwardMarks(client, rootUrl: rootUrl);
    var daLmpClient = DaLmp(client, rootUrl: rootUrl);

  /// Populate fwdMarksCache given the asOfDate and the curveId.
    Future<TimeSeries<Map<Bucket, num>>> _fwdMarksLoader(
        Tuple2<Date, String> tuple) async {
      var aux = await curveIdCache.get(tuple.item2);
      var location = getLocation(aux['tzLocation']);
      return forwardMarksClient.getMonthlyForwardCurve(tuple.item2, tuple.item1,
          tzLocation: location);
    }

    /// Populate the settlementPricesCache given the deal term and the curveId.
    /// For now, only support ISONE DA LMPs
    Future<TimeSeries<num>> _settlementPricesLoader(Tuple2<Term,String> tuple) async {
      var curveDetails = await curveIdCache.get(tuple.item2);
      var ptid = curveDetails['ptid'] as int;
      var start = tuple.item1.startDate;
      var end = tuple.item1.endDate;
      return await daLmpClient.getHourlyLmp(ptid, LmpComponent.lmp, start, end);
    }

    /// Cache the HourlySchedule associated with this hourly shape.
    Future<HourlySchedule> _hourlyShapeLoader(
        Tuple2<Date, String> tuple) async {
      var aux = await curveIdCache.get(tuple.item2);
      var location = getLocation(aux['tzLocation']);
      var hs = await forwardMarksClient.getHourlyShape(tuple.item2, tuple.item1,
          tzLocation: location);
      return HourlySchedule.fromHourlyShape(hs);
    }

    /// Loader for [curveIdCache] with all curveDetails
    Future<Map<String, dynamic>> _curveIdLoader(String curveId) {
      return curveIdClient.getCurveId(curveId);
    }

    curveIdCache =
        Cache<String, Map<String, dynamic>>.lru(loader: _curveIdLoader);
    forwardMarksCache =
        Cache<Tuple2<Date, String>, TimeSeries<Map<Bucket, num>>>.lru(
            loader: _fwdMarksLoader);
    hourlyShapeCache = Cache<Tuple2<Date, String>, HourlySchedule>.lru(
        loader: _hourlyShapeLoader);
    settlementPricesCache = Cache<Tuple2<Term, String>, TimeSeries<num>>.lru(
      loader: _settlementPricesLoader);
  }
}
