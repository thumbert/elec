library test.physical.gen.lib_battery_test;

import 'package:dama/basic/count.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/gen/battery/battery.dart';
import 'package:elec/src/physical/gen/battery/battery_optimization.dart';
import 'package:elec/src/physical/gen/battery/battery_price_stats.dart';
import 'package:elec/src/physical/offer_curve.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';
import 'package:elec/src/price/lib_hourly_lmp.dart';
import 'package:table/table_base.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

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

TimeSeries<({BidCurve bids, OfferCurve offers})> getBidsOffers() {
  return TimeSeries.from(
      Term.parse('13Sep24', IsoNewEngland.location).hours(),
      List.generate(
          24,
          (i) => (
                bids: BidCurve.fromIterable([PriceQuantityPair(10, 100)]),
                offers: OfferCurve.fromIterable([PriceQuantityPair(100, 100)])
              )));
}

void tests() {
  group('Best hours to charge/discharge', () {
    var ts = getHourlyLmpIsone(
        ptids: [4000],
        market: Market.da,
        component: LmpComponent.lmp,
        term: Term.parse('Jan22-Dec22', IsoNewEngland.location))[4000]!;
    // var traces = [{
    //   'x': ts.map((e) => e.interval.start.toIso8601String()).toList(),
    //   'y': ts.map((e) => e.value).toList(),
    // }];
    // var layout = <String, dynamic>{
    //   'title': 'Mass Hub',
    //   'width': 1000,
    //   'height': 650,
    //   'yaxis': {
    //     'title': 'Hourly DA LMP price, \$/MWh',
    //   },
    // };
    // Plotly.now(traces, layout, file: File('/home/adrian/Downloads/da_lmp.html'));

    test('best hours in day (non-contiguous)', () {
      var day = Date(2022, 1, 8, location: IsoNewEngland.location).toInterval();
      var xs = ts.window(day).toTimeSeries();
      var res = bestHoursChargeDischarge(xs, 4, endChargingBeforeHour: 15);
      // print(xs);
      // print('Charging:');
      // res.charging.forEach(print);
      // print('Discharging:');
      // res.discharging.forEach(print);
      expect(res.charging.length, 4);
      expect(res.discharging.length, 4);
    });

    test('min/max price blocks for 1Jan22', () {
      // simple case, min block before max, non-overlapping
      var ts1Jan = ts
          .window(Term.parse('1Jan22', IsoNewEngland.location).interval)
          .toTimeSeries();
      var res = minMaxDailyPriceForBlock(ts1Jan, 4);
      expect(res.values.first,
          (maxIndex: 16, maxPrice: 40.0625, minIndex: 3, minPrice: 30.43));

      // max block before min block
      print(res);
    });

    test('min/max price blocks for 4Jan22', () {
      // inverted case, max block before min, non-overlapping
      var ts4Jan = ts
          .window(Term.parse('4Jan22', IsoNewEngland.location).interval)
          .toTimeSeries();
      // print(ts4Jan);
      var res = minMaxDailyPriceForBlock(ts4Jan, 4);
      expect(res.values.first, (
        maxIndex: 16,
        maxPrice: 107.64750000000001,
        minIndex: 12,
        minPrice: 72.57499999999999
      ));
    });

    test('min/max price blocks for Jan22', () {
      var res = minMaxDailyPriceForBlock(ts, 4);
      print(res);
      expect(res[3].value, (
        maxIndex: 16,
        maxPrice: 107.64750000000001,
        minIndex: 12,
        minPrice: 72.57499999999999
      ));
    });

    test('tabulate blocks for Jan22-Feb22', () {
      var xs = ts
          .window(Term.parse('Jan22-Feb22', IsoNewEngland.location).interval)
          .toTimeSeries();
      var res = tabulateBestBlocks(hourlyPrices: xs, n: 4);

      var maxD = count<int>(
          res.expand((e) => List<int>.filled(e['count'], e['maxIndex'])));
      var minD = count<int>(
          res.expand((e) => List<int>.filled(e['count'], e['minIndex'])));
      var tbl = [
        ...maxD.entries.map<Map<String, dynamic>>((e) =>
            {'action': 'discharge', 'hourIndex': e.key, 'count': e.value}),
        ...minD.entries.map<Map<String, dynamic>>(
            (e) => {'action': 'charge', 'hourIndex': e.key, 'count': e.value})
      ];
      tbl.sort((a, b) => -a['count'].compareTo(b['count']));

      ///
      print(Table.from(tbl));
    });
  });

  group('Lib battery tests: ', () {
    final battery = Battery(
      ecoMaxMw: 100,
      efficiencyRating: 0.85,
      totalCapacityMWh: 400,
      maxCyclesPerYear: 365,
      degradationFactor: TimeSeries<num>(),
    );
    final initialState = Empty(cyclesInCalendarYear: 0, cycleNumber: 0);

    test('hours', () {
      expect(battery.hours(), 4);
    });

    test('a battery with no favorable conditions to dispatch', () {
      final opt = BatteryOptimizationSimple(
        battery: battery,
        initialBatteryState: initialState,
        daPrice: getDaPrice(),
        rtPrice: getRtPrice(),
        daBidsOffers: getBidsOffers(),
        rtBidsOffers: getBidsOffers(),
      );
      opt.run();
      final res = opt.dispatchDa;
      expect(res.every((e) => e.value.endState is Empty), true);
    });

    test('Cycle counter resets on new calendar year', () {
      final initialState =
          Unavailable(cyclesInCalendarYear: 365, cycleNumber: 500);
      final term = Term.parse('31Dec22-3Jan23', IsoNewEngland.location);
      var daBidsOffers = makeBidsOffers(
        term: term,
        chargeHours: {1, 2, 3, 4},
        dischargeHours: {17, 18, 19, 20},
        chargingBids: [PriceQuantityPair(800, battery.maxLoadMw)],
        nonChargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        dischargingOffers: [PriceQuantityPair(0, battery.ecoMaxMw)],
        nonDischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
      );
      final opt = BatteryOptimizationSimple(
        battery: battery,
        initialBatteryState: initialState,
        daPrice: TimeSeries.fill(term.hours(), 15),
        rtPrice: TimeSeries.fill(term.hours(), 17),
        daBidsOffers: daBidsOffers,
        rtBidsOffers: daBidsOffers,
      );
      opt.run();
      final res = opt.dispatchDa;
      // opt.dispatchDa.forEach(print);
      expect(
          res
              .observationAt(
                  Hour.beginning(TZDateTime(IsoNewEngland.location, 2023)))
              .value
              .endState is Empty,
          true);
      expect(
          res
              .observationAt(
                  Hour.beginning(TZDateTime(IsoNewEngland.location, 2023)))
              .value
              .endState
              .cyclesInCalendarYear,
          0);
    });

    test('a battery charging/discharging on a fixed schedule, one day', () {
      var bidsOffers = getBidsOffers();
      var values = bidsOffers.values.toList();
      // demand bid the battery at very high prices to make battery charge
      for (var i in [1, 2, 3, 4]) {
        values[i] = (
          bids: BidCurve.fromIterable(
              [PriceQuantityPair(500, battery.maxLoadMw)]),
          offers: values[i].offers
        );
      }
      // offer battery at very low prices to make battery discharge
      for (var i in [17, 18, 19, 20]) {
        values[i] = (
          bids: values[i].bids,
          offers:
              OfferCurve.fromIterable([PriceQuantityPair(0, battery.ecoMaxMw)])
        );
      }
      bidsOffers = TimeSeries.from(bidsOffers.intervals, values);
      // print(bidsOffers);

      final opt = BatteryOptimizationSimple(
        battery: battery,
        initialBatteryState: initialState,
        daPrice: getDaPrice(),
        rtPrice: getRtPrice(),
        daBidsOffers: bidsOffers,
        rtBidsOffers: bidsOffers,
      );
      print(getDaPrice());
      opt.run();

      final dispatchDa = opt.dispatchDa;
      // dispatchDa.forEach(print);
      expect(
          dispatchDa.where((e) => e.value.endState is PartiallyCharged).length,
          6);
      expect(dispatchDa[1].value.endState is PartiallyCharged, true);
      expect(dispatchDa[1].value.endState.batteryLevelMwh, 100);
      expect(dispatchDa[17].value.endState is PartiallyCharged, true);
      expect(dispatchDa[17].value.endState.batteryLevelMwh, 300);

      // calculate PnL
      expect(opt.pnlDa.values.where((e) => e < 0).sum().round(), -12699);
      expect(opt.pnlDa.values.where((e) => e > 0).sum().round(), 21166);
      expect(opt.pnlDa.sum().round(), 8467);

      // get daily stats
      // final dailyStats = opt.cycleStats;
      // print('Daily stats:');
      // for (var e in dailyStats) {
      //   print(e.toJson());
      // }
    });

    test('battery optimization in DAM by ISO, one day', () {
      final opt = BatteryOptimizationIso(
        battery: battery,
        initialBatteryState: initialState,
        daPrice: getDaPrice(),
        endChargingBeforeHour: 15,
      );
      opt.run();
      // final dispatchDa = opt.dispatchDa;
      // dispatchDa.forEach(print);

      // calculate PnL
      expect(opt.pnlDa.values.where((e) => e < 0).sum().round(), -12540);
      expect(opt.pnlDa.values.where((e) => e > 0).sum().round(), 21824);
      expect(opt.pnlDa.sum().round(), 9284);

      // get daily stats
      // final dailyStats = opt.cycleStats;
      // print('Daily stats:');
      // for (var e in dailyStats) {
      //   print(e.toJson());
      // }
    });

    test('battery optimization flex, one day', () {
      var day = Term.parse('8Jul24', IsoNewEngland.location);
      final daPrice = getHourlyLmpIsone(
          ptids: [4000],
          market: Market.da,
          component: LmpComponent.lmp,
          term: day)[4000]!;
      final rtPrice = getHourlyLmpIsone(
          ptids: [4000],
          market: Market.rt,
          component: LmpComponent.lmp,
          term: day)[4000]!;

      final opt = BatteryOptimizationFlex(
        battery: battery,
        initialBatteryState: initialState,
        daPrice: daPrice,
        rtPrice: rtPrice,
        dischargeMultiplier: 1.3,
        chargeDiscount: 0.8,
        endChargingBeforeHour: 15,
      );
      opt.run();
      final dispatchDa = opt.dispatchDa;
      dispatchDa.forEach(print);
      //
      print('RT:');
      final dispatchRt = opt.dispatchRt;
      dispatchRt.forEach(print);

      // calculate PnL
      // expect(opt.pnlDa.values.where((e) => e < 0).sum().round(), -12540);
      // expect(opt.pnlDa.values.where((e) => e > 0).sum().round(), 21824);
      // expect(opt.pnlDa.sum().round(), 9284);

      // get daily stats
      // final dailyStats = opt.cycleStats;
      // print('Daily stats:');
      // for (var e in dailyStats) {
      //   print(e.toJson());
      // }
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();

  // print(getRtPrice());

  // TODO: generalize battery dispatch to work with more than one segment in the
  // bid/offer curves!
}
