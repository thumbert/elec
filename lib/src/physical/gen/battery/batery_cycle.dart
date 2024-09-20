// library physical.gen.battery.battery_cycle;

// import 'package:date/date.dart';
// import 'package:elec/src/physical/gen/battery/battery.dart';
// import 'package:timeseries/timeseries.dart';

// class BatteryCycle {
//   /// A cycle is what happens to the battery between the first charging interval
//   /// and the last discharging interval included.
//   ///
//   /// A cycle can be all within a day, may stretch into another day, or you
//   /// can have multiple cycles in a day (rare).
//   ///
//   ///

//   BatteryCycle.fromIterable(Iterable<IntervalTuple<BatteryState>> xs) {
//     /// Add checks that this iterable of battery states actually make
//     /// a cycle.
//     for (var x in xs) {
//       _data.add(x);
//     }
//   }

//   final _data = <IntervalTuple<BatteryState>>[];

//   // final Interval interval;
//   // // in $/MWh
//   // final num meanChargingDaPrice;
//   // // in $/MWh
//   // final num meanDischargingDaPrice;
//   // // in $
//   // final num costChargingDa;
//   // // in $
//   // final num revenueDischargingDa;

//   Interval interval() =>
//       Interval(_data.first.interval.start, _data.last.interval.end);

//   // in $/MWh
//   num meanChargingPrice() {}

//   // in $
//   num get pnl => revenueDischargingDa - costChargingDa;

//   Map<String, dynamic> toJson() {
//     return <String, dynamic>{
//       'start': interval.start.toIso8601String(),
//       'end': interval.end.toIso8601String(),
//       'meanChargingDaPrice': meanChargingDaPrice,
//       'meandDischargingDaPrice': meanDischargingDaPrice,
//       'costChargingDa': costChargingDa,
//       'revenueDischargingDa': revenueDischargingDa,
//       'PnL': pnl,
//     };
//   }
// }
