import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';

void tests() {
  var tzLocation = getLocation('America/New_York');
  group('Risk system: Energy futures', () {
    test('Jan19 Nepool MH DA futures', () {
      var tradeDate = Date.utc(2018, 12, 10);
      var month = Month(2019, 1, location: tzLocation);
      var fut = EnergyFutures(tradeDate, month, BuySell.buy, 10,
          EnergyHub.massHubDa, IsoNewEngland.bucket5x16, 81.03);
      fut.toMap().forEach((k,v) => print('$k: $v'));
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
