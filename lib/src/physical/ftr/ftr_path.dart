library physical.ftr.ftr_path;

import 'dart:async';
import 'package:date/date.dart';
// import 'package:elec_server/api/isoexpress/api_isone_dalmp.dart';
import 'package:elec_server/client/dalmp.dart';
import 'package:http/http.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:elec/src/iso/location.dart';
import 'ftr_auction.dart';

class FtrPath {
  final int source, sink;
  final num mw;
  final Bucket bucket;
  final Iso iso;

  late final DaLmp _daLmpClient;

  /// Cache (iso,ptid) -> <Bucket,TimeSeries<num>>{}
  TimeSeries<num>? _settlePrices;

  /// An FTR path
  FtrPath(
      {required this.source,
      required this.sink,
      required this.bucket,
      this.mw = 1,
      required this.iso,
      String rootUrl = 'http://127.0.0.1:8080',
      Client? client}) {
    client ??= Client();
    _daLmpClient = DaLmp(client, rootUrl: rootUrl, iso: iso);
  }

  // /// Get all auction cleared prices from the database
  // Future<Map<FtrAuction, num>> clearedPrices() async {}
  //
  // /// Get all da congestion settle prices from the database
  // Future<Map<FtrAuction, num>> settlePriceForAuction(FtrAuction auction) async {
  //   if (_settlePrices == null) {
  //     _settlePrices = _daLmpClient.getDailyLmpBucket(ptid, component, bucket, start, end)
  //   }
  // }

  /// get the hourly settle price for this path
//  Future<List<Map<Hour, num>>> getSettlePrice(
//      tz.TZDateTime start, tz.TZDateTime end) async {
//
//    var sourcePrices = source.getHourlyCongestionPrice(start, end);
//    var sinkPrices = sink.getHourlyCongestionPrice(start, end);
//    List<List> data = await Future.wait([sourcePrices, sinkPrices]);
//    if (data[0].length != data[1].length)
//      throw 'Sink and source data have different lengths.';
//
//    List res = [];
//    for (int i=0; i<data[1].length; i++) {
//      Hour hour = data[1][i]['hour'];
//      if (data[0][i]['hour'] != hour)
//        throw 'Misaligned data, results will be wrong';
//      if (bucket.containsHour(hour)) {
//        res.add({
//          'hour': hour,
//          'value': data[1][i]['congestion'] - data[0][i]['congestion']
//        });
//      }
//    }
//
//    return res;
//  }

}
