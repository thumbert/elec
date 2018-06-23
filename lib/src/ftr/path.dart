library ftr.path;

import 'dart:async';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:elec/src/iso/location.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/ftr/auction.dart';



class Path {
  Location source, sink;
  num quantity;
  Bucket bucket;

  Path();

  /// An FTR path
  Path.from(this.source, this.sink, this.bucket, {this.quantity: 1}) {
    //TODO:  check that the ISO is the same?
  }

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

class Bid extends Path {
  num bidPrice;
  Auction auction;

  Bid();
  Bid.from(this.auction, this.bidPrice, Path path) {
    source = path.source;
    sink = path.sink;
    bucket = path.bucket;
    quantity = path.quantity;
  }

}

class Award extends Path {
  num clearingPrice;
  Auction auction;

  Award();
  Award.from(this.auction, this.clearingPrice, Path path){
    source = path.source;
    sink = path.sink;
    bucket = path.bucket;
    quantity = path.quantity;
  }

}


