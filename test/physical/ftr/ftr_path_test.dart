library path_test;

import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:elec_server/client/binding_constraints.dart';
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
    test('get cp vs. sp table for a path that doesn\'t exist', () async {
      var path = FtrPath(
          sourcePtid: 23518,
          sinkPtid: 61762,
          bucket: Bucket.atc,
          iso: Iso.newYork,
          rootUrl: rootUrl);
      var data = await path.makeTableCpSp(
          fromDate: Date(2020, 12, 14, location: NewYorkIso.location));
      expect(data.isEmpty, true);
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
    test('get relevant constraints ISONE', () async {
      var path = FtrPath(
          sourcePtid: 4000,
          sinkPtid: 4006,
          bucket: Bucket.b5x16,
          iso: Iso.newEngland);
      var term = Term.parse('1Aug21-31Dec21', location);
      var client = BindingConstraints(http.Client(),
          iso: Iso.newEngland, rootUrl: rootUrl);

      var bc = await client.getDaBindingConstraints(term.interval);
      var effects =
          await path.bindingConstraintEffect(term, bindingConstraints: bc);
      effects.sort(
          (a, b) => -a['Cumulative Spread'].compareTo(b['Cumulative Spread']));
      expect(effects.first.keys.toSet(), {
        'name',
        'hours',
        'Mean Spread',
        'Cumulative Spread',
      });
      expect(effects.length, 10);
    });
    test('get relevant constraints NYISO', () async {
      var path = FtrPath(
          sourcePtid: 23598, // Fitz
          sinkPtid: 61754, // C
          bucket: Bucket.b5x16,
          iso: Iso.newYork);
      var term = Term.parse('1Jan19-31Dec19', location);
      var client =
          BindingConstraints(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);

      var bc = await client.getDaBindingConstraints(term.interval);
      var effects =
          await path.bindingConstraintEffect(term, bindingConstraints: bc);
      // print(relevantConstraints);
      effects.sort(
          (a, b) => -a['Cumulative Spread'].compareTo(b['Cumulative Spread']));
      expect(effects.length, 16);
    });
    test('get relevant constraints NYISO, short term', () async {
      var path = FtrPath(
          sourcePtid: 61752, // A
          sinkPtid: 61758, // G
          bucket: Bucket.atc,
          iso: Iso.newYork);
      var term = Term.parse('1Nov20-27Feb22', location);
      var client =
          BindingConstraints(http.Client(), iso: Iso.newYork, rootUrl: rootUrl);

      var bc = await client.getDaBindingConstraints(term.interval);
      var effects =
          await path.bindingConstraintEffect(term, bindingConstraints: bc);
      // print(relevantConstraints);
      effects.sort((a, b) => -(a['Cumulative Spread'].abs())
          .compareTo(b['Cumulative Spread'].abs()));
      expect(effects.length, 65);
      expect(effects.first['name'], 'CENTRAL EAST - VC');
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  var rootUrl = 'http://localhost:8080';
  await tests(rootUrl);
}
