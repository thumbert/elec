library risk_system.pricing.calculators.base.cache_provider;

import 'package:elec/risk_system.dart';
import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import 'package:more/cache.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:elec_server/client/marks/forward_marks.dart';

class CacheProvider {
  /// The keys are the curveId, data comes from marks/curve_ids collection
  Cache<String, Map<String, dynamic>> curveDetailsCache;

  /// The keys of the cache are tuples (asOfDate,curveId).
  /// for daily and monthly marks.  The timeseries data is hourly!
  Cache<Tuple2<Date, String>, TimeSeries<num>> forwardMarksCache;

  CacheProvider();

  /// An example of a CacheProvider implementation, that only provides
  /// the curve details and forward marks.
  CacheProvider.test(
      {Client client, String rootUrl = 'http://localhost:8080/'}) {
    client ??= Client();
    var curveIdClient = CurveIdClient(client, rootUrl: rootUrl);
    var forwardMarksClient = ForwardMarks(client, rootUrl: rootUrl);

    /// Populate fwdMarksCache given the asOfDate and the curveId.
    Future<TimeSeries<num>> _fwdMarksLoader(Tuple2<Date, String> tuple) async {
      var aux = await curveDetailsCache.get(tuple.item2);
      var location = getLocation(aux['tzLocation']);
      var marks = await forwardMarksClient
          .getForwardCurve(tuple.item2, tuple.item1, tzLocation: location);
      return marks.toHourly();
    }

    /// Loader for [curveIdCache] with all curveDetails
    Future<Map<String, dynamic>> _curveIdLoader(String curveId) {
      return curveIdClient.getCurveId(curveId);
    }

    curveDetailsCache =
        Cache<String, Map<String, dynamic>>.lru(loader: _curveIdLoader);
    forwardMarksCache = Cache<Tuple2<Date, String>, TimeSeries<num>>.lru(
        loader: _fwdMarksLoader);
  }
}
