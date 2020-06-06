library risk_system.locations.curve_id;

import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timezone/timezone.dart' as tz;


class CurveId {
  tz.Location tzLocation;
  String _name;
  Map<String,dynamic> _components;

  /// Create a curveId from components.  The resulting curveId is available in
  /// [name].  Constructing the curveId from components is brittle, better use
  /// specialized constructors.  No checks are made to ensure that the order
  /// of components is right, or that the values are valid.
  CurveId(String name) {
    _name = name.toLowerCase();
    _components = <String,dynamic>{};
    tzLocation = tz.getLocation('US/Eastern');
    /// TODO: Fixme once you have a database!
    if (name == 'isone_energy_4000_da_lmp') {
      _components = {
        'iso': IsoNewEngland(),
        'serviceType': 'energy',
        'ptid': 4000,
        'name': 'Mass Hub',
        'market': Market.da,
        'lmpComponent': LmpComponent.lmp,
      };
    } else if (name == 'isone_energy_4004_da_lmp') {
      _components = {
        'iso': IsoNewEngland(),
        'serviceType': 'energy',
        'ptid': 4004,
        'name': 'CT',
        'market': Market.da,
        'lmpComponent': LmpComponent.lmp,
      };
    }
  }

  CurveId.forIsoEnergyPtid(Iso iso, int ptid, Market market, LmpComponent component) {
    _components = <String,dynamic>{
      'iso': iso,
      'serviceType': 'energy',
      'ptid': ptid,
      'market': market,
      'lmpComponent': component,
    };
    _name = '${iso.name.toLowerCase()}_energy_${ptid}'
      '_${market.name.toLowerCase()}_${component.name.toLowerCase()}';
    tzLocation = iso.preferredTimeZoneLocation;
  }


  /// Name is lower case.
  /// For example: isone_elec_hub_lmp_da, isone_elec_hub_mcc_da
  String get name => _name;

  Map<String,dynamic> get components => _components;

//  /// for curves within an ISO, start with the iso name.
//  set iso(Iso iso) {
//    if (_step != 0) {
//      throw ArgumentError('Iso can only be in position 0');
//    }
//    _step++;
//    _components['iso'] = iso;
//    _name += iso.name.toLowerCase();
//  }
//
//  /// E.g. 'Energy', 'FwdRes', 'OpRes', ...
//  set serviceType(String serviceType) {
//    if (_step != 1 ) {
//      throw ArgumentError('ServiceType needs to be in position 1');
//    }
//    _step++;
//    _components['serviceType'] = serviceType.toLowerCase();
//    _name += '_' + serviceType.toLowerCase();
//  }
//
//  /// Prefer using a ptid to a deliveryPoint, if ptid is available.
//  set deliveryPoint(String deliveryPoint) {
//    if (_components.containsKey('ptid')) {
//      throw ArgumentError('Can\'t set both ptid and deliveryPoint for one curve');
//    }
//    _step++;
//    _components['deliveryPoint'] = deliveryPoint;
//    _name += '_' + deliveryPoint.toLowerCase();
//  }
//
//  /// Prefer using a ptid to a deliveryPoint, if ptid is available.
//  set ptid(int ptid) {
//    if (_components.containsKey('deliveryPoint')) {
//      throw ArgumentError('Can\'t set both ptid and deliveryPoint for one curve');
//    }
//    _step++;
//    _components['ptid'] = ptid;
//    _name += '_' + ptid.toString().toLowerCase();
//  }
//
//  /// Add an LmpComponent, e.g. lmp, congestion, loss
//  set lmpComponent(LmpComponent component) {
//    if (_components['serviceType'] != 'energy') {
//      throw ArgumentError('Can\'t set up an LMP component for serviceType ${_components['serviceType']}');
//    }
//    _step++;
//    _components['lmpComponent'] = component.toString();
//    _name += '_' + component.toString();
//  }
//
//  /// Add a DA/RT market component
//  set market(Market market) {
//    _step++;
//    _components['market'] = market.toString().toLowerCase();
//    _name += '_' + market.toString().toLowerCase();
//  }

}