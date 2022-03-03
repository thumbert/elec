library elec.iso;

import 'package:timezone/timezone.dart' as tz;
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/iso/location.dart';

abstract class Iso {
  String get name;
  Set<String> get serviceTypes;

  late tz.Location preferredTimeZoneLocation;

  static final Iso ieso = Ieso();
  static final Iso newEngland = IsoNewEngland();
  static final Iso newYork = NewYorkIso();
  static final Iso pjm = Pjm();

  static final _map = <String, Iso>{
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

  /// A map from loadZone name to ptid
  static const loadZones = <String, int>{};
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

  /// A convenient location, should be used.
  static const loadZones = <String, int>{
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

  static const loadZones = <String, int>{
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

  /// Allowed service types in this ISO
  @override
  final serviceTypes = <String>{
    'Energy',
    // Maybe others, eh?
  };

  @override
  tz.Location preferredTimeZoneLocation = tz.getLocation('America/New_York');
}

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
}

class Ieso implements Iso {
  @override
  final String name = 'IESO';
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
}

//class Caiso extends Iso {
//static final Location location = getLocation('America/Los_Angeles');
//}

//class Ercot extends Iso {
//  //static final Location location = getLocation('America/Chicago');
//}
