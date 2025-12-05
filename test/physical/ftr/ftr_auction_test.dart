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
      'K21-6M-R5Spring21',
      'K21-6M-R6Spring21',
      'K21-1Y-R4Spring21',
      'K21-1Y-R3Spring21',
      'K21-6M-R7Spring21',
      'K21-6M-R8Spring21',
    ];
    test('parse NYISO TCC auction names', () {
      for (var name in auctionNames) {
        var auction = FtrAuction.parse(name, iso: Iso.newYork);
        expect(auction.name, name);
      }
    });
    test('parse ISONE FTR auction names', () {
      var auctionNames = [
        'F06-1Y',
        'F20-1Y-R2',
        'G22',
        'J22-boppF22',
      ];
      for (var name in auctionNames) {
        var auction = FtrAuction.parse(name, iso: Iso.newEngland);
        expect(auction.name, name);
      }
    });
    test('monthly auction Z21', () {
      var auction = FtrAuction.parse('Z21', iso: Iso.newYork);
      expect(auction.monthCount, 1);
      expect(auction.start, Date(2021, 12, 1, location: location));
      expect(auction.end, Date(2021, 12, 31, location: location));
    });
    test('6 months auction K21-6M-R5Spring21', () {
      var auction = FtrAuction.parse('K21-6M-R5Spring21', iso: Iso.newYork);
      expect(auction.monthCount, 6);
      expect(auction.start, Date(2021, 5, 1, location: location));
      expect(auction.end, Date(2021, 10, 31, location: location));
      expect(auction is SixMonthFtrAuction, true);
    });
    test('1Y auction K21-6M-R4Spring21', () {
      var auction = FtrAuction.parse('K21-1Y-R4Spring21', iso: Iso.newYork);
      expect(auction.monthCount, 12);
      expect(auction.start, Date(2021, 5, 1, location: location));
      expect(auction.end, Date(2022, 4, 30, location: location));
    });
    test('2Y auction K21-2Y-R1Spring21', () {
      var auction = FtrAuction.parse('K21-2Y-R1Spring21', iso: Iso.newYork);
      expect(auction.monthCount, 24);
      expect(auction.start, Date(2021, 5, 1, location: location));
      expect(auction.end, Date(2023, 4, 30, location: location));
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
    test('compare bopp auctions', () {
      var xs = [
        'J22-boppF22',
        'J22-boppX21',
        'J22-boppH22',
        'J22-boppG22',
        'H22-boppZ21',
        'J22-boppZ21',
      ].map((e) => FtrAuction.parse(e, iso: Iso.newYork)).toList();
      xs.sort();
      expect(xs.map((e) => e.name).toList(), [
        'H22-boppZ21',
        'J22-boppX21',
        'J22-boppZ21',
        'J22-boppF22',
        'J22-boppG22',
        'J22-boppH22',
      ]);
    });
    test('compare monthly and bopp auctions', () {
      var xs = [
        'F22',
        'J22-boppH22',
        'J22',
        'X21',
        'H22-boppZ21',
        'J22-boppZ21',
      ].map((e) => FtrAuction.parse(e, iso: Iso.newYork)).toList();
      xs.sort();
      expect(xs.map((e) => e.name).toList(), [
        'X21',
        'F22',
        'H22-boppZ21',
        'J22-boppZ21',
        'J22-boppH22',
        'J22',
      ]);
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
