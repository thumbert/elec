library physical.gen.battery.battery_optimization;

import 'dart:math' as math;

import 'package:collection/collection.dart' hide IterableNumberExtension;
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:more/collection.dart';
import 'package:table/table.dart';
import 'package:timeseries/timeseries.dart';
import 'battery.dart';

class CycleStats {
  /// A cycle is what happens to the battery between the first charging interval
  /// and the last discharging interval included.
  ///
  /// A cycle can be all within a day, may stretch into another day, or you
  /// can have multiple cycles in a day (rare).
  ///
  CycleStats({
    required this.interval,
    required this.meanChargingDaPrice,
    required this.meanDischargingDaPrice,
    required this.costChargingDa,
    required this.revenueDischargingDa,
  });

  final Interval interval;
  // in $/MWh
  final num meanChargingDaPrice;
  // in $/MWh
  final num meanDischargingDaPrice;
  // Usually a negative value, in $
  final num costChargingDa;
  // Usually a positive value, in $
  final num revenueDischargingDa;

  // in $
  num get pnl => revenueDischargingDa + costChargingDa;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': interval.start.toIso8601String(),
      'end': interval.end.toIso8601String(),
      'meanChargingDaPrice': meanChargingDaPrice,
      'meandDischargingDaPrice': meanDischargingDaPrice,
      'costChargingDa': costChargingDa,
      'revenueDischargingDa': revenueDischargingDa,
      'PnL': pnl,
    };
  }
}

class BatteryOptimization {
  /// Optimize a battery given the inputs:
  /// - [battery] models the physical asset,
  /// - [daPrice] hourly timeseries of DA prices,
  /// - [daBidsOffers] hourly bids (when charging) and offers (when discharging)
  ///   for the DA market.
  ///
  /// All the input timeseries need to have the same domain (no missing hours.)
  BatteryOptimization({
    required this.battery,
    required this.initialBatteryState,
    required this.daPrice,
    required this.rtPrice,
    required this.daBidsOffers,
    required this.rtBidsOffers,
  });

  final Battery battery;

  final BatteryState initialBatteryState;

  /// Hourly timeseries of DA prices
  final TimeSeries<num> daPrice;

  /// Hourly timeseries of RT prices
  final TimeSeries<num> rtPrice;

  /// Hourly timeseries of DA bids and offers
  final TimeSeries<BidsOffers> daBidsOffers;

  /// Hourly timeseries of RT bids and offers
  final TimeSeries<BidsOffers> rtBidsOffers;

  void run() {
    dispatchDa = _runDispatch(price: daPrice, bidsOffers: daBidsOffers);
    pnlDa = _calculateHourlyPnlDa();
    dispatchRt = _runDispatch(price: rtPrice, bidsOffers: rtBidsOffers);
    pnlRt = _calculateHourlyPnlRt();
    cycleStats = _calculateCycleStats();
  }

  /// Hourly timeseries of battery states for all the hours in the window.
  /// Financial dispatch.
  late TimeSeries<BatteryState> dispatchDa;

  /// Hourly timeseries of battery states for all the hours in the window.
  /// Physical dispatch.
  late TimeSeries<BatteryState> dispatchRt;

  /// PnL from the DA schedule, an hourly timeseries.
  late TimeSeries<num> pnlDa;

  /// PnL from the RT schedule, an hourly timeseries.
  late TimeSeries<num> pnlRt;

  /// Summary of battery performance over each charging/discharging cycle.
  late List<CycleStats> cycleStats;

