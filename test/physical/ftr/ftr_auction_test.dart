library test.physical.ftr.ftr_auction_test;

import 'package:date/date.dart';
import 'package:elec/src/physical/ftr/ftr_auction.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('FTR Auction tests:', () {
    test('parse NYISO TCC auction names', () {
      var auctionNames = [
        'G22',
        'H22-boppG22',
        'J22-boppG22',
        'X21-1Y-R1Fall21',
        'X21-1Y-R2Fall21',
        'X21-1Y-R3Fall21',
        'X21-6M-R4Fall21',
        'X21-6M-R5Fall21',
        'X21-6M-R6Fall21',
        'X21-6M-R7Fall21',
        'X21-6M-R8Fall21',
        'K21-1Y-R8Fall20',
        'K21-2Y-R1Spring21',
        'K21-1Y-R2Spring21',
        'K21-1Y-R3Spring21',
        'K21-1Y-R4Spring21',
        'K21-6M-R5Spring21',
        'K21-6M-R6Spring21',
        'K21-6M-R7Spring21',
        'K21-6M-R8Spring21',
      ];
    });
  });
}

void main() {
  tests();
}
