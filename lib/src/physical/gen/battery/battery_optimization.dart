library physical.gen.battery.battery_optimization;

import 'dart:math' as math;

import 'package:collection/collection.dart' hide IterableNumberExtension;
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/offer_curve.dart';
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

abstract class BatteryOptimization {
  late final Battery battery;

  late final BatteryState initialBatteryState;

  /// Hourly timeseries of DA prices
  late final TimeSeries<num> daPrice;

  /// Hourly | 5min timeseries of RT prices
  late final TimeSeries<num> rtPrice;

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

  void run();

  List<CycleStats> _calculateCycleStats() {
    var data = dispatchDa
        .merge(daPrice, f: (x, y) => (x!, y!))
        .merge(pnlDa, f: (x, y) => (state: x!.$1, daPrice: x!.$2, daPnl: y!));

    var cycles = groupBy(data, (e) => e.value.state.cycleNumber);
    cycles.remove(cycles.keys.first);
    if (cycles.isEmpty) return <CycleStats>[];

    /// split the data into cycles
    var groups = cycles.values.map((xs) {
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
              (state.batteryLevelMwh - previousState.batteryLevelMwh) /
              battery.efficiencyRating;
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
          value =
              -priceRt * (rtQuantity - daQuantity) / battery.efficiencyRating;
        case DischargingState():
          num daQuantity =
              previousStateDa.batteryLevelMwh - stateDa.batteryLevelMwh;
          num rtQuantity =
              previousStateRt.batteryLevelMwh - stateRt.batteryLevelMwh;
          value = priceRt * (rtQuantity - daQuantity);
        case FullyChargedState() || EmptyState() || Unavailable():
          value = 0;
      }
      out.add(IntervalTuple(interval, value));
    }
    return out;
  }
}

class BatteryOptimizationSimple extends BatteryOptimization {
  /// Optimize a battery given the inputs:
  /// - [battery] models the physical asset,
  /// - [daPrice] hourly timeseries of DA prices,
  /// - [daBidsOffers] hourly bids (when charging) and offers (when discharging)
  ///   for the DA market.
  /// - [rtBidsOffers] hourly bids (when charging) and offers (when discharging)
  ///   for the RT market.
  ///
  /// In this strategy the hours to charge and discharge are predetermined
  /// by the operator.
  ///
  /// All the input timeseries need to have the same domain (no missing hours.)
  ///
  BatteryOptimizationSimple({
    required Battery battery,
    required BatteryState initialBatteryState,
    required TimeSeries<num> daPrice,
    required TimeSeries<num> rtPrice,
    required this.daBidsOffers,
    required this.rtBidsOffers,
  }) {
    this.battery = battery;
    this.initialBatteryState = initialBatteryState;
    this.daPrice = daPrice;
    this.rtPrice = rtPrice;
  }

  /// Hourly timeseries of DA bids and offers
  final TimeSeries<({BidCurve bids, OfferCurve offers})> daBidsOffers;

  /// Hourly timeseries of RT bids and offers
  final TimeSeries<({BidCurve bids, OfferCurve offers})> rtBidsOffers;

  @override
  void run() {
    //
    dispatchDa = _runDispatchSimple(price: daPrice, bidsOffers: daBidsOffers);
    pnlDa = _calculateHourlyPnlDa();
    //
    dispatchRt = _runDispatchSimple(price: rtPrice, bidsOffers: rtBidsOffers);
    pnlRt = _calculateHourlyPnlRt();
    cycleStats = _calculateCycleStats();
  }

