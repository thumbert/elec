library elec.iso;

import 'package:timezone/timezone.dart' as tz;
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/iso/location.dart';


abstract class Iso {
  String get name;
  Set<String> get serviceTypes;

  tz.Location preferredTimeZoneLocation;

  static final Iso newEngland = IsoNewEngland();

  factory Iso.parse(String x) {
    if (x.toLowerCase() == 'isone') {
      return IsoNewEngland();
    } else {
      throw ArgumentError('Iso $x not supported yet');
    }
  }
}



class IsoNewEngland implements Iso {
  @override
  final String name = 'ISONE';
  static tz.Location location = tz.getLocation('US/Eastern');
  static final Bucket bucket5x8     = Bucket5x8(location);
  static final Bucket bucket5x16    = Bucket5x16(location);
  static final Bucket bucket7x16    = Bucket7x16(location);
  static final Bucket bucket2x8     = Bucket2x8(location);
  static final Bucket bucket2x16H   = Bucket2x16H(location);
  static final Bucket bucket2x16    = Bucket2x16(location);
  static final Bucket bucket7x8     = Bucket7x8(location);
  static final Bucket bucket7x24    = Bucket7x24(location);
  static final Bucket bucketOffpeak = BucketOffpeak(location);
  static final Bucket bucketPeak    = bucket5x16;

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
  tz.Location preferredTimeZoneLocation = tz.getLocation('US/Eastern');



}



//class Caiso extends Iso {
  //static final Location location = getLocation('America/Los_Angeles');
//}

//class Ercot extends Iso {
//  //static final Location location = getLocation('America/Chicago');
//}
