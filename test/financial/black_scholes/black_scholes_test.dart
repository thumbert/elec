import 'package:elec/src/financial/black_scholes/black_scholes.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:test/test.dart';

void tests() {
  group('Black-Scholes model tests: ', () {
    // test('calculate daily vol', () {
    //   var timeToExpiration =
    //       (Date(2021, 1, 1).value - Date(2020, 11, 20).value) / 365;
    //   var mVol = 0.9795221;
    //   var cVol = 2.60;
    //   var dVol = dailyVolatility(mVol, cVol, timeToExpiration);
    //   print(dVol);
    //   expect(dVol.toStringAsFixed(4), '1.5767');
    // });
    test('futures option', () {
      var c100 = BlackScholes(
          type: CallPut.call,
          strike: 100,
          expirationDate: Date.utc(2021, 1, 15),
          underlyingPrice: 46.0,
          asOfDate: Date.utc(2020, 11, 19),
          volatility: 1.6231,
          riskFreeRate: 0);
      expect(c100.value() > 1, true);
    });
    test('Call', () {
      var c1 = BlackScholes(
          type: CallPut.call,
          strike: 100,
          expirationDate: Date.utc(2015, 1, 31),
          underlyingPrice: 100,
          asOfDate: Date.utc(2015, 1, 1),
          volatility: 0.25,
          riskFreeRate: 0.03);
      expect(c1.value().toStringAsFixed(4), '2.9790');
      expect(c1.delta().toStringAsFixed(4), '0.5280');
      expect(c1.gamma().toStringAsFixed(4), '0.0555');
      expect(c1.vega().toStringAsFixed(4), '0.1141');
      expect(c1.theta().toStringAsFixed(4), '-0.0516');
      expect(c1.rho().toStringAsFixed(4), '0.0004');
      expect(c1.impliedVolatility(2.978962).toStringAsFixed(4), '0.2500');
    });
    test('Put theta, r=0', () {
      var c1 = BlackScholes(
          type: CallPut.put,
          strike: 100,
          expirationDate: Date.utc(2015, 1, 31),
          underlyingPrice: 100,
          asOfDate: Date.utc(2015, 1, 1),
          volatility: 0.25,
          riskFreeRate: 0.0);
      expect(c1.theta().toStringAsFixed(4), '-0.0476');
    });

    test('Put', () {
      var p1 = BlackScholes(
          type: CallPut.put,
          strike: 100,
          expirationDate: Date.utc(2015, 1, 31),
          underlyingPrice: 100,
          asOfDate: Date.utc(2015, 1, 1),
          volatility: 0.25,
          riskFreeRate: 0.03);
      expect(p1.value().toStringAsFixed(4), '2.7329');
      expect(p1.delta().toStringAsFixed(4), '-0.4720');
      expect(p1.gamma().toStringAsFixed(4), '0.0555');
      expect(p1.vega().toStringAsFixed(4), '0.1141');
      expect(p1.theta().toStringAsFixed(4), '-0.0434');
      expect((p1.rho() * 10000).toStringAsFixed(3), '-4.101');
      expect(p1.impliedVolatility(2.7329).toStringAsFixed(4), '0.2500');
    });
    test('An itm Call close to expiration has delta ~ 1', () {
      var c1 = BlackScholes(
          type: CallPut.call,
          strike: 100,
          expirationDate: Date.utc(2015, 1, 31),
          underlyingPrice: 105,
          asOfDate: Date.utc(2015, 1, 28),
          volatility: 0.25,
          riskFreeRate: 0.03);
      expect(c1.delta().toStringAsFixed(2), '0.99');
    });
    test('An itm Put close to expiration has delta ~ -1', () {
      var p1 = BlackScholes(
          type: CallPut.put,
          strike: 100,
          expirationDate: Date.utc(2015, 1, 31),
          underlyingPrice: 95,
          asOfDate: Date.utc(2015, 1, 28),
          volatility: 0.25,
          riskFreeRate: 0.03);
      expect(p1.delta().toStringAsFixed(2), '-0.99');
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
