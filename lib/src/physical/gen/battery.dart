library src.physical.gen.battery;

import 'package:date/date.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';
import 'package:timeseries/timeseries.dart';

final class BidsOffers {
  BidsOffers({required this.bids, required this.offers});
  List<PriceQuantityPair> bids;
  List<PriceQuantityPair> offers;

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

  /// Use a greedy algorith for dispatch in the DAM:
  ///   If an interval is in the money relative to charging/discharging do it
  ///   if the transition matrix allows it.
  List<BatteryState> dispatchDa({
    required BatteryState initialState,
  }) {
    assert(initialState.interval.end == daPrice.first.interval.start);

    final out = <BatteryState>[
      initialState,
    ];

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
      if (interval.start.year == out.last.interval.start.year + 1) {
        // reset cycles to 0 on new year and move to empty
        out.add(EmptyState(interval: interval, cyclesInCalendarYear: 0));
        continue;
      }
      int cycles = out.last.cyclesInCalendarYear;
      if (cycles > battery.maxCyclesPerYear) {
        out.add(Unavailable(interval: interval, cyclesInCalendarYear: cycles));
        continue;
      }

      if (priceDa <= bidPrice) {
        // battery should charge based on economics
        switch (out.last) {
          case ChargingState() || EmptyState():
            cycles += (out.last is EmptyState ? 1 : 0);
            var newLevel = out.last.batteryLevelMwh + battery.maxLoadMw;
            if (newLevel < battery.totalCapacityMWh) {
              // battery remains in charging state
              out.add(ChargingState(
                  interval: interval,
                  batteryLevelMwh: newLevel,
                  cyclesInCalendarYear: cycles));
            } else {
              // battery is now charged
              out.add(FullyChargedState(
                  interval: interval,
                  batteryLevelMwh: battery.totalCapacityMWh,
                  cyclesInCalendarYear: cycles));
            }
          case FullyChargedState():
            out.add(FullyChargedState(
                interval: interval,
                batteryLevelMwh: battery.totalCapacityMWh,
                cyclesInCalendarYear: cycles));
          case DischargingState():
            out.add(DischargingState(
                interval: interval,
                batteryLevelMwh: battery.totalCapacityMWh,
                cyclesInCalendarYear: cycles));
          case Unavailable():
            out.add(
                Unavailable(interval: interval, cyclesInCalendarYear: cycles));
        }
      } else if (priceDa >= offerPrice) {
        // battery can discharge
        switch (out.last) {
          case ChargingState():
            out.add(ChargingState(
                interval: interval,
                batteryLevelMwh: out.last.batteryLevelMwh,
                cyclesInCalendarYear: cycles));
          case FullyChargedState() || DischargingState():
            var newLevel = out.last.batteryLevelMwh - battery.ecoMaxMw;
            if (newLevel > 0) {
              // battery can continue to discharge
              out.add(DischargingState(
                  interval: interval,
                  batteryLevelMwh: newLevel,
                  cyclesInCalendarYear: cycles));
            } else {
              // battery is now empty
              out.add(
                  EmptyState(interval: interval, cyclesInCalendarYear: cycles));
            }
          case EmptyState():
            out.add(
                EmptyState(interval: interval, cyclesInCalendarYear: cycles));
          case Unavailable():
            out.add(
                Unavailable(interval: interval, cyclesInCalendarYear: cycles));
        }
      } else {
        out.add(out.last);
      }
    }

    out.removeAt(0); // the initial state
    return out;
  }
}

sealed class BatteryState {
  /// General description of a battery state
  BatteryState({
    required this.interval,
    required this.batteryLevelMwh,
    required this.cyclesInCalendarYear,
  });

  /// A time interval to describe the state of the battery
  /// Can be hourly, 15-min, 5-min, etc.
  /// Assumed the same during the entire program.
  final Interval interval;

  /// State of the battery during this [interval].
  // final BatteryMode mode;

  /// The amount of energy available to discharge at the end
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
    return 'interval: $interval, batteryLevelMWh: $batteryLevelMwh, '
        'cycles: $cyclesInCalendarYear';
  }
}

class ChargingState extends BatteryState {
  ChargingState(
      {required super.interval,
      required super.batteryLevelMwh,
      required super.cyclesInCalendarYear});

  @override
  String toString() {
    return 'Charging,    ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.charging,
      'interval': interval,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class FullyChargedState extends BatteryState {
  FullyChargedState(
      {required super.interval,
      required super.batteryLevelMwh,
      required super.cyclesInCalendarYear});
  @override
  String toString() {
    return 'Full,        ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.fullyCharged,
      'interval': interval,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class DischargingState extends BatteryState {
  DischargingState({
    required super.interval,
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
      'interval': interval,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class EmptyState extends BatteryState {
  /// Battery is an empty state waiting for conditions to meet to go into
  /// a charging state.
  EmptyState({required super.interval, required super.cyclesInCalendarYear})
      : super(batteryLevelMwh: 0);

  @override
  String toString() {
    return 'Empty,       ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.empty,
      'interval': interval,
      'batteryLevelMwh': batteryLevelMwh,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class Unavailable extends BatteryState {
  /// If the battery is on outage or has exceeded the maximum number of
  /// cycles in a year.
  Unavailable({required super.interval, required super.cyclesInCalendarYear})
      : super(batteryLevelMwh: 0);

  @override
  String toString() {
    return 'Unavailable, ${super.toString()}';
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.unavailable,
      'interval': interval,
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

  ///
  // static TimeSeries<num> calculateRevenue(List<State> states) {

  // }
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

