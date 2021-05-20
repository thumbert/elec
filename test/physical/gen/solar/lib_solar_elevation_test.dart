library test.load.solar.lib_solar_test;

import 'package:elec/src/physical/gen/solar/lib_solar_elevation.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';

/// https://www.esrl.noaa.gov/gmd/grad/solcalc/
void tests() {
  group('Solar elevation tests: ', () {
    var location = getLocation('America/New_York');
    test('elevation angle noon', () {
      var dt = TZDateTime(location, 2010, 6, 21, 12);
      expect(solarElevationAngle(40, -105, dt).toStringAsFixed(2), '48.48');
    });
    test('Boston', () {
      var bos = coordinates['BOS']!;
      var dt = TZDateTime(location, 2020, 4, 25, 11);
      var elevation = solarElevationAngle(bos.latitude, bos.longitude, dt);
      expect(elevation.toStringAsFixed(2), '53.68');
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