  /// Use a greedy algorith for dispatch:
  ///   If an interval is in the money relative to charging/discharging do it
  ///   if the transition matrix allows it.
  ///
  /// The hours to charge and discharge are preset in the [bidsOffers].  No
  /// attempt is made to select the best hours.
  ///
  TimeSeries<BatteryState> _runDispatchSimple({
    required TimeSeries<num> price,
    required TimeSeries<({BidCurve bids, OfferCurve offers})> bidsOffers,
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
      var cyclesInCalendarYear = state.cyclesInCalendarYear;
      final batteryLevelMwh = out.last.value.batteryLevelMwh;

      /// reset the counter of cycles in calendar year
      if (interval.start.year == out.last.interval.start.year + 1) {
        cyclesInCalendarYear = 0;
      }

      switch (state) {
        case ChargingState():
          if (batteryLevelMwh == battery.totalCapacityMWh) {
            state = FullyChargedState(
                batteryLevelMwh: battery.totalCapacityMWh,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            break;
          }
          var newLevel = (priceMkt <= bidPrice)
              ? math.min(
                  batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh)
              : batteryLevelMwh;
          // Note that the level may not change on some intervals when the
          // battery is charging.  It only means that the prices were not
          // favorable and charging has been paused.  Battery is still on it's
          // way to fully charged, before starting to discharge.
          state = ChargingState(
              batteryLevelMwh: newLevel,
              cycleNumber: cycleNumber,
              cyclesInCalendarYear: cyclesInCalendarYear);

        case FullyChargedState():
          if (priceMkt >= offerPrice) {
            // battery is discharging
            var newLevel = math.max(batteryLevelMwh - battery.ecoMaxMw, 0);
            state = DischargingState(
                batteryLevelMwh: newLevel,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          }

        case DischargingState():
          if (batteryLevelMwh == 0) {
            state = EmptyState(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
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
              cyclesInCalendarYear: cyclesInCalendarYear);

        case EmptyState():
          if (cyclesInCalendarYear == battery.maxCyclesPerYear) {
            // battery becomes unavailable
            state = Unavailable(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            break;
          }
          if (priceMkt <= bidPrice) {
            // battery begins a new charging cycle
            cycleNumber += 1;
            cyclesInCalendarYear += 1;
            var newLevel = math.min(
                batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh);
            if (newLevel <= battery.totalCapacityMWh &&
                batteryLevelMwh < battery.totalCapacityMWh) {
              state = ChargingState(
                  batteryLevelMwh: newLevel,
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cyclesInCalendarYear);
            }
          } else {
            // remains empty
            state = EmptyState(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          }

        case Unavailable():
          //
          // Introduce OUTAGES here!
          //
          if (cyclesInCalendarYear < battery.maxCyclesPerYear) {
            state =
                EmptyState(cycleNumber: cycleNumber, cyclesInCalendarYear: 0);
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

class BatteryOptimizationIso extends BatteryOptimization {
  /// This algorithm lets the ISO pick the best set of hours to charge
  /// and discharge in the DAM, and then run to the schedule in RT.
  ///
  BatteryOptimizationIso({
    required Battery battery,
    required BatteryState initialBatteryState,
    required TimeSeries<num> daPrice,
    required this.endChargingBeforeHour,
  }) {
    this.battery = battery;
    this.initialBatteryState = initialBatteryState;
    this.daPrice = daPrice;
  }

  /// In the DAM, let the model pick out the best 4 hours to charge before
  /// this hour.  For example, if [endChargingBeforeHour] = 15, the DAM model
  /// will pick the best 4 hours to charge before 15:00 and best 4 hours to
  /// discharge from 15:00.
  final int endChargingBeforeHour;

  @override
  void run() {
    // DA dispatch, ISO optimizes revenue
    dispatchDa = _runDaDispatch(price: daPrice);
    pnlDa = _calculateHourlyPnlDa();
    // run to the DA schedule in the RT market
    dispatchRt = TimeSeries.fromIterable(dispatchDa);
    pnlRt = _calculateHourlyPnlRt();
    cycleStats = _calculateCycleStats();
  }

  TimeSeries<BatteryState> _runDaDispatch({
    required TimeSeries<num> price,
  }) {
    final out = TimeSeries<BatteryState>.fromIterable([
      IntervalTuple(
          (price.first.interval as Hour).previous, initialBatteryState),
    ]);

    /// group by day
    var groups = groupBy(price, (e) => Date.containing(e.interval.start));
    var days = groups.keys.toList();

    for (var i = 0; i < days.length; i++) {
      var ps = groups[days[i]]!;
      ps.sort((a, b) => a.value.compareTo(b.value));

      final interval = price[i].interval;
      final priceMkt = price[i].value;
      // // FIXME Assumes that bids/offers have only one element
      // final bidPrice = bidsOffers[i].value.bids.first.price;
      // final offerPrice = bidsOffers[i].value.offers.first.price;
      // if (offerPrice <= priceMkt && priceMkt <= bidPrice) {
      //   throw StateError('Inconsistent state for ${price[i].interval}.  '
      //       'Offer price of $offerPrice <= price $priceMkt <= bid price $bidPrice');
      // }

      var state = out.last.value;
      var cycleNumber = state.cycleNumber;
      var cyclesInCalendarYear = state.cyclesInCalendarYear;
      final batteryLevelMwh = out.last.value.batteryLevelMwh;

      /// reset the counter of cycles in calendar year
      if (interval.start.year == out.last.interval.start.year + 1) {
        cyclesInCalendarYear = 0;
      }

      // switch (state) {
      //   case ChargingState():
      //     if (batteryLevelMwh == battery.totalCapacityMWh) {
      //       state = FullyChargedState(
      //           batteryLevelMwh: battery.totalCapacityMWh,
      //           cycleNumber: cycleNumber,
      //           cyclesInCalendarYear: cyclesInCalendarYear);
      //       break;
      //     }
      //     var newLevel = (priceMkt <= bidPrice)
      //         ? math.min(
      //             batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh)
      //         : batteryLevelMwh;
      //     // Note that the level may not change on some intervals when the
      //     // battery is charging.  It only means that the prices were not
      //     // favorable and charging has been paused.  Battery is still on it's
      //     // way to fully charged, before starting to discharge.
      //     state = ChargingState(
      //         batteryLevelMwh: newLevel,
      //         cycleNumber: cycleNumber,
      //         cyclesInCalendarYear: cyclesInCalendarYear);

      //   case FullyChargedState():
      //     if (priceMkt >= offerPrice) {
      //       // battery is discharging
      //       var newLevel = math.max(batteryLevelMwh - battery.ecoMaxMw, 0);
      //       state = DischargingState(
      //           batteryLevelMwh: newLevel,
      //           cycleNumber: cycleNumber,
      //           cyclesInCalendarYear: cyclesInCalendarYear);
      //     }

      //   case DischargingState():
      //     if (batteryLevelMwh == 0) {
      //       state = EmptyState(
      //           cycleNumber: cycleNumber,
      //           cyclesInCalendarYear: cyclesInCalendarYear);
      //       break;
      //     }
      //     var newLevel = (priceMkt >= offerPrice)
      //         ? math.max(batteryLevelMwh - battery.ecoMaxMw, 0)
      //         : batteryLevelMwh;
      //     // Note that the level may not change on some intervals when the
      //     // battery is discharging.  It only means that the prices were not
      //     // favorable and discharging has been paused.  Battery is still on
      //     // it's way to the empty state, before starting a new charging cycle.
      //     state = DischargingState(
      //         batteryLevelMwh: newLevel,
      //         cycleNumber: cycleNumber,
      //         cyclesInCalendarYear: cyclesInCalendarYear);

      //   case EmptyState():
      //     if (cyclesInCalendarYear == battery.maxCyclesPerYear) {
      //       // battery becomes unavailable
      //       state = Unavailable(
      //           cycleNumber: cycleNumber,
      //           cyclesInCalendarYear: cyclesInCalendarYear);
      //       break;
      //     }
      //     if (priceMkt <= bidPrice) {
      //       // battery begins a new charging cycle
      //       cycleNumber += 1;
      //       cyclesInCalendarYear += 1;
      //       var newLevel = math.min(
      //           batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh);
      //       if (newLevel <= battery.totalCapacityMWh &&
      //           batteryLevelMwh < battery.totalCapacityMWh) {
      //         state = ChargingState(
      //             batteryLevelMwh: newLevel,
      //             cycleNumber: cycleNumber,
      //             cyclesInCalendarYear: cyclesInCalendarYear);
      //       }
      //     } else {
      //       // remains empty
      //       state = EmptyState(
      //           cycleNumber: cycleNumber,
      //           cyclesInCalendarYear: cyclesInCalendarYear);
      //     }

      //   case Unavailable():
      //     //
      //     // Introduce OUTAGES here!
      //     //
      //     if (cyclesInCalendarYear < battery.maxCyclesPerYear) {
      //       state =
      //           EmptyState(cycleNumber: cycleNumber, cyclesInCalendarYear: 0);
      //       break;
      //     }
      // }

      // record the current state
      out.add(IntervalTuple(interval, state));
    }

    out.removeAt(0); // remove the spurious initial state
    return out;
  }
}

class BatteryOptimizationFlex2 extends BatteryOptimization {
  /// This algorithm tries to take advantage of price volatility in non-commited
  /// hours.  For example,
  ///  * If P_{RT} > \overline{P}_{DA}^d (1 + f)
  ///
  ///
  /// RT prices are 5min intervals
  ///
  BatteryOptimizationFlex2({
    required Battery battery,
    required BatteryState initialBatteryState,
    required TimeSeries<num> daPrice,
    required TimeSeries<num> rtPrice,
    required this.dischargeMultiplier,
    required this.chargeDiscount,
    required this.endChargingBeforeHour,
  }) {
    this.battery = battery;
    this.initialBatteryState = initialBatteryState;
    this.daPrice = daPrice;
    this.rtPrice = rtPrice;
  }

  /// Battery starts discharging outside of DA schedule if
  /// RT price > [dischargeMultiplier] * average discharge price in the DAM
  final num dischargeMultiplier;

  /// Battery starts charging outside of DA schedule if
  /// RT price < [chargeDiscount] * average charge price in the DAM
  final num chargeDiscount;

  /// In the DAM, let the model pick out the best 4 hours to charge before
  /// this hour.  For example, if [endChargingBeforeHour] = 15, the DAM model
  /// will pick the best 4 hours to charge before 15:00 and best 4 hours to
  /// discharge from 15:00.
  final int endChargingBeforeHour;

  @override
  void run() {
    // DA dispatch is the
    // dispatchDa = _runDaDispatchFlex(price: daPrice, bidsOffers: daBidsOffers);
    // pnlDa = _calculateHourlyPnlDa();
    // //
    // dispatchRt = _runRtDispatchFlex(price: rtPrice, bidsOffers: rtBidsOffers);
    // pnlRt = _calculateHourlyPnlRt();
    // cycleStats = _calculateCycleStats();
  }

  ///
  // TimeSeries<BatteryState> _runDaDispatchFlex({
  //   required TimeSeries<num> price,
  //   required TimeSeries<({BidCurve bids, OfferCurve offers})> bidsOffers,
  // }) {}

  /// Use a more flexible algorithm for dispatch:
  ///   If an interval is in the money relative to charging/discharging do it
  ///   if the transition matrix allows it.
  TimeSeries<BatteryState> _runRtDispatchFlex({
    required TimeSeries<num> price,
    required TimeSeries<({BidCurve bids, OfferCurve offers})> bidsOffers,
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
      var cyclesInCalendarYear = state.cyclesInCalendarYear;
      final batteryLevelMwh = out.last.value.batteryLevelMwh;

      /// reset the counter of cycles in calendar year
      if (interval.start.year == out.last.interval.start.year + 1) {
        cyclesInCalendarYear = 0;
      }

      switch (state) {
        case ChargingState():
          if (batteryLevelMwh == battery.totalCapacityMWh) {
            state = FullyChargedState(
                batteryLevelMwh: battery.totalCapacityMWh,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            break;
          }
          var newLevel = (priceMkt <= bidPrice)
              ? math.min(
                  batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh)
              : batteryLevelMwh;
          // Note that the level may not change on some intervals when the
          // battery is charging.  It only means that the prices were not
          // favorable and charging has been paused.  Battery is still on it's
          // way to fully charged, before starting to discharge.
          state = ChargingState(
              batteryLevelMwh: newLevel,
              cycleNumber: cycleNumber,
              cyclesInCalendarYear: cyclesInCalendarYear);

        case FullyChargedState():
          if (priceMkt >= offerPrice) {
            // battery is discharging
            var newLevel = math.max(batteryLevelMwh - battery.ecoMaxMw, 0);
            state = DischargingState(
                batteryLevelMwh: newLevel,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          }

        case DischargingState():
          if (batteryLevelMwh == 0) {
            state = EmptyState(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
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
              cyclesInCalendarYear: cyclesInCalendarYear);

        case EmptyState():
          if (cyclesInCalendarYear == battery.maxCyclesPerYear) {
            // battery becomes unavailable
            state = Unavailable(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            break;
          }
          if (priceMkt <= bidPrice) {
            // battery begins a new charging cycle
            cycleNumber += 1;
            cyclesInCalendarYear += 1;
            var newLevel = math.min(
                batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh);
            if (newLevel <= battery.totalCapacityMWh &&
                batteryLevelMwh < battery.totalCapacityMWh) {
              state = ChargingState(
                  batteryLevelMwh: newLevel,
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cyclesInCalendarYear);
            }
          } else {
            // remains empty
            state = EmptyState(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          }

        case Unavailable():
          //
          // Introduce OUTAGES here!
          //
          if (cyclesInCalendarYear < battery.maxCyclesPerYear) {
            state =
                EmptyState(cycleNumber: cycleNumber, cyclesInCalendarYear: 0);
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
