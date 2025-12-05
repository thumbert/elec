import 'dart:math' as math;

import 'package:collection/collection.dart' hide IterableNumberExtension;
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/gen/battery/battery_price_stats.dart';
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
  ///
  /// * [endState] is the battery state at the end of the interval.
  /// * [action] is what the battery did during the interval.
  ///
  late TimeSeries<({BatteryState endState, Action action})> dispatchDa;

  /// Hourly timeseries of battery states for all the hours in the window.
  /// Physical dispatch.
  ///
  /// * [endState] is the battery state at the end of the interval.
  /// * [action] is what the battery did during the interval.
  ///
  late TimeSeries<({BatteryState endState, Action action})> dispatchRt;

  /// PnL from the DA schedule, an hourly timeseries.
  late TimeSeries<num> pnlDa;

  /// PnL from the RT schedule, an hourly timeseries.
  late TimeSeries<num> pnlRt;

  /// Summary of battery performance over each charging/discharging cycle.
  late List<CycleStats> cycleStats;

  void run();

  List<CycleStats> _calculateDaCycleStats() {
    var data = dispatchDa
        .merge(daPrice, f: (x, y) => (x!, y!))
        .merge(pnlDa, f: (x, y) => (state: x!.$1, daPrice: x.$2, daPnl: y!));

    var cycles = groupBy(data, (e) => e.value.state.endState.cycleNumber);
    cycles.remove(cycles.keys.first);
    if (cycles.isEmpty) return <CycleStats>[];

    /// split the data into cycles
    var groups = cycles.values.map((xs) {
      var meanChargingDaPrice = xs
          .where((e) => e.value.state.action == Action.charge)
          .map((e) => e.value.daPrice)
          .mean();
      var meanDischargingDaPrice = xs
          .where((e) => e.value.state.action == Action.discharge)
          .map((e) => e.value.daPrice)
          .mean();
      var costChargingDa = xs
          .where((e) => e.value.state.action == Action.charge)
          .map((e) => e.value.daPnl)
          .sum();
      var revenueDischargingDa = xs
          .where((e) => e.value.state.action == Action.discharge)
          .map((e) => e.value.daPnl)
          .sum();
      var end = xs
          .firstWhere((e) =>
              e.value.state.endState.batteryLevelMwh == 0 &&
              e.value.state.action == Action.discharge)
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
      final (endState: state, action: action) = dispatchDa[i].value;

      if (i > 0) previousState = dispatchDa[i - 1].value.endState;
      num value;
      switch (action) {
        case Action.charge:
          value = -priceDa *
              (state.batteryLevelMwh - previousState.batteryLevelMwh) /
              battery.efficiencyRating;
        case Action.discharge:
          value =
              priceDa * (previousState.batteryLevelMwh - state.batteryLevelMwh);
        case _:
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
      final stateDa = dispatchDa[i].value.endState;
      final (endState: stateRt, action: action) = dispatchRt[i].value;
      if (i > 0) {
        previousStateDa = dispatchDa[i - 1].value.endState;
        previousStateRt = dispatchRt[i - 1].value.endState;
      }
      num value;
      switch (action) {
        case Action.charge:
          num daQuantity =
              stateDa.batteryLevelMwh - previousStateDa.batteryLevelMwh;
          num rtQuantity =
              stateRt.batteryLevelMwh - previousStateRt.batteryLevelMwh;
          value =
              -priceRt * (rtQuantity - daQuantity) / battery.efficiencyRating;
        case Action.discharge:
          num daQuantity =
              previousStateDa.batteryLevelMwh - stateDa.batteryLevelMwh;
          num rtQuantity =
              previousStateRt.batteryLevelMwh - stateRt.batteryLevelMwh;
          value = priceRt * (rtQuantity - daQuantity);
        case _:
          value = 0;
      }
      out.add(IntervalTuple(interval, value));
    }
    return out;
  }

  /// In the DAM, let the model pick out the best 'n' hours to charge before
  /// this hour.  For example, if [endChargingBeforeHour] = 15, the DAM model
  /// will pick the best 'n' hours to charge before 15:00 and best 'n' hours to
  /// discharge from 15:00.
  TimeSeries<({BatteryState endState, Action action})> _runDaDispatchIsoOptim(
      int endChargingBeforeHour) {
    final out =
        TimeSeries<({BatteryState endState, Action action})>.fromIterable([
      IntervalTuple((daPrice.first.interval as Hour).previous,
          (endState: initialBatteryState, action: Action.none)),
    ]);

    // group by day
    var groups = groupBy(daPrice, (e) => Date.containing(e.interval.start));
    var days = groups.keys.toList();

    for (var day in days) {
      var prices = groups[day]!;
      final hours = day.hours();
      // get the best 'n' hours to charge and discharge
      var bestHours = bestHoursChargeDischarge(prices, battery.hours(),
          endChargingBeforeHour: endChargingBeforeHour);
      var chargingHours = bestHours.charging.map((e) => e.interval).toSet();
      var dischargingHours =
          bestHours.discharging.map((e) => e.interval).toSet();

      for (var i = 0; i < hours.length; i++) {
        var state = out.last.value.endState;
        var cycleNumber = state.cycleNumber;
        var cyclesInCalendarYear = state.cyclesInCalendarYear;
        final batteryLevelMwh = out.last.value.endState.batteryLevelMwh;

        // reset the counter of cycles in calendar year
        if (hours[i].start.year == out.last.interval.start.year + 1) {
          cyclesInCalendarYear = 0;
          state = Empty(
              cycleNumber: cycleNumber,
              cyclesInCalendarYear: cyclesInCalendarYear);
          out.add(IntervalTuple(
              hours[i], (endState: state, action: Action.toEmpty)));
          continue;
        }
        //
        // Introduce OUTAGES here!
        //
        if (cyclesInCalendarYear > battery.maxCyclesPerYear) {
          // battery becomes unavailable
          state = Unavailable(
              cycleNumber: cycleNumber,
              cyclesInCalendarYear: cyclesInCalendarYear);
          out.add(IntervalTuple(
              hours[i], (endState: state, action: Action.toUnavailable)));
          continue;
        }

        // in charging hours
        if (chargingHours.contains(hours[i])) {
          var newLevel = math.min(
              batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh);
          if (state is Empty) {
            // battery begins a new charging cycle
            cycleNumber += 1;
            cyclesInCalendarYear += 1;
          }
          if (newLevel == battery.totalCapacityMWh) {
            // get to full
            state = FullyCharged(
                batteryLevelMwh: battery.totalCapacityMWh,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          } else {
            state = PartiallyCharged(
                batteryLevelMwh: newLevel,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          }
          out.add(IntervalTuple(
              hours[i], (endState: state, action: Action.charge)));
          continue;
        }

        // in discharging hours
        if (dischargingHours.contains(hours[i])) {
          var newLevel = math.max(batteryLevelMwh - battery.ecoMaxMw, 0);
          if (newLevel == 0) {
            state = Empty(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          } else {
            state = PartiallyCharged(
                batteryLevelMwh: newLevel,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
          }
          out.add(IntervalTuple(
              hours[i], (endState: state, action: Action.discharge)));
          continue;
        }

        // continue with the current state
        out.add(
            IntervalTuple(hours[i], (endState: state, action: Action.none)));
      }
    }

    out.removeAt(0); // remove the spurious initial state
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
    cycleStats = _calculateDaCycleStats();
  }

  /// Use a greedy algorith for dispatch:
  ///   If an interval is in the money relative to charging/discharging do it
  ///   if the transition matrix allows it.
  ///
  /// The hours to charge and discharge are preset in the [bidsOffers].  No
  /// attempt is made to select the best hours.
  ///
  TimeSeries<({BatteryState endState, Action action})> _runDispatchSimple({
    required TimeSeries<num> price,
    required TimeSeries<({BidCurve bids, OfferCurve offers})> bidsOffers,
  }) {
    final out =
        TimeSeries<({BatteryState endState, Action action})>.fromIterable([
      IntervalTuple((price.first.interval as Hour).previous,
          (endState: initialBatteryState, action: Action.none)),
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

      var state = out.last.value.endState;
      // what happens in this interval (hour)
      late Action action;
      var cycleNumber = state.cycleNumber;
      var cyclesInCalendarYear = state.cyclesInCalendarYear;
      final batteryLevelMwh = out.last.value.endState.batteryLevelMwh;

      /// reset the counter of cycles in calendar year
      if (interval.start.year == out.last.interval.start.year + 1) {
        cyclesInCalendarYear = 0;
      }

      // Note that the level may not change on some intervals when the
      // battery is charging.  It only means that the prices were not
      // favorable and charging has been paused.  Battery is still on it's
      // way to fully charged, before starting to discharge.
      switch (state) {
        case PartiallyCharged():
          if (priceMkt <= bidPrice) {
            // charge
            action = Action.charge;
            var newLevel = math.min(
                batteryLevelMwh + battery.ecoMaxMw, battery.totalCapacityMWh);
            if (newLevel == battery.totalCapacityMWh) {
              // get to full
              state = FullyCharged(
                  batteryLevelMwh: battery.totalCapacityMWh,
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cyclesInCalendarYear);
              break;
            } else {
              // remain partially charged
              state = PartiallyCharged(
                  batteryLevelMwh: newLevel,
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cyclesInCalendarYear);
              break;
            }
          }

          if (priceMkt >= offerPrice) {
            // discharge
            action = Action.discharge;
            var newLevel = math.max(batteryLevelMwh - battery.ecoMaxMw, 0);
            if (newLevel == 0) {
              // get to empty
              state = Empty(
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cyclesInCalendarYear);
              break;
            } else {
              // remain partially charged
              state = PartiallyCharged(
                  batteryLevelMwh: newLevel,
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cyclesInCalendarYear);
              break;
            }
          }

          // do nothing, keep the same battery level
          state = PartiallyCharged(
              batteryLevelMwh: batteryLevelMwh,
              cycleNumber: cycleNumber,
              cyclesInCalendarYear: cyclesInCalendarYear);
          action = Action.none;

        case FullyCharged():
          if (priceMkt >= offerPrice) {
            // battery starts to discharge
            var newLevel = math.max(batteryLevelMwh - battery.ecoMaxMw, 0);
            state = PartiallyCharged(
                batteryLevelMwh: newLevel,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            action = Action.discharge;
          } else {
            // battery does nothing, remains fully charged
            state = FullyCharged(
                batteryLevelMwh: battery.totalCapacityMWh,
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            action = Action.none;
          }

        case Empty():
          if (cyclesInCalendarYear == battery.maxCyclesPerYear) {
            // battery becomes unavailable
            state = Unavailable(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            action = Action.toUnavailable;
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
              state = PartiallyCharged(
                  batteryLevelMwh: newLevel,
                  cycleNumber: cycleNumber,
                  cyclesInCalendarYear: cyclesInCalendarYear);
              action = Action.charge;
            }
          } else {
            // remains empty
            state = Empty(
                cycleNumber: cycleNumber,
                cyclesInCalendarYear: cyclesInCalendarYear);
            action = Action.none;
          }

        case Unavailable():
          //
          // Introduce OUTAGES here!
          //
          if (cyclesInCalendarYear < battery.maxCyclesPerYear) {
            state = Empty(cycleNumber: cycleNumber, cyclesInCalendarYear: 0);
            action = Action.toEmpty;
            break;
          } else {
            action = Action.none;
            break;
          }
      }

      // record the current state
      out.add(IntervalTuple(interval, (endState: state, action: action)));
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
    rtPrice = daPrice;
  }

  /// In the DAM, let the model pick out the best 'n' hours to charge before
  /// this hour.  For example, if [endChargingBeforeHour] = 15, the DAM model
  /// will pick the best 'n' hours to charge before 15:00 and best 'n' hours to
  /// discharge from 15:00.
  final int endChargingBeforeHour;

  @override
  void run() {
    // DA dispatch, ISO optimizes revenue
    dispatchDa = _runDaDispatchIsoOptim(endChargingBeforeHour);
    pnlDa = _calculateHourlyPnlDa();
    // run to the DA schedule in the RT market
    dispatchRt = TimeSeries.fromIterable(dispatchDa);
    pnlRt = _calculateHourlyPnlRt();
    // cycleStats = _calculateCycleStats();
  }
}

class BatteryOptimizationFlex extends BatteryOptimization {
  /// This algorithm tries to take advantage of price volatility in non-commited
  /// hours.  For example,
  ///  * If P_{RT} > \overline{P}_{DA}^d (1 + f)
  ///
  ///
  /// RT prices are 5min intervals
  ///
  BatteryOptimizationFlex({
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
    assert(chargeDiscount < 1 && chargeDiscount > 0);
    assert(dischargeMultiplier > 1);
  }

  // final TimeSeries<num> rt5MinPrice;

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
    // DA dispatch is the ISO optimization
    dispatchDa = _runDaDispatchIsoOptim(endChargingBeforeHour);
    pnlDa = _calculateHourlyPnlDa();
    //
    dispatchRt = _runRtDispatchFlex();
    pnlRt = _calculateHourlyPnlRt();
    // cycleStats = _calculateCycleStats();
  }

  /// RT dispatch is also hourly.  It could be based on the 5Min interval,
  /// but here it's implemented with the ourly grain
  ///
  TimeSeries<({BatteryState endState, Action action})> _runRtDispatchFlex() {
    var start =
        Interval.ending(rtPrice.first.interval.start, Duration(hours: 1));
    final out =
        TimeSeries<({BatteryState endState, Action action})>.fromIterable([
      IntervalTuple(
          start, (endState: initialBatteryState, action: Action.none)),
    ]);

    final daPriceByDay =
        groupBy(daPrice, (e) => Date.containing(e.interval.start));
    final daDispatchByDay =
        groupBy(dispatchDa, (e) => Date.containing(e.interval.start));
    final rtPriceByDay =
        groupBy(rtPrice, (e) => Date.containing(e.interval.start));

    // loop over the days
    for (var day in rtPriceByDay.keys) {
      var priceDa = daPriceByDay[day]!;
      var priceRt = rtPriceByDay[day]!;
      var daDispatch = daDispatchByDay[day]!;
      // calculate the average charging price
      var avgChargingPriceDa = daDispatch.indexed
          .where((e) => e.$2.value.action == Action.charge)
          .map((e) => e.$1)
          .map((i) => priceDa[i].value)
          .mean();
      // calculate the average discharging price
      var avgDischargingPriceDa = daDispatch.indexed
          .where((e) => e.$2.value.action == Action.discharge)
          .map((e) => e.$1)
          .map((i) => priceDa[i].value)
          .mean();

      var startedEarlyDischarge = false;

      // loop over the hours of the day
      for (var i = 0; i < priceDa.length; i++) {
        final daAction = daDispatch[i].value.action;
        final hour = daDispatch[i].interval as Hour;
        var state = out.last.value.endState;
        var action = out.last.value.action;
        if (state.cyclesInCalendarYear > battery.maxCyclesPerYear) {
          // battery becomes unavailable
          state = Unavailable(
              cycleNumber: state.cycleNumber,
              cyclesInCalendarYear: state.cyclesInCalendarYear);
          out.add(IntervalTuple(
              hour, (endState: state, action: Action.toUnavailable)));
          continue;
        }
        var cyclesInCalendarYear = state.cyclesInCalendarYear;

        /// reset the counter of cycles in calendar year
        if (hour.start.year == out.last.interval.start.year + 1) {
          cyclesInCalendarYear = 0;
        }

        if (startedEarlyDischarge) {
          print(hour.start);
        }

        switch (daAction) {
          ///
          ///
          ///
          case Action.charge:
            if (state.batteryLevelMwh < battery.totalCapacityMWh &&
                !startedEarlyDischarge) {
              action = Action.charge;
              var newLevel = math.min(state.batteryLevelMwh + battery.ecoMaxMw,
                  battery.totalCapacityMWh);
              if (newLevel == battery.totalCapacityMWh) {
                // get to full
                state = FullyCharged(
                    batteryLevelMwh: battery.totalCapacityMWh,
                    cycleNumber: state.cycleNumber,
                    cyclesInCalendarYear: cyclesInCalendarYear);
              } else {
                var adder = state.batteryLevelMwh == 0 ? 1 : 0;
                state = PartiallyCharged(
                    batteryLevelMwh: newLevel,
                    cycleNumber: state.cycleNumber + adder,
                    cyclesInCalendarYear: cyclesInCalendarYear + adder);
              }
            } else {
              // Battery is already full, need to sit it out
              // state remains the same
              action = Action.none;
            }

          ///
          ///
          ///
          case Action.discharge:
            if (state.batteryLevelMwh > 0) {
              action = Action.discharge;
              var newLevel =
                  math.max(state.batteryLevelMwh - battery.ecoMaxMw, 0);
              if (newLevel == 0) {
                state = Empty(
                    cycleNumber: state.cycleNumber,
                    cyclesInCalendarYear: cyclesInCalendarYear);
              } else {
                state = PartiallyCharged(
                    batteryLevelMwh: newLevel,
                    cycleNumber: state.cycleNumber,
                    cyclesInCalendarYear: cyclesInCalendarYear);
              }
            } else {
              // battery is already empty, need to sit it out
              // state remains the same
              action = Action.none;
            }

          ///
          /// Look for RT opportunities in this hour
          ///
          case Action.none:
            action = Action.none;
            if (hour.start.hour < endChargingBeforeHour) {
              // Maybe battery is not yet fully charged, check if it makes
              // sense to charge ahead of DA schedule.
              if (priceRt[i].value < avgChargingPriceDa * chargeDiscount) {
                // charge if not already full
                if (state.batteryLevelMwh < battery.totalCapacityMWh) {
                  action = Action.charge;
                  var newLevel = math.min(
                      state.batteryLevelMwh + battery.ecoMaxMw,
                      battery.totalCapacityMWh);
                  if (newLevel == battery.totalCapacityMWh) {
                    // get to full
                    state = FullyCharged(
                        batteryLevelMwh: battery.totalCapacityMWh,
                        cycleNumber: state.cycleNumber,
                        cyclesInCalendarYear: cyclesInCalendarYear);
                  } else {
                    state = PartiallyCharged(
                        batteryLevelMwh: newLevel,
                        cycleNumber: state.cycleNumber,
                        cyclesInCalendarYear: cyclesInCalendarYear);
                  }
                }
              }
            } else {
              // Maybe battery is not yet fully discharged, check if it
              // makes sense to discharge ahead of DA schedule.
              if (priceRt[i].value >
                  avgDischargingPriceDa * dischargeMultiplier) {
                // discharge if not already empty
                if (state.batteryLevelMwh > 0) {
                  action = Action.discharge;
                  startedEarlyDischarge = true;
                  var newLevel =
                      math.max(state.batteryLevelMwh - battery.ecoMaxMw, 0);
                  if (newLevel == 0) {
                    state = Empty(
                        cycleNumber: state.cycleNumber,
                        cyclesInCalendarYear: cyclesInCalendarYear);
                  } else {
                    state = PartiallyCharged(
                        batteryLevelMwh: newLevel,
                        cycleNumber: state.cycleNumber,
                        cyclesInCalendarYear: cyclesInCalendarYear);
                  }
                }
              }
            }

          case Action.toEmpty:
          case Action.toUnavailable:
            // state and action remains the same as in the DAM
            action = daAction;
            break;
        }
        // add the end state and action for this interval
        out.add(IntervalTuple(hour, (endState: state, action: action)));
      }
    }

    out.removeAt(0); // remove the spurious initial state
    return out;
  }
}