  List<CycleStats> _calculateCycleStats() {
    var data = dispatchDa
        .merge(daPrice, f: (x, y) => (x!, y!))
        .merge(pnlDa, f: (x, y) => (state: x!.$1, daPrice: x!.$2, daPnl: y!));

    /// split the data into cycles
    var groups =
        groupBy(data, (e) => e.value.state.cycleNumber).values.map((xs) {
      var meanChargingDaPrice = xs
          .where((e) => e.value.state is ChargingState)
          .map((e) => e.value.daPrice)
          .mean();
      var meanDischargingDaPrice = xs
          .where((e) => e.value.state is DischargingState)
          .map((e) => e.value.daPrice)
          .mean();
      var costChargingDa = xs
          .where((e) => e.value.state is ChargingState)
          .map((e) => e.value.daPnl)
          .sum();
      var revenueDischargingDa = xs
          .where((e) => e.value.state is DischargingState)
          .map((e) => e.value.daPnl)
          .sum();
      var end = xs
          .firstWhere((e) =>
              e.value.state.batteryLevelMwh == 0 &&
              e.value.state is DischargingState)
          .interval
          .end;
      var interval = Interval(xs.first.interval.start, end);
      return CycleStats(
          interval: interval,
          meanChargingDaPrice: meanChargingDaPrice,
          meanDischargingDaPrice: meanDischargingDaPrice,
          costChargingDa: costChargingDa,
          revenueDischargingDa: revenueDischargingDa);
    }).toList();
    return groups;
  }

  /// PnL from the financial DA market.
  TimeSeries<num> _calculateHourlyPnlDa() {
    var out = TimeSeries<num>();
    var previousState = initialBatteryState;
    for (var i = 0; i < dispatchDa.length; i++) {
      if (daPrice[i].interval != dispatchDa[i].interval) {
        throw StateError('Missaligned prices and battery states, position $i');
      }
      final interval = daPrice[i].interval;
      final priceDa = daPrice[i].value;
      final state = dispatchDa[i].value;
      if (i > 0) previousState = dispatchDa[i - 1].value;
      num value;
      switch (state) {
        case ChargingState():
          value = -priceDa *
              (state.batteryLevelMwh - previousState.batteryLevelMwh);
        case DischargingState():
          value =
              priceDa * (previousState.batteryLevelMwh - state.batteryLevelMwh);
        case FullyChargedState() || EmptyState() || Unavailable():
          value = 0;
      }
      out.add(IntervalTuple(interval, value));
    }
    return out;
  }

  /// Residual PnL from the physical balancing RT market.
  TimeSeries<num> _calculateHourlyPnlRt() {
    var out = TimeSeries<num>();
    var previousStateRt = initialBatteryState;
    var previousStateDa = initialBatteryState;
    for (var i = 0; i < dispatchRt.length; i++) {
      if (rtPrice[i].interval != dispatchRt[i].interval) {
        throw StateError('Missaligned prices and battery states, position $i');
      }
      final interval = rtPrice[i].interval;
      final priceRt = rtPrice[i].value;
      final stateDa = dispatchDa[i].value;
      final stateRt = dispatchRt[i].value;
      if (i > 0) {
        previousStateDa = dispatchDa[i - 1].value;
        previousStateRt = dispatchRt[i - 1].value;
      }
      num value;
      switch (stateRt) {
        case ChargingState():
          num daQuantity =
              stateDa.batteryLevelMwh - previousStateDa.batteryLevelMwh;
          num rtQuantity =
              stateRt.batteryLevelMwh - previousStateRt.batteryLevelMwh;
          value = -priceRt * (rtQuantity - daQuantity);
        case DischargingState():
          num daQuantity =
              stateDa.batteryLevelMwh - previousStateDa.batteryLevelMwh;
          num rtQuantity =
              stateRt.batteryLevelMwh - previousStateRt.batteryLevelMwh;
          value = priceRt * (rtQuantity - daQuantity);
        case FullyChargedState() || EmptyState() || Unavailable():
          value = 0;
      }
      out.add(IntervalTuple(interval, value));
    }
    return out;
  }

