//library risk_system.locations.curve_id;
//
//import 'package:elec/elec.dart';
//import 'package:elec/risk_system.dart';
//import 'package:timezone/timezone.dart' as tz;
//
//
//class CurveId {
//  tz.Location tzLocation;
//  String _name;
//  String _curve;
//  Map<String,dynamic> _components;
//
//  /// Create a curveId from components.  The resulting curveId is available in
//  /// [name].  Constructing the curveId from components is brittle, better use
//  /// specialized constructors.  No checks are made to ensure that the order
//  /// of components is right, or that the values are valid.
//  CurveId(String name) {
//    _name = name.toLowerCase();
//    _components = <String,dynamic>{};
//    tzLocation = tz.getLocation('America/New_York');
//    /// TODO: Fixme once you have a database!
//    if (name == 'isone_energy_4000_da_lmp') {
//      _components = {
//        'iso': IsoNewEngland(),
//        'serviceType': 'energy',
//        'ptid': 4000,
//        'name': 'Mass Hub',
//        'market': Market.da,
//        'lmpComponent': LmpComponent.lmp,
//      };
//      _curve = 'HUB_DA_LMP';
//
//    } else if (name == 'isone_energy_4004_da_lmp') {
//      _components = {
//        'iso': IsoNewEngland(),
//        'serviceType': 'energy',
//        'ptid': 4004,
//        'name': 'CT',
//        'market': Market.da,
//        'lmpComponent': LmpComponent.lmp,
//      };
//      _curve = 'CT_DA_LMP';
//    }
//  }
//
//  CurveId.forIsoEnergyPtid(Iso iso, int ptid, Market market, LmpComponent component) {
//    _components = <String,dynamic>{
//      'iso': iso,
//      'serviceType': 'energy',
//      'ptid': ptid,
//      'market': market,
//      'lmpComponent': component,
//    };
//    _name = '${iso.name.toLowerCase()}_energy_${ptid}'
//      '_${market.name.toLowerCase()}_${component.name.toLowerCase()}';
//    tzLocation = iso.preferredTimeZoneLocation;
//  }
//
//
//  /// Name is lower case.
//  /// For example: isone_elec_hub_lmp_da, isone_elec_hub_mcc_da
//  String get name => _name;
//
//  String get curve => _curve;
//
//  Map<String,dynamic> get components => _components;
//}