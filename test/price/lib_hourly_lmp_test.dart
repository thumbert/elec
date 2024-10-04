import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/price/lib_hourly_lmp.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() {
  group('Historical LMP', () {
    test('get ISONE hourly LMPs', () {
      var xs = getHourlyLmpIsone(
          ptids: [4000, 4001],
          market: Market.da,
          component: LmpComponent.lmp,
          term: Term.parse('Nov22', IsoNewEngland.location));

      expect(xs.keys.toSet(), {4000, 4001});
      expect(xs[4000]!.length, 721); // one extra DST hour
    });
    test('get ISONE 5min RT LMPs', () {
      var xs = get5MinRtLmpIsone(
          ptids: [4000],
          component: LmpComponent.lmp,
          reportType: ReportType.finalized,
          term: Term.parse('Jan24', IsoNewEngland.location));
      expect(xs.keys.toSet(), {4000});
      expect(xs[4000]!.length, 8928); 
    });
  });
}

void main() {
  initializeTimeZones();
  tests();
}
