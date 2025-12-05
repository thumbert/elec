import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:timezone/timezone.dart' as tz;
import 'location.dart';

class ElectricityIndex extends Object with Location {
  Iso? iso;
  int ptid;
  Market market;
  LmpComponent lmpComponent;
  final commodity = Commodity.electricity;
  late tz.Location tzLocation;

  ElectricityIndex(this.iso, this.ptid, this.market, this.lmpComponent);

  ElectricityIndex.isoNewEngland(this.ptid, this.market, this.lmpComponent) {
    iso = IsoNewEngland();
    tzLocation = tz.getLocation('America/New_York');
  }
}
