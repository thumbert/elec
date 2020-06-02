part of elec.risk_system;

/// On second thoughts, maybe this is too much configuration to maintain in a
/// static variable.  Not sure it pays off, when you need to add additional ones.
/// It's only convenient for the developer.  The maintainer will suffer.
///

//class ServiceType {
//  final String shortName;
//  final String longName;
//
//  const ServiceType._internal(this.shortName, this.longName);
//
//  static const energy = ServiceType._internal('Energy', 'Energy');
//  static const forwardReserves = ServiceType._internal('FwdRes', 'Forward Reserves');
//  static const lscpr = ServiceType._internal('Lscpr', 'Local Second Contingency Protection');
//  static const opres = ServiceType._internal('OpRes', 'Operating Reserves');
//  static const trSch2 = ServiceType._internal('TrSch2', 'TrSch2');
//  static const trSch3 = ServiceType._internal('TrSch3', 'TrSch3');
//  static const voltage = ServiceType._internal('Voltage', 'Voltage');
//
//  factory ServiceType.parse(String x) {
//    var y = x.toLowerCase();
//    if (y == 'energy') {
//      return energy;
//    } else if (y == 'fwdres' || y == 'forward reserves') {
//      return forwardReserves;
//    } else {
//      throw ArgumentError('Unsuported ServiceType $x');
//    }
//  }
//
//}