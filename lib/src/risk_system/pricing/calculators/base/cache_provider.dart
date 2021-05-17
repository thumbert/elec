library risk_system.pricing.calculators.base.cache_provider;

import 'package:http/http.dart';
import 'package:more/cache.dart';
// import 'package:elec_server/client/marks/curves/curve_id.dart';

class CacheProviderBase {
  /// The keys are the curveId, data comes from marks/curve_ids collection
  Cache<String, Map<String, dynamic>> curveDetailsCache;

  CacheProviderBase();

  /// An example of a CacheProvider implementation, that only provides
  /// the curve details and forward marks.
  CacheProviderBase.test(
      {Client client, String rootUrl = 'http://localhost:8080/'}) {
    client ??= Client();
    // var curveIdClient = CurveIdClient(client, rootUrl: rootUrl);

    /// Loader for [curveIdCache] with all curveDetails
    Future<Map<String, dynamic>> _curveIdLoader(String curveId) {
      return Future.value(<String,dynamic>{});  // FIXME: here
      // return curveIdClient.getCurveId(curveId);
    }

    curveDetailsCache =
        Cache<String, Map<String, dynamic>>.lru(loader: _curveIdLoader);
  }
}