  /// Use a greedy algorith for dispatch in the DAM:
  ///   If an interval is in the money relative to charging/discharging do it
  ///   if the transition matrix allows it.
  TimeSeries<BatteryState> _runDispatch({
    required TimeSeries<num> price,
    required TimeSeries<BidsOffers> bidsOffers,
  }) {
    final out = TimeSeries<BatteryState>.fromIterable([
      IntervalTuple(
          (price.first.interval as Hour).previous, initialBatteryState),
    ]);

    for (var i = 0; i < bidsOffers.length; i++) {
      if (price[i].interval != bidsOffers[i].interval) {
        throw StateError(
            'Missaligned DA prices and bids/offers, ${price[i].interval}');
      }
      final interval = price[i].interval;
      final priceMkt = price[i].value;
      // FIXME Assumes that bids/offers have only one element
      final bidPrice = bidsOffers[i].value.bids.first.price;
      final offerPrice = bidsOffers[i].value.offers.first.price;
      if (offerPrice <= priceMkt && priceMkt <= bidPrice) {
        throw StateError('Inconsistent state for ${price[i].interval}.  '
            'Offer price of $offerPrice <= price $priceMkt <= bid price $bidPrice');
      }

      var state = out.last.value;
      var cycleNumber = state.cycleNumber;
      var cycles = state.cyclesInCalendarYear;
      final batteryLevelMwh = out.last.value.batteryLevelMwh;

      switch (state) {
        case ChargingState():
          if (batteryLevelMwh == battery.totalCapacityMWh) {
            state = FullyChargedState(
                batteryLevelMwh: battery.totalCapacityMWh,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cycles);
            break;
          }
          var newLevel = (priceMkt <= bidPrice)
              ? math.min(
                  batteryLevelMwh + battery.maxLoadMw, battery.totalCapacityMWh)
              : batteryLevelMwh;
          // Note that the level may not change on some intervals when the
          // battery is charging.  It only means that the prices were not
          // favorable and charging has been paused.  Battery is still on it's
          // way to fully charged, before starting to discharge.
          state = ChargingState(
              batteryLevelMwh: newLevel,
              cycleNumber: cycleNumber,
              cyclesInCalendarYear: cycles);

        case FullyChargedState():
          if (priceMkt >= offerPrice) {
            // battery is discharging
            var newLevel = math.max(batteryLevelMwh - battery.ecoMaxMw, 0);
            state = DischargingState(
                batteryLevelMwh: newLevel,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cycles);
          }

        case DischargingState():
          if (batteryLevelMwh == 0) {
            state = EmptyState(
                cycleNumber: cycleNumber, cyclesInCalendarYear: cycles);
            break;
          }
          var newLevel = (priceMkt >= offerPrice)
              ? math.max(batteryLevelMwh - battery.ecoMaxMw, 0)
              : batteryLevelMwh;
          // Note that the level may not change on some intervals when the
          // battery is discharging.  It only means that the prices were not
          // favorable and discharging has been paused.  Battery is still on
          // it's way to the empty state, before starting a new charging cycle.
          state = DischargingState(
              batteryLevelMwh: newLevel,
              cycleNumber: cycleNumber,
              cyclesInCalendarYear: cycles);

        case EmptyState():
          if (cycles > battery.maxCyclesPerYear) {
            // battery becomes unavailable
            state = Unavailable(
                cycleNumber: cycleNumber, cyclesInCalendarYear: cycles);
            break;
          }
          // Introduce OUTAGES here!
          if (priceMkt <= bidPrice) {
            // battery begins a new charging cycle
            cycleNumber += 1;
            cycles += 1;
            var newLevel = math.min(
                batteryLevelMwh + battery.maxLoadMw, battery.totalCapacityMWh);
            if (newLevel <= battery.totalCapacityMWh &&
                batteryLevelMwh < battery.totalCapacityMWh) {
              state = ChargingState(
                  batteryLevelMwh: newLevel,
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cycles);
            }
          }

        case Unavailable():
          if (interval.start.year == out.last.interval.start.year + 1) {
            // reset cycles to 0 on new year and move to empty
            out.add(IntervalTuple(interval,
                EmptyState(cycleNumber: cycleNumber, cyclesInCalendarYear: 0)));
            break;
          }
      }

      // record the current state
      out.add(IntervalTuple(interval, state));
    }

    out.removeAt(0); // remove the spurious initial state
    return out;
  }
}

