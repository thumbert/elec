part of elec.risk_system;


abstract class BaseHub {
  Commodity commodity;
  String hub;
}


class EnergyHub implements BaseHub {
  Commodity commodity = Commodity.energy;
  String hub;
  Market market;
  Iso iso;
  Location tzLocation;

  EnergyHub(this.hub, this.market, this.iso, this.tzLocation) {
    if (hub == null) throw ArgumentError('Argument hub can\'t be null.');
    if (market == null) throw ArgumentError('Argument market can\'t be null.');
    if (iso == null) throw ArgumentError('Argument iso can\'t be null.');
    if (tzLocation == null) throw ArgumentError('Argument tzLocation can\'t be null.');
  }

  /// Construct an EnergyHub from a Json object
  EnergyHub.fromMap(Map<String,dynamic> x) {
    var commodity = Commodity.parse(x['commodity']);
    if (commodity != Commodity.energy)
      throw ArgumentError('$x is not an energy hub');
    hub = x['hub'];
    market = Market.parse(x['market']);
    iso = Iso.parse(x['iso']);
    tzLocation = getLocation(x['tzLocation']);
  }

  Map<String,dynamic> toMap() {
    return <String,dynamic> {
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
