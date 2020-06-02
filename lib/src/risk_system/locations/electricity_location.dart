library risk_system.electricity_location;

import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:timezone/timezone.dart' as tz;
import 'location.dart';

class ElectricityLocation extends Location {
  Iso iso;
  int ptid;
  Market market;
  @override
  final commodity = Commodity.electricity;

  ElectricityLocation(this.iso, this.ptid, this.market);

  ElectricityLocation.IsoNewEngland(this.ptid, this.market) {
    iso = IsoNewEngland();
    tzLocation = tz.getLocation('US/Eastern');
  }
}