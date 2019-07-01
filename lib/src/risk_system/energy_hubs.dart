part of elec.risk_system;

abstract class BaseHub {
  Commodity commodity;
  String hub;
}

class EnergyHub implements BaseHub {
  Commodity commodity = Commodity.electricity;
  String hub;
  Market market;
  Iso iso;
  Location tzLocation;

  static final _cacheHubs = <Tuple4, EnergyHub>{};

  factory EnergyHub(String hub, Market market, Iso iso, Location tzLocation) {
    var t4 = Tuple4(hub, market, iso, tzLocation);
    if (!_cacheHubs.containsKey(t4))
      _cacheHubs[t4] = EnergyHub._internal(hub, market, iso, tzLocation);
    return _cacheHubs[t4];
  }

  EnergyHub._internal(this.hub, this.market, this.iso, this.tzLocation) {
    if (hub == null) throw ArgumentError('Argument hub can\'t be null.');
    if (market == null) throw ArgumentError('Argument market can\'t be null.');
    if (iso == null) throw ArgumentError('Argument iso can\'t be null.');
    if (tzLocation == null)
      throw ArgumentError('Argument tzLocation can\'t be null.');
  }

  /// Construct an EnergyHub from a Json object
  EnergyHub.fromMap(Map<String, dynamic> x) {
    // TODO: add some checks here
    var commodity = Commodity.parse(x['commodity']);
    if (commodity != Commodity.electricity)
      throw ArgumentError('$x is not an energy hub');
    hub = x['hub'];
    market = Market.parse(x['market']);
    iso = Iso.parse(x['iso']);
    tzLocation = getLocation(x['tzLocation']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'commodity': 'energy',
      'hub': hub,
      'market': market.toString(),
      'iso': iso.name,
      'tzLocation': tzLocation.name,
    };
  }

  static final massHubDa =
      EnergyHub('MassHub', Market.da, IsoNewEngland(), _eastern);

  String toString() => '${iso.name} $hub $market';
}

class NgHub implements BaseHub {
  var commodity = Commodity.ng;
  String hub;

  NgHub(this.hub);

  static final henry = NgHub('Henry');
  static final tetcoM3 = NgHub('Tetco-M3');
  static final agtcg = NgHub('Algonquin');
}
