library src.physical.gen.battery;

import 'dart:math';

import 'package:date/date.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/offer_curve.dart';
import 'package:timeseries/timeseries.dart';

final class BidsOffers {
  BidsOffers({required this.bids, required this.offers});
  BidCurve bids;
  OfferCurve offers;

  @override
  String toString() {
    return 'bids: ${bids.toString()}, offers: ${offers.toString()}';
  }
}

class BatteryOptimization {
  BatteryOptimization({
    required this.battery,
    required this.daPrice,
    required this.rtPrice,
    required this.bidsOffers,
  });

  final Battery battery;
  final TimeSeries<num> daPrice;
  final TimeSeries<num> rtPrice;
  final TimeSeries<BidsOffers> bidsOffers;

  ///
  TimeSeries<num> calculatePnlDa(
      TimeSeries<BatteryState> states, BatteryState initialState) {
    var out = TimeSeries<num>();
    var previousState = initialState;
    for (var i = 0; i < states.length; i++) {
      if (daPrice[i].interval != states[i].interval) {
        throw StateError(
            'Missaligned DA prices and battery states, position $i');
      }
      final interval = daPrice[i].interval;
      final priceDa = daPrice[i].value;
      final state = states[i].value;
      if (i > 0) previousState = states[i - 1].value;
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

  /// Use a greedy algorith for dispatch in the DAM:
  ///   If an interval is in the money relative to charging/discharging do it
  ///   if the transition matrix allows it.
  TimeSeries<BatteryState> dispatchDa({
    required BatteryState initialState,
  }) {
    final out = TimeSeries<BatteryState>.fromIterable([
      IntervalTuple((daPrice.first.interval as Hour).previous, initialState),
    ]);

    for (var i = 0; i < bidsOffers.length; i++) {
      if (daPrice[i].interval != bidsOffers[i].interval) {
        throw StateError(
            'Missaligned DA prices and bids/offers, ${daPrice[i].interval}');
      }
      final interval = daPrice[i].interval;
      final priceDa = daPrice[i].value;
      final bidPrice = bidsOffers[i].value.bids.first.price;
      final offerPrice = bidsOffers[i].value.offers.first.price;
      if (offerPrice <= priceDa && priceDa <= bidPrice) {
        throw StateError('Inconsistent state for ${daPrice[i].interval}.  '
            'Offer price of $offerPrice <= DA price $priceDa <= bid price $bidPrice');
      }

      var state = out.last.value;
      var cycles = state.cyclesInCalendarYear;
      final batteryLevelMwh = out.last.value.batteryLevelMwh;

      switch (state) {
        case ChargingState():
          if (batteryLevelMwh == battery.totalCapacityMWh) {
            state = FullyChargedState(
                batteryLevelMwh: battery.totalCapacityMWh,
                cyclesInCalendarYear: cycles);
            break;
          }
          var newLevel = (priceDa <= bidPrice)
              ? min(
                  batteryLevelMwh + battery.maxLoadMw, battery.totalCapacityMWh)
              : batteryLevelMwh;
          // Note that the level may not change on some intervals when the
          // battery is charging.  It only means that the prices were not
          // favorable and charging has been paused.  Battery is still on it's
          // way to fully charged, before starting to discharge.
          state = ChargingState(
              batteryLevelMwh: newLevel, cyclesInCalendarYear: cycles);

        case FullyChargedState():
          if (priceDa >= offerPrice) {
            // battery is discharging
            var newLevel = max(batteryLevelMwh - battery.ecoMaxMw, 0);
            state = DischargingState(
                batteryLevelMwh: newLevel, cyclesInCalendarYear: cycles);
          }

        case DischargingState():
          if (batteryLevelMwh == 0) {
            state = EmptyState(cyclesInCalendarYear: cycles);
            break;
          }
          var newLevel = (priceDa >= offerPrice)
              ? max(batteryLevelMwh - battery.ecoMaxMw, 0)
              : batteryLevelMwh;
          // Note that the level may not change on some intervals when the
          // battery is discharging.  It only means that the prices were not
          // favorable and discharging has been paused.  Battery is still on
          // it's way to the empty state, before starting a new charging cycle.
          state = DischargingState(
              batteryLevelMwh: newLevel, cyclesInCalendarYear: cycles);

        case EmptyState():
          if (cycles > battery.maxCyclesPerYear) {
            // battery becomes unavailable
            state = Unavailable(cyclesInCalendarYear: cycles);
            break;
          }
          // Introduce OUTAGES here!
          if (priceDa <= bidPrice) {
            // battery begins a new charging cycle
            cycles += 1;
            var newLevel = min(
                batteryLevelMwh + battery.maxLoadMw, battery.totalCapacityMWh);
            if (newLevel <= battery.totalCapacityMWh &&
                batteryLevelMwh < battery.totalCapacityMWh) {
              state = ChargingState(
                  batteryLevelMwh: newLevel, cyclesInCalendarYear: cycles);
            }
          }

        case Unavailable():
          if (interval.start.year == out.last.interval.start.year + 1) {
            // reset cycles to 0 on new year and move to empty
            out.add(
                IntervalTuple(interval, EmptyState(cyclesInCalendarYear: 0)));
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

sealed class BatteryState {
  /// General description of a battery state, always associated with a
  /// time interval.
  ///
  ///
  BatteryState({
    required this.batteryLevelMwh,
    required this.cyclesInCalendarYear,
  });

  /// The amount of energy still left in the battery at the end
  /// of the [interval].
  final num batteryLevelMwh;

  /// How many cycles has the battery been through this
  /// calendar year.  Resets to zero at the beginning of
  /// each year.
  ///
  /// What constitues a cycle?
  ///   Is it any trip from empty -> charging -> discharging -> empty?
  ///   Does it depend on getting to fully charged state?
  ///
  final int cyclesInCalendarYear;

  @override
  String toString() {
    return 'batteryLevelMWh: $batteryLevelMwh, '
        'cycles: $cyclesInCalendarYear';
  }
}

class ChargingState extends BatteryState {
  /// The battery is charging in this interval.
  /// Even if the battery becomes fully charged a the end of the interval, the
  /// state of the battery for the interval is marked as charging, and only
  /// the following interval it will be marked FullyCharged.
  ChargingState(
      {required super.batteryLevelMwh, required super.cyclesInCalendarYear});

  @override
  String toString() {
    return 'Charging,    ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.charging,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class FullyChargedState extends BatteryState {
  FullyChargedState(
      {required super.batteryLevelMwh, required super.cyclesInCalendarYear});
  @override
  String toString() {
    return 'Full,        ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.fullyCharged,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class DischargingState extends BatteryState {
  /// The battery is discharging in this interval.
  /// Even if the battery becomes empty a the end of the interval, the
  /// state of the battery for the interval is marked as discharging, and only
  /// the following interval it will be marked Empty.
  DischargingState({
    required super.batteryLevelMwh,
    required super.cyclesInCalendarYear,
  });

  @override
  String toString() {
    return 'Discharging, ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.discharging,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class EmptyState extends BatteryState {
  /// Battery is an empty state waiting for conditions to meet to go into
  /// a charging state.
  EmptyState({required super.cyclesInCalendarYear}) : super(batteryLevelMwh: 0);

  @override
  String toString() {
    return 'Empty,       ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.empty,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class Unavailable extends BatteryState {
  /// If the battery is on outage or has exceeded the maximum number of
  /// cycles in a year.
  Unavailable({required super.cyclesInCalendarYear})
      : super(batteryLevelMwh: 0);

  @override
  String toString() {
    return 'Unavailable, ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.unavailable,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class Battery {
  Battery({
    required this.ecoMaxMw,
    required this.maxLoadMw,
    required this.totalCapacityMWh,
    required this.maxCyclesPerYear,
  });

  /// Maximum amount of power to discharge
  final num ecoMaxMw;

  /// Maximum amount of power to charge
  final num maxLoadMw;

  /// How much energy can the battery hold in MWh
  final num totalCapacityMWh;

  /// Max charge/discharge cycles in a calendar year
  final int maxCyclesPerYear;
}

/// A battery mode is associated with a time interval, be it 5 min, 15 min or
/// an hour.
enum BatteryMode {
  charging,
  fullyCharged,
  discharging,
  empty,
  unavailable,
}
