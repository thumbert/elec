library test.risk_system.locations.curve_id_test;

import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/locations/curve_id.dart';
import 'package:test/test.dart';

void tests() {
  group('CurveId tests:', (){
    test('ISONE MassHub DA LMP', () {
      var id = CurveId.forIsoEnergyPtid(IsoNewEngland(), 4000, Market.da,
          LmpComponent.lmp);
      expect(id.name, 'isone_energy_4000_da_lmp');
    });
    test('ISONE CT DA congestion', (){
      var id = CurveId.forIsoEnergyPtid(IsoNewEngland(), 4004, Market.da,
          LmpComponent.congestion);
      expect(id.name, 'isone_energy_4004_da_congestion');
    });
  });
}

void main() {
  tests();
}