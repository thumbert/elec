library nepool_dam_lmp_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:date/date.dart';

import 'package:elec/elec.dart';
import 'package:elec/src/iso/nepool/nepool_da_lmp.dart';
import 'package:elec/src/base/summary_by_bucket.dart';
import 'package:elec/src/api/nepool_lmp.dart';

setupArchive() async {
  DamArchive arch = new DamArchive();
  await arch.setup();

  await arch.updateDb(new Date(2015,1,1), new Date(2015,3,30));
}

testNepoolDamArchive() async {
  DamArchive arch = new DamArchive();

  await arch.db.open();
  Date end = await arch.lastDayInserted();
  print('Last day inserted is: $end');
  await arch.removeDataForDay(end);
  print('Last day inserted is: ${await arch.lastDayInserted()}');
  await arch.db.close();
}


testNepoolDam() async {
  DaLmp daLmp = new DaLmp();

//  var data = await daLmp.getHourlyCongestionData(4000).toList();
  var data = await daLmp.getHourlyCongestionData(4000, startDate: new Date(2015,2,1)).toList();
  data.forEach((e) => print(e));
}

testMonthlyLmp () async {
  DaLmp daLmp = new DaLmp();

  List ptids = await daLmp.allPtids();
  print(ptids);
  List buckets = [Nepool.bucket5x16, Nepool.bucket2x16H, Nepool.bucket7x8,
    Nepool.bucketOffpeak, Nepool.bucket7x24];

  Future _calcOne(int ptid) async {
    List hourlyData = await daLmp.getHourlyCongestionData(ptid).toList();
    var data = await summaryByBucketMonth(hourlyData, buckets);
    print('done with $ptid');
    return data;
  }

  await Future.forEach(ptids.take(20), (ptid) => _calcOne(ptid));




}


main() async {

  config = new TestConfig();
  await config.open();

  //await setupArchive();

  //await testNepoolDamArchive();

  //await testNepoolDam();

  await testMonthlyLmp();

  await config.close();
}