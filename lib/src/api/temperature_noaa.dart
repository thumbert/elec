library api.temperature_noaa;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

class Result {
  String? result;
  Result();
}

/// Expose the NOAA daily temperatures as a web service
///
// @ApiClass(name:'noaa', version: 'v1')
class ApiTemperatureNoaa {
  late Db db;
  late DbCollection coll;

  ApiTemperatureNoaa();

  Future init() async {
    db = Db("mongodb://localhost:27017/weather");
    await db.open();
    coll = db.collection('daily');
  }

  /// Get the daily historical min/max temperatures for a
  /// given station GHCND identifier.
  /// http://localhost:8080/noaa/v1/ghcnd/USW00014739
  /// Return a list of strings
  /// [[19800101,26,38], [19800102,26,37], ...]
  // @ApiMethod(path: 'ghcnd/{ghcnd}')
  Future<List<List<String?>>> getTemperature(String ghcnd) async {
    //String ghcnd = 'USW00014739';
    List pipeline = [];
    Map match = {
      'station': {'\$eq': 'GHCND:$ghcnd'}
    };
    Map project = {'_id': 0, 'date': 1, 'tmin': 1, 'tmax': 1};
    pipeline.add({'\$match': match});
    pipeline.add({'\$limit': 5});
    pipeline.add({'\$project': project});
    var res = await coll.aggregateToStream(pipeline as List<Map<String, Object>>)
        .map((e) => [e['date'], e['tmin'], e['tmax']])
        .toList();

    //return new Result()..result = res.toString();
    return res as FutureOr<List<List<String?>>>;
  }

}
