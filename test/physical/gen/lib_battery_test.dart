library test.physical.gen.lib_battery_test;

import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/gen/battery.dart';
import 'package:elec/src/physical/offer_curve.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';

TimeSeries<num> getDaPrice() {
  return TimeSeries.from(
      Term.parse('13Sep24', IsoNewEngland.location).hours(), [
    31.93,
    28.94,
    27.09,
    25.84,
    26.07,
    29.1,
    33.98,
    31.95,
    29.06,
    27.59,
    30.22,
    31.66,
    33.01,
    36.42,
    37.61,
    40.21,
    52.01,
    62.12,
    53.3,
    50.81,
    45.43,
    37.81,
    34.2,
    30.95,
  ]);
}

TimeSeries<num> getRtPrice() {
  return TimeSeries.from(
      Term.parse('13Sep24', IsoNewEngland.location).hours(), [
    27.96,
    24.5,
    25.78,
    24.59,
    24.9,
    26.88,
    25.48,
    27.95,
    29.26,
    25.5,
    26.01,
    26.73,
    25.22,
    25.57,
    29.14,
    43.02,
    38.2,
    45.2,
    39.99,
    40.58,
    39.94,
    40.87,
    49.64,
    40.68,
  ]);
}

TimeSeries<BidsOffers> getBidsOffers() {
  return TimeSeries.from(
      Term.parse('13Sep24', IsoNewEngland.location).hours(),
      List.generate(
          24,
          (i) => BidsOffers(
              bids: BidCurve.fromIterable([PriceQuantityPair(10, 100)]),
              offers: OfferCurve.fromIterable([PriceQuantityPair(100, 100)]))));
}

void tests() {
  group('Lib battery tests: ', () {
    final battery = Battery(
      ecoMaxMw: 100,
      maxLoadMw: 125,
      totalCapacityMWh: 400,
      maxCyclesPerYear: 400,
    );
    // print(getBidsOffers());

    final initialState = EmptyState(cyclesInCalendarYear: 0);

    test('a battery with no favorable conditions to dispatch', () {
      final opt = BatteryOptimization(
          battery: battery,
          daPrice: getDaPrice(),
          rtPrice: getRtPrice(),
          bidsOffers: getBidsOffers());
      final res = opt.dispatchDa(initialState: initialState);
      expect(res.every((e) => e.value is EmptyState), true);
    });

    test('a battery charging/discharging on a fixed schedule, one day', () {
      var bidsOffers = getBidsOffers();
      var values = bidsOffers.values.toList();
      // demand bid the battery at very high prices to make battery charge
      for (var i in [1, 2, 3, 4]) {
        values[i] = BidsOffers(
            bids: BidCurve.fromIterable(
                [PriceQuantityPair(500, battery.maxLoadMw)]),
            offers: values[i].offers);
      }
      // offer battery at very low prices to make battery discharge
      for (var i in [17, 18, 19, 20]) {
        values[i] = BidsOffers(
            bids: values[i].bids,
            offers: OfferCurve.fromIterable(
                [PriceQuantityPair(0, battery.ecoMaxMw)]));
      }
      bidsOffers = TimeSeries.from(bidsOffers.intervals, values);
      // print(bidsOffers);

      final opt = BatteryOptimization(
          battery: battery,
          daPrice: getDaPrice(),
          rtPrice: getRtPrice(),
          bidsOffers: bidsOffers);
      final dispatchDa = opt.dispatchDa(initialState: initialState);
      dispatchDa.forEach(print);
      expect(dispatchDa.where((e) => e.value is ChargingState).length, 4);
      expect(dispatchDa.where((e) => e.value is DischargingState).length, 4);
      expect(dispatchDa[1].value is ChargingState, true);
      expect(dispatchDa[1].value.batteryLevelMwh, 125);
      expect(dispatchDa[17].value is DischargingState, true);
      expect(dispatchDa[17].value.batteryLevelMwh, 300);

      // calcualte PnL
      final pnl = opt.calculatePnlDa(dispatchDa, initialState);
      print('PnL:');
      print(pnl);
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();

  // TODO: generalize battery dispatch to work with more than one segment in the
  // bid/offer curves!
}
