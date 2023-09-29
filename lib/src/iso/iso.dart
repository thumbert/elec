library elec.iso;

import 'package:elec/src/iso/load_zone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:elec/src/time/bucket/bucket.dart';

abstract class Iso {
  String get name;
  Set<String> get serviceTypes;
  Map<String, int> get loadZones;

  late tz.Location preferredTimeZoneLocation;

  static final Iso ercot = Ercot();
  static final Iso ieso = Ieso();
  static final Iso newEngland = IsoNewEngland();
  static final Iso newYork = NewYorkIso();
  static final Iso pjm = Pjm();

  static final _map = <String, Iso>{
    'ercot': ercot,
    'ieso': ieso,
    'isone': newEngland,
    'nyiso': newYork,
    'pjm': pjm,
  };

  factory Iso.parse(String x) {
    if (_map.containsKey(x.toLowerCase())) {
      return _map[x.toLowerCase()]!;
    } else {
      throw ArgumentError('Iso $x not supported yet');
    }
  }
}

class IsoNewEngland implements Iso {
  @override
  final String name = 'ISONE';
  static tz.Location location = tz.getLocation('America/New_York');
  static final Bucket bucket5x8 = Bucket.b5x8;
  static final Bucket bucket5x16 = Bucket.b5x16;
  static final Bucket bucket7x16 = Bucket.b7x16;
  static final Bucket bucket2x8 = Bucket.b2x8;
  static final Bucket bucket2x16H = Bucket.b2x16H;
  static final Bucket bucket2x16 = Bucket.b2x16;
  static final Bucket bucket7x8 = Bucket.b7x8;
  static final Bucket bucket7x24 = Bucket.atc;
  static final Bucket bucketOffpeak = Bucket.offpeak;
  static final Bucket bucketPeak = bucket5x16;

  /// the load zones
  static final maine = LoadZone('MAINE', 4001);
  static final newHampshire = LoadZone('NH', 4002);
  static final vermont = LoadZone('VT', 4003);
  static final connecticut = LoadZone('CT', 4004);
  static final rhodeIsland = LoadZone('RI', 4005);
  static final sema = LoadZone('SEMA', 4006);
  static final wcma = LoadZone('WCMA', 4007);
  static final nema = LoadZone('NEMA', 4008);

  /// A convenient location, should be used.
  @override
  final loadZones = <String, int>{
    'Maine': 4001,
    'NH': 4002,
    'VT': 4003,
    'CT': 4004,
    'RI': 4005,
    'SEMA': 4006,
    'WCMA': 4007,
    'NEMA': 4008,
  };

  /// Allowed service types in this ISO
  @override
  final serviceTypes = <String>{
    'Energy',
    'FwdRes',
    'Lscpr',
    'OpRes',
    'Volt',
    'Regulation',
    'TrSch2',
    'TrSch3',
  };

  @override
  tz.Location preferredTimeZoneLocation = tz.getLocation('America/New_York');
}

class NewYorkIso implements Iso {
  @override
  final String name = 'NYISO';
  static tz.Location location = tz.getLocation('America/New_York');
  static final Bucket bucket5x8 = Bucket.b5x8;
  static final Bucket bucket5x16 = Bucket.b5x16;
  static final Bucket bucket7x16 = Bucket.b7x16;
  static final Bucket bucket2x8 = Bucket.b2x8;
  static final Bucket bucket2x16H = Bucket.b2x16H;
  static final Bucket bucket2x16 = Bucket.b2x16;
  static final Bucket bucket7x8 = Bucket.b7x8;
  static final Bucket bucket7x24 = Bucket.atc;
  static final Bucket bucketOffpeak = Bucket.offpeak;
  static final Bucket bucketPeak = bucket5x16;

  @override
  final loadZones = <String, int>{
    'Zone A': 61752,
    'Zone B': 61753,
    'Zone C': 61754,
    'Zone D': 61755,
    'Zone E': 61756,
    'Zone F': 61757,
    'Zone G': 61758,
    'Zone H': 61759,
    'Zone I': 61760,
    'Zone J': 61761,
    'Zone K': 61762,
  };

  final loadZoneNameToPtid = <String, int>{
    'WEST': 61752,
    'CAPITL': 61757,
    'CENTRL': 61754,
    'DUNWOD': 61760,
    'GENESE': 61753,
    'HUD VL': 61758,
    'LONGIL': 61762,
    'MHK VL': 61756,
    'MILLWD': 61759,
    'N.Y.C.': 61761,
    'NORTH': 61755,
  };

  /// Allowed service types in this ISO
  @override
  final serviceTypes = <String>{
    'Energy',
    // Maybe others, eh?
  };

  @override
  tz.Location preferredTimeZoneLocation = tz.getLocation('America/New_York');

  /// the load zones
  static final zoneA = LoadZone('WEST', 61752);
  static final zoneB = LoadZone('GENESE', 61753);
  static final zoneC = LoadZone('CENTRL', 61754);
  static final zoneD = LoadZone('NORTH', 61755);
  static final zoneE = LoadZone('MHK VL', 61756);
  static final zoneF = LoadZone('CAPITL', 61757);
  static final zoneG = LoadZone('HUD VL', 61758);
  static final zoneH = LoadZone('MILLWD', 61759);
  static final zoneI = LoadZone('DUNWOD', 61760);
  static final zoneJ = LoadZone('N.Y.C.', 61761);
  static final zoneK = LoadZone('LONGIL', 61762);
}

