library path_test;

import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/iso/iso.dart';
// import 'package:elec/src/ftr/path.dart';
// import 'package:elec/src/ftr/ftr_auction.dart';

//pathTest() async {
//  var source = new NepoolLocation.fromPtid(555);
//  var sink = new NepoolLocation.fromPtid(4002);
//  TZDateTime start = new TZDateTime(Nepool.location, 2015, 1, 1);
//  TZDateTime end = new TZDateTime(Nepool.location, 2015, 5, 1);
//
//
////  var data = await source.getHourlyCongestionPrice(start, end);
////  data.forEach((e) => print(e));
//  Path path = new Path.from(source, sink, Nepool.bucket5x16);
//  var data = await path.getSettlePrice(start, end);
//  data.forEach((e) => print(e));
//
//
//}
//
//main() async {
//  config = new TestConfig();
//  await config.nepool_dam_lmp_hourly.db.open();
//  await initializeTimeZone();
//
//  await pathTest();
//
//  await config.nepool_dam_lmp_hourly.db.close();
//}
