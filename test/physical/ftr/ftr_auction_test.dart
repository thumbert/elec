library test.physical.ftr.ftr_auction_test;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/physical/ftr/ftr_auction.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('FTR Auction tests:', () {
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
    test('parse NYISO TCC auction names', () {
      for (var name in auctionNames) {
        var auction = FtrAuction.parse(name, iso: Iso.newYork);
        expect(auction.name, name);
      }
    });
    test('equality annual auctions', () {
      var a1 = FtrAuction.parse('X21-1Y-R1Autumn21', iso: Iso.newYork);
      var a2 = AnnualFtrAuction(
          iso: Iso.newYork,
          startMonth: Month(2021, 11, location: location),
          round: 1);
      expect(a1, a2);
    });
    test('compare auctions', () {
      var xs = auctionNames
          .map((e) => FtrAuction.parse(e, iso: Iso.newYork))
          .toList();
      xs.sort();
      expect(xs.map((e) => e.name).toList(), [
        'K21-2Y-R1Spring21',
        'K21-1Y-R2Spring21',
        'K21-1Y-R3Spring21',
        'K21-1Y-R4Spring21',
        'K21-1Y-R8Autumn20', // I prefer this one to be the first -1Y-
        'K21-6M-R5Spring21',
        'K21-6M-R6Spring21',
        'K21-6M-R7Spring21',
        'K21-6M-R8Spring21',
        'X21-1Y-R1Autumn21',
        'X21-1Y-R2Autumn21',
        'X21-1Y-R3Autumn21',
        'X21-6M-R4Autumn21',
        'X21-6M-R5Autumn21',
        'X21-6M-R6Autumn21',
        'X21-6M-R7Autumn21',
        'X21-6M-R8Autumn21',
        'G22',
        'H22-boppG22',
        'J22-boppG22',
      ]);
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
