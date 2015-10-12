library iso.location;

import 'dart:async';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/ftr/auction.dart';


abstract class Location {
  int ptid;
  String name;
  Iso iso;
  Future<List<Map<Hour, num>>> getHourlyCongestionPrice(
      TZDateTime start, TZDateTime end);

  factory Location() {

  }

}

class NepoolLocation implements Location {
  int ptid;
  String name;
  Iso iso = new Nepool();

  NepoolLocation.fromPtid(this.ptid);
  NepoolLocation.fromName(this.name);

  /// Return the hourly congestion prices for this location.
  Future<List<Map<Hour, num>>> getHourlyCongestionPrice(
      TZDateTime start, TZDateTime end) async {
    DbCollection coll = config.nepool_dam_lmp_hourly.coll;
    SelectorBuilder sb = where;
    sb.eq('ptid', ptid);
    sb.gte('hourBeginning', start);
    sb.lt('hourBeginning', end);

    return await coll
    .find(sb.excludeFields(['_id', 'ptid']).sortBy('hourBeginning'))
    .map((Map row) => {
      'hour': new Hour.beginning(
          new TZDateTime.from(row['hourBeginning'], Nepool.location)),
      'congestion': row['Lmp_Cong_Loss'][1]
    })
    .toList();
  }
}
