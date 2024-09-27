library src.physical.gen.battery;

import 'package:date/date.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/offer_curve.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';
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

sealed class BatteryState {
  /// General description of a battery state, always associated with a
  /// time interval.
  ///
  ///
  BatteryState({
    required this.batteryLevelMwh,
    required this.cycleNumber,
    required this.cyclesInCalendarYear,
  });

  /// The amount of energy still left in the battery at the end
  /// of the [interval].
  final num batteryLevelMwh;

  /// Keep track of which cycle you are currently in.
  ///
  /// What constitues a cycle?  A cycle is a trip from
  /// empty -> charging -> fully charged -> discharging -> empty.  Depending on
  /// the bids/offers, there can be multiple cycles in a day, or a cycle can
  /// stretch over multiple days.
  ///
  final int cycleNumber;

  /// How many cycles has the battery been through this calendar year.  Resets
  /// to zero at the beginning of each year.
  ///
  final int cyclesInCalendarYear;

  @override
  String toString() {
    return 'batteryLevelMWh: $batteryLevelMwh, '
        'cyclesInCalendarYear: $cyclesInCalendarYear';
  }

  Map<String, dynamic> toMap() {
    return {
      'batteryLevelMwh': batteryLevelMwh,
      'cycleNumber': cycleNumber,
      'cyclesInCalendarYear': cyclesInCalendarYear,
    };
  }
}

class ChargingState extends BatteryState {
  /// The battery is charging in this interval.
  /// Even if the battery becomes fully charged a the end of the interval, the
  /// state of the battery for the interval is marked as charging, and only
  /// the following interval it will be marked FullyCharged.
  ChargingState(
      {required super.batteryLevelMwh,
      required super.cycleNumber,
      required super.cyclesInCalendarYear});

  @override
  String toString() {
    return 'Charging,    ${super.toString()}';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.charging,
      ...super.toMap(),
    };
  }
}

class FullyChargedState extends BatteryState {
  FullyChargedState(
      {required super.batteryLevelMwh,
      required super.cycleNumber,
      required super.cyclesInCalendarYear});
  @override
  String toString() {
    return 'Full,        ${super.toString()}';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.fullyCharged,
      ...super.toMap(),
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
    required super.cycleNumber,
    required super.cyclesInCalendarYear,
  });

  @override
  String toString() {
    return 'Discharging, ${super.toString()}';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.discharging,
      ...super.toMap(),
    };
  }
}

class EmptyState extends BatteryState {
  /// Battery is an empty state waiting for conditions to meet to go into
  /// a charging state.
  EmptyState({required super.cycleNumber, required super.cyclesInCalendarYear})
      : super(batteryLevelMwh: 0);

  @override
  String toString() {
    return 'Empty,       ${super.toString()}';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.empty,
      ...super.toMap(),
    };
  }
}

class Unavailable extends BatteryState {
  /// If the battery is on outage or has exceeded the maximum number of
  /// cycles in a year.
  Unavailable({required super.cycleNumber, required super.cyclesInCalendarYear})
      : super(batteryLevelMwh: 0);

  @override
  String toString() {
    return 'Unavailable, ${super.toString()}';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'mode': BatteryMode.unavailable,
      ...super.toMap(),
    };
  }
}

class Battery {
  Battery({
    required this.ecoMaxMw,
    required this.efficiencyRating,
    required this.totalCapacityMWh,
    required this.maxCyclesPerYear,
    required this.degradationFactor,
  }) {
    maxLoadMw = ecoMaxMw / efficiencyRating;
  }

  /// Maximum amount of power to discharge
  final num ecoMaxMw;

  /// Round trip efficiency rating, typically a value around 0.85
  final num efficiencyRating;

  /// How much energy can the battery hold in MWh when fully charged.
  ///
  final num totalCapacityMWh;

  /// Max charge/discharge cycles in a **calendar** year
  final int maxCyclesPerYear;

  /// Can be a value by calendar year, e.g 2026 -> 0.95, 2027 -> 0.92, ...
  /// Or even monthly frequency if needed.
  /// NOT IMPLEMENTED YET!
  final TimeSeries<num> degradationFactor;

  /// Maximum amount of power to charge.  Only needed as a convenience 
  /// when the charging bids are constructed!  
  late final num maxLoadMw;
}

/// Construct hourly bids/offers to use in the dispatch.
/// Various strategies can be represented this way.
///
/// * [chargingBids] high prices
/// * [nonChargingBids] low prices
/// * [dischargingOffers] low prices
/// * [nonDischargingOffers] high prices
///
TimeSeries<({BidCurve bids, OfferCurve offers})> makeBidsOffers({
  required Term term,
  required Set<int> chargeHours,
  required Set<int> dischargeHours,
  required List<PriceQuantityPair> chargingBids, // high prices
  required List<PriceQuantityPair> nonChargingBids, // low prices
  required List<PriceQuantityPair> dischargingOffers, // low prices
  required List<PriceQuantityPair> nonDischargingOffers, // high prices
}) {
  var hours = term.hours();
  var out = TimeSeries<({BidCurve bids, OfferCurve offers})>();
  for (var hour in hours) {
    var bidsC = BidCurve();
    if (chargeHours.contains(hour.start.hour)) {
      bidsC.addAll(chargingBids);
    } else {
      bidsC.addAll(nonChargingBids);
    }
    var offerC = OfferCurve();
    if (dischargeHours.contains(hour.start.hour)) {
      offerC.addAll(dischargingOffers);
    } else {
      offerC.addAll(nonDischargingOffers);
    }

    out.add(IntervalTuple(hour, (bids: bidsC, offers: offerC)));
  }

  return out;
}




/// A battery mode is associated with a time interval, be it 5 min, 15 min or
/// an hour.
enum BatteryMode {
  charging,
  fullyCharged,
  discharging,
  empty,
  unavailable;
}