///
///
///
///
class Pjm implements Iso {
  @override
  final String name = 'PJM';
  static tz.Location location = tz.getLocation('America/New_York');
  static final Bucket bucket5x8 = Bucket.b5x8;
  static final Bucket bucket5x16 = Bucket.b5x16;
  static final Bucket bucket7x16 = Bucket.b7x16;
  static final Bucket bucket2x8 = Bucket.b2x8;
  static final Bucket bucket2x16H = Bucket.b2x16H;
  static final Bucket bucket2x16 = Bucket.b2x16;
  static final Bucket bucket7x8 = Bucket.b7x8;
  static final Bucket bucket7x24 = Bucket.atc;
  static final Bucket bucketOffpeak = Bucket.offpeak;
  static final Bucket bucketPeak = bucket5x16;

  /// Allowed service types in this ISO
  @override
  final serviceTypes = <String>{
    'Energy',
    // Maybe others, eh?
  };

  @override
  tz.Location preferredTimeZoneLocation = tz.getLocation('America/New_York');

  @override
  final Map<String, int> loadZones = {
    'AECO': 51291,
    'AEP': 8445784,
    'APS': 8394954,
    'ATSI': 116013753,
    'BGE': 51292,
    'COMED': 33092371,
    'DAY': 34508503,
    'DEOK': 124076095,
    'DOM': 34964545,
    'DPL': 51293,
    'DUQ': 37737283,
    'EKPC': 970242670,
    'JCPL': 51295,
    'METED': 51296,
    'OVEC': 1709725933,
    'PECO': 51297,
    'PENELEC': 51300,
    'PEPCO': 51298,
    'PPL': 51299,
    'PSEG': 51301,
    'RECO': 7633629,
  };
}

class Ieso implements Iso {
  @override
  final String name = 'IESO';

  /// Yes, you read it right.  Ontario publishes all their data in EST time
  /// that is, no daylight savings (no 23 hours in Mar, 25 in Nov).  It's -0500
  /// all year long.  Wikipedia recommends using America/Cancun as the
  /// timezone that respects that year long.
  static tz.Location location = tz.getLocation('America/Cancun');
  static final Bucket bucket5x8 = Bucket.b5x8;
  static final Bucket bucket5x16 = Bucket.b5x16;
  static final Bucket bucket7x16 = Bucket.b7x16;
  static final Bucket bucket2x8 = Bucket.b2x8;
  static final Bucket bucket2x16H = Bucket.b2x16H;
  static final Bucket bucket2x16 = Bucket.b2x16;
  static final Bucket bucket7x8 = Bucket.b7x8;
  static final Bucket bucket7x24 = Bucket.atc;
  static final Bucket bucketOffpeak = Bucket.offpeak;
  static final Bucket bucketPeak = bucket5x16;

  /// load zones
  static final ontario = IesoLoadZone.ontario; // all of the pool
  static final northwest = IesoLoadZone.northwest;
  static final northeast = IesoLoadZone.northeast;
  static final ottawa = IesoLoadZone.ottawa;
  static final east = IesoLoadZone.east;
  static final toronto = IesoLoadZone.toronto;
  static final essa = IesoLoadZone.essa;
  static final bruce = IesoLoadZone.bruce;
  static final southwest = IesoLoadZone.southwest;
  static final niagara = IesoLoadZone.niagara;
  static final west = IesoLoadZone.west;

  @override
  final loadZones = <String, int>{
    'Northwest': 0,
    'NorthEast': 0,
    'Ottawa': 0,
    'East': 0,
    'Toronto': 0,
    'Essa': 0,
    'Bruce': 0,
    'Southwest': 0,
    'Niagara': 0,
    'West': 0,
  };

  /// Allowed service types in this ISO
  @override
  final serviceTypes = <String>{
    'Energy',
    // Maybe others, eh?
  };

  /// Yes, you read it right.  Ontario publishes all their data in EST time
  /// that is, no daylight savings (no 23 hours in Mar, 25 in Nov).  It's -0500
  /// all year long.  Wikipedia recommends using America/Cancun as the
  /// timezone that respects that year long.
  @override
  tz.Location preferredTimeZoneLocation = tz.getLocation('America/Cancun');
}

//class Caiso extends Iso {
//static final Location location = getLocation('America/Los_Angeles');
//}

class Ercot implements Iso {
  static final location = tz.getLocation('America/Chicago');

  @override
  final String name = 'ERCOT';
  @override
  tz.Location preferredTimeZoneLocation = tz.getLocation('America/Chicago');

  static final Bucket bucket5x16 = Bucket.peakErcot;
  static final Bucket bucket7x16 = Bucket.b7x16Ercot;
  static final Bucket bucket2x16H = Bucket.b2x16HErcot;
  static final Bucket bucket7x8 = Bucket.b7x8Ercot;
  static final Bucket bucket7x24 = Bucket.atc;
  static final Bucket bucketOffpeak = Bucket.offpeakErcot;
  static final Bucket bucketPeak = bucket5x16;

  @override

  /// I made up some ptids because Ercot doesn't have them as of 11/11/2022
  Map<String, int> get loadZones => {
        'LZ AEN': 1000,
        'LZ CPS': 1001,
        'LZ HOUSTON': 1002,
        'LZ LCRA': 1003,
        'LZ NORTH': 1004,
        'LZ RAYBN': 1005,
        'LZ SOUTH': 1006,
        'LZ WEST': 1007,
      };

  static const List<String> hubNames = [
    'HB_BUSAVG',
    'HB_HOUSTON',
    'HB_HUBAVG',
    'HB_NORTH',
    'HB_PAN',
    'HB_SOUTH',
    'HB_WEST',
  ];

  @override
  // TODO: implement serviceTypes
  Set<String> get serviceTypes => throw UnimplementedError();
}
