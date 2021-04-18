library test.risk_system.transactions.swaps.hourly_energy_swap;

import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/locations/electricity_index.dart';
import 'package:test/test.dart';

void tests() {
  group('Hourly energy swaps', () {
    test('One month, fixed quantity', () {
      var hubDa = ElectricityIndex(IsoNewEngland(), 4000, Market.da,
          LmpComponent.lmp);
      //var swap = HourlyEnergySwap(hubDa, )
    });
  });
}

void main() async {

}