/// For each day of the hourly timeseries [ts] calculate the best blocks
/// of [n] continuous hours to charge and discharge the battery.
///
/// When selecting the blocks with the lowest/highest price, make sure that
/// the blocks are not overlapping and that the min price block (charging)
/// comes before the max price block (discharging)
///
/// [n] is the number of consecutive hours
/// [minIndex] is the index of the hours when prices are the lowest
/// [maxIndex] is the index of the hours when prices are the highest
///
TimeSeries<({int minIndex, num minPrice, int maxIndex, num maxPrice})>
    minMaxDailyPriceForBlock(TimeSeries<num> ts, int n) {
  var dailyTs = ts.groupByIndex((e) => Date.containing(e.start));
  return TimeSeries<
      ({
        int minIndex,
        num minPrice,
        int maxIndex,
        num maxPrice
      })>.fromIterable(dailyTs.map((obs) {
    var chunks = obs.value
        .window(n)
        .mapIndexed((i, es) => (index: i, price: es.mean()))
        .toList();
    // check all possible pairs of charging/discharging blocks and
    // keep the one with the largest spread
    num maxDiff = -999.99;
    var iMinBest = -1;
    var iMaxBest = -1;
    for (var iMin = 0; iMin < (chunks.length - n); iMin++) {
      for (var iMax = iMin + n - 1; iMax < chunks.length; iMax++) {
        var diff = chunks[iMax].price - chunks[iMin].price;
        if (diff > maxDiff) {
          maxDiff = diff;
          iMinBest = chunks[iMin].index;
          iMaxBest = chunks[iMax].index;
        }
      }
    }
    return IntervalTuple<
        ({
          int minIndex,
          num minPrice,
          int maxIndex,
          num maxPrice
        })>(obs.interval, (
      minIndex: chunks[iMinBest].index,
      minPrice: chunks[iMinBest].price,
      maxIndex: chunks[iMaxBest].index,
      maxPrice: chunks[iMaxBest].price
    ));
  }));
}

class BestBlocks {
  BestBlocks(
      {required this.term,
      required this.chargeStartIndex,
      required this.dischargeStartIndex,
      required this.count,
      required this.averageSpread});

  /// Term for the results
  final Term term;

  /// Index of hour of the day when charging should start.
  /// Note that this is not equal with the hour of the day in
  /// DST days.
  final int chargeStartIndex;

  /// Index of hour of the day when discharging should start
  /// Note that this is not equal with the hour of the day in
  /// DST days.
  final int dischargeStartIndex;

  /// Number of days in the term with these starting hours for
  /// the charging/discharging block.
  final int count;

  /// The average spread for the days in the term with these
  /// starting hours for the charging/discharging block.
  /// Spread for one day is the average price during discharge
  /// hours minus the average price during charging hours,
  /// in $/MWh
  final num averageSpread;
}

List<Map<String,dynamic>> tabulateBestBlocks(
    {required TimeSeries<num> hourlyPrices, required int n}) {
  var dailyBlocks = minMaxDailyPriceForBlock(hourlyPrices, n);

  var nest = Nest()
    ..key((e) => e.minIndex)
    ..key((e) => e.maxIndex)
    ..rollup((List es) => {
          'count': es.length,
          'averageSpread': mean(es.map((e) => e.maxPrice - e.minPrice))
        });
  var res = nest.map(dailyBlocks.values.toList());
  var aux = flattenMap(res, ['minIndex','maxIndex'])!;

  // var out = <Map<String,dynamic>>[];
  // for (var e in aux) {
  //   out.add({'minIndex': aux['minMax']})
  // }
  // print(aux);


  return aux;
}
