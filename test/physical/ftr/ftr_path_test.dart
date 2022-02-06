library path_test;

import 'package:date/date.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/physical/ftr/ftr_auction.dart';
import 'package:elec/src/physical/ftr/ftr_path.dart';

Future<void> tests(String rootUrl) async {
  group('FTR path tests:', () {
    final location = getLocation('America/New_York');
    final auctionNames = [
      'G22',
      'H22-boppG22',
      'J22-boppG22',
      'X21-1Y-R1Autumn21',
      'X21-1Y-R2Autumn21',
      'X21-1Y-R3Autumn21',
      'X21-6M-R4Autumn21',
      'X21-6M-R5Autumn21',
      'X21-6M-R6Autumn21',
      'X21-6M-R7Autumn21',
      'X21-6M-R8Autumn21',
      'K21-1Y-R8Autumn20',
      'K21-2Y-R1Spring21',
      'K21-1Y-R2Spring21',
      'K21-1Y-R3Spring21',
      'K21-1Y-R4Spring21',
      'K21-6M-R5Spring21',
      'K21-6M-R6Spring21',
      'K21-6M-R7Spring21',
      'K21-6M-R8Spring21',
    ];
    var path = FtrPath(
        sourcePtid: 61752,
        sinkPtid: 61758,
        bucket: Bucket.atc,
        iso: Iso.newYork,
        rootUrl: rootUrl);
    test('get daily settled prices', () async {
      var sp = await path.getDailySettlePrices();
      expect(sp.length > 365, true);
    });
    test('get settle price for one auction', () async {
      var auction = FtrAuction.parse('F21', iso: Iso.newYork);
      var sp = await path.getSettlePriceForAuction(auction);
      expect(sp, 8.631370967741935);
    });
    test('get clearing prices for the path', () async {
      var cp = await path.getClearingPrices();
      expect(cp[FtrAuction.parse('F21', iso: Iso.newYork)], 7.768346774193549);
      expect(cp[FtrAuction.parse('X21-1Y-R1Autumn21', iso: Iso.newYork)],
          11.499999999999998);
    });
    test('get cp vs. sp table', () async {
      var data = await path.makeTableCpSp(
          fromDate: Date(2020, 12, 14, location: NewYorkIso.location));
      var f21 = data.firstWhere(
          (e) => e['auction'] == FtrAuction.parse('F21', iso: Iso.newYork));
      expect(f21, {
        'auction': FtrAuction.parse('F21', iso: Iso.newYork),
        'clearingPrice': 7.768346774193549,
        'settlePrice': 8.631370967741935,
      });
    });
    test('toString() for the path', () {
      expect(path.toString(), 'NYISO 61752 -> 61758');
      var path1 = FtrPath(
          sourcePtid: 4000,
          sinkPtid: 4008,
          bucket: Bucket.b5x16,
          iso: Iso.newEngland);
      expect(path1.toString(), 'ISONE 4000 -> 4008 5x16');
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  var rootUrl = 'http://localhost:8080';
  await tests(rootUrl);
}
