
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';

tests() {
  var location = getLocation('US/Eastern');
  group('Risk system: Energy futures', () {
    test('Jan19 Nepool MH DA futures', () {
      var month = Month(2019, 1, location: location);
      //var fut = EnergyFutures()
    });
  });
}

main() async {
  await initializeTimeZone();
  tests();
}