
import 'package:elec/risk_system.dart';
import 'package:date/date.dart';

//abstract class ChargeDischargeProfile {
//
//}


class Battery {

  Mw ecoMax;
  Mw maxLoad;
  Mwh totalCapacity;

  /// the energy available in the battery to discharge
  Mwh energy;

  /// Calculate the percent charged as a fraction of totalCapacity if the
  /// battery is put to charge for a certain duration given the current
  /// energy state.
  num Function(Duration, num) chargingProfile;

  /// A function that given a duration and the current state,
  /// returns the percent discharged.
  num Function(Duration, num) dischargingProfile;


  Battery.simple(this.ecoMax, this.maxLoad, this.totalCapacity,
      num chargeRateMinute, num dischargeRateMinute) {
    chargingProfile = (Duration duration, num energy) {

    };
  }



}