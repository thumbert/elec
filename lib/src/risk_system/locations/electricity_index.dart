library risk_system.locations.electricity_index;

import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:timezone/timezone.dart' as tz;
import 'location.dart';

class ElectricityIndex extends Location {
  Iso? iso;
  int ptid;
  Market market;
  LmpComponent lmpComponent;
  final commodity = Commodity.electricity;

  ElectricityIndex(this.iso, this.ptid, this.market, this.lmpComponent);

  ElectricityIndex.IsoNewEngland(this.ptid, this.market, this.lmpComponent) {
    iso = IsoNewEngland();
    tzLocation = tz.getLocation('America/New_York');
  }
}