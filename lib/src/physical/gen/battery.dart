library src.physical.gen.battery;

import 'package:date/date.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';
import 'package:timeseries/timeseries.dart';

class BatteryOptimization {
  BatteryOptimization(
      {required this.battery,
      required this.daPrice,
      required this.rtPrice,
      required this.bids,
      required this.offers});

  final Battery battery;
  final TimeSeries<num> daPrice;
  final TimeSeries<num> rtPrice;
  final TimeSeries<List<PriceQuantityPair>> bids;
  final TimeSeries<List<PriceQuantityPair>> offers;

  List<State> dispatch({
    required State initialState,
  }) {
    final out = <State>[];

    return out;
  }


}


// class BidsOffersForDay {
//   BidsOffersForDay(
//       {required this.date, required this.bids, required this.offers}) {
//     // check that the inputs are correct
//   }

//   final Date date;
//   final TimeSeries<List<PriceQuantityPair>> bids;
//   final TimeSeries<List<PriceQuantityPair>> offers;
// }

// class PriceInsensitiveDispatch implements DispatchStrategy {
//   /// Charge and discharge at the same time every day, irrespective of the price.
//   /// With an hourly resolution.
//   PriceInsensitiveDispatch({
//     required this.chargingHoursRange,
//     required this.dischargingHoursRange,
//   });

//   final (int, int) chargingHoursRange;
//   final (int, int) dischargingHoursRange;

//   @override
//   List<State> dispatch({
//     required Battery battery,
//     required State initialState,
//     required TimeSeries<num> price,
//   }) {
//     final out = <State>[];

//     for (var e in price) {
//       final prevState = out.isEmpty ? initialState : out.last;

//       // switch (prevState.mode) {
//       //   case BatteryMode.charging:
//       //   // TODO: Handle this case.
//       //   case BatteryMode.discharging:
//       //   // TODO: Handle this case.
//       //   case BatteryMode.offline:
//       // }

//       // final hour = e.interval.start.hour;
//       // if (hour >= chargingHoursRange.$1 && hour <= chargingHoursRange.$2) {
//       //   // battery is charging
//       //   var cyclesInCalendarYear = out.isEmpty
//       //       ? initialState.cyclesInCalendarYear
//       //       : out.last.cyclesInCalendarYear;
//       //   if (out.last.mode == BatteryMode.offline) {
//       //     // start a new cycle
//       //     cyclesInCalendarYear += 1;
//       //   }
//       //   var newState = State(
//       //     interval: e.interval,
//       //     mode: BatteryMode.charging,
//       //     cyclesInCalendarYear: cyclesInCalendarYear,
//       //   );
//       //   if (newState.isValid(battery)) {
//       //     out.add(newState);
//       //   }
//       // }

//       // if (hour >= chargingHoursRange.$1 && hour <= chargingHoursRange.$2) {
//       //   // battery is discharging
//       // }
//     }

//     return out;
//   }
// }

/// A battery mode is associated with a time interval, be it 5 min, 15 min or
/// an hour.
enum BatteryMode {
  charging,
  fullyCharged,
  discharging,
  empty,
  offline,
}

sealed class State {
  State({
    required this.interval,
    // required this.mode,
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
  final int cyclesInCalendarYear;
}

class ChargingState extends State {
  ChargingState(
      {required super.interval,
      required super.batteryLevelMwh,
      required super.cyclesInCalendarYear});

  ChargingState toCharging() {
    return ChargingState(
        interval: interval,
        batteryLevelMwh: batteryLevelMwh,
        cyclesInCalendarYear: cyclesInCalendarYear);
  }

  // DischargingState toDischarging() {
  //   return DischargingState(
  //       interval: interval,
  //       batteryLevelMwh: batteryLevelMwh,
  //       cyclesInCalendarYear: cyclesInCalendarYear);
  // }

  FullyChargedState toFullyCharged() {
    return FullyChargedState(
        interval: interval,
        batteryLevelMwh: batteryLevelMwh,
        cyclesInCalendarYear: cyclesInCalendarYear);
  }
}

class FullyChargedState extends State {
  FullyChargedState(
      {required super.interval,
      required super.batteryLevelMwh,
      required super.cyclesInCalendarYear});

  FullyChargedState toFullyCharged() {
    return FullyChargedState(
        interval: interval,
        batteryLevelMwh: batteryLevelMwh,
        cyclesInCalendarYear: cyclesInCalendarYear);
  }

  DischargingState toDischarging() {
    return DischargingState(
        interval: interval,
        batteryLevelMwh: batteryLevelMwh,
        cyclesInCalendarYear: cyclesInCalendarYear);
  }
}

class DischargingState extends State {
  DischargingState({
    required super.interval,
    required super.batteryLevelMwh,
    required super.cyclesInCalendarYear,
  });

  // ChargingState toCharging() {
  //   return ChargingState(
  //       interval: interval,
  //       batteryLevelMwh: batteryLevelMwh,
  //       cyclesInCalendarYear: cyclesInCalendarYear);
  // }

  DischargingState toDischarging() {
    return DischargingState(
        interval: interval,
        batteryLevelMwh: batteryLevelMwh,
        cyclesInCalendarYear: cyclesInCalendarYear);
  }

  EmptyState toEmpty() {
    return EmptyState(
        interval: interval, batteryLevelMwh: 0, cyclesInCalendarYear: 0);
  }
}

class EmptyState extends State {
  EmptyState(
      {required super.interval,
      required super.batteryLevelMwh,
      required super.cyclesInCalendarYear});

  ChargingState toCharging() {
    return ChargingState(
        interval: interval,
        batteryLevelMwh: batteryLevelMwh,
        cyclesInCalendarYear: cyclesInCalendarYear);
  }

  Unavailable toUnavailable() {
    return Unavailable(
        interval: interval,
        batteryLevelMwh: batteryLevelMwh,
        cyclesInCalendarYear: cyclesInCalendarYear);
  }
}

class Unavailable extends State {
  Unavailable(
      {required super.interval,
      required super.batteryLevelMwh,
      required super.cyclesInCalendarYear});

  EmptyState toEmpty() {
    return EmptyState(
        interval: interval, batteryLevelMwh: 0, cyclesInCalendarYear: 0);
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
