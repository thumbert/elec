part of 'electricity_location.dart';

mixin IsoNewEnglandLocation implements Location {
  final Iso iso = Iso.newEngland;
  final location = tz.getLocation('America/New_York');

  static final hubDa = MassHubDa();
  static final maineZoneDa = MaineZoneDa();
  static final nhZoneDa = NhZoneDa();
  static final ctZoneDa = CtZoneDa();
  static final riZoneDa = RiZoneDa();
  static final semaZoneDa = SemaZoneDa();
  static final wcmaZoneDa = WcmaZoneDa();
  static final nemaZoneDa = NemaZoneDa();

  static final rosetonDa = Roseton(Market.da);
}

class MassHubDa extends ElectricityLocation with IsoNewEnglandLocation {
  MassHubDa() {
    name = '.H.INTERNAL_HUB';
    ptid = 4000;
    market = Market.da;
  }
}

class CtZoneDa extends ElectricityLocation with IsoNewEnglandLocation {
  CtZoneDa() {
    name = '.Z.CONNECTICUT';
    ptid = 4004;
    market = Market.da;
  }
}

class MaineZoneDa extends ElectricityLocation with IsoNewEnglandLocation {
  MaineZoneDa() {
    name = '.Z.MAINE';
    ptid = 4001;
    market = Market.da;
  }
}

class NemaZoneDa extends ElectricityLocation with IsoNewEnglandLocation {
  NemaZoneDa() {
    name = '.Z.NEMASSBOST';
    ptid = 4008;
    market = Market.da;
  }
}

class NhZoneDa extends ElectricityLocation with IsoNewEnglandLocation {
  NhZoneDa() {
    name = '.Z.NEWHAMPSHIRE';
    ptid = 4002;
    market = Market.da;
  }
}

class RiZoneDa extends ElectricityLocation with IsoNewEnglandLocation {
  RiZoneDa() {
    name = '.Z.RHODEISLAND';
    ptid = 4005;
    market = Market.da;
  }
}

class SemaZoneDa extends ElectricityLocation with IsoNewEnglandLocation {
  SemaZoneDa() {
    name = '.Z.SEMASS';
    ptid = 4006;
    market = Market.da;
  }
}

class WcmaZoneDa extends ElectricityLocation with IsoNewEnglandLocation {
  WcmaZoneDa() {
    name = '.Z.WCMASS';
    ptid = 4007;
    market = Market.da;
  }
}

class Roseton extends ElectricityLocation with IsoNewEnglandLocation {
  Roseton(Market market) {
    name = '.I.ROSETON 345 1';
    ptid = 4011;
    this.market = market;
  }
}
