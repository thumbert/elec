library test.risk_system.data_provider.data_provider_test;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/data_provider/data_provider.dart';
import 'package:elec/src/risk_system/locations/curve_id.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() async {
  group('Data provider tests:', () {
    var provider = DataProvider();
    test('get mh 5x16 as of 5/29/2020', () async {
      var curveId = CurveId.forIsoEnergyPtid(
          Iso.newEngland, 4000, Market.da, LmpComponent.lmp);
      var mh5x16 = await provider.getForwardCurveForBucket(
          curveId, IsoNewEngland.bucket5x16, Date(2020, 5, 29));
      expect(
          mh5x16.domain,
          Term.parse('Jun20-Dec21', Iso.newEngland.preferredTimeZoneLocation)
              .interval);
    });
  });
}

void main() async {
  initializeTimeZones();
  await tests();
}
