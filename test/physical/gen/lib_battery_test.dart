library test.physical.gen.lib_battery_test;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/physical/gen/battery.dart';
import 'package:elec/src/physical/gen/lib_battery.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Lib battery tests: ', () {
    test('create a battery', () {
      final battery = Battery(
        ecoMaxMw: 100,
        maxLoadMw: 125,
        totalCapacityMWh: 400,
        maxCyclesPerYear: 400,
      );
      // final initialState = State(
      //     interval: Hour.beginning(TZDateTime(IsoNewEngland.location, 2022)),
      //     mode: BatteryMode.offline,
      //     cyclesInCalendarYear: 0);

      // final strategy = PriceInsensitiveDispatch(
      //     chargingHoursRange: (1, 4), dischargingHoursRange: (17, 20));

      // final price = TimeSeries<num>();
      // final states = strategy.dispatch(
      //     battery: battery, initialState: initialState, price: price);


    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
