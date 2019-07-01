library elec.iso;

import 'package:timezone/timezone.dart' as tz;
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/iso/location.dart';


abstract class Iso {
  String get name;

  factory Iso.parse(String x) {
    var y = x.toLowerCase();
    if (y == 'isone') return IsoNewEngland();
    else throw ArgumentError('Iso $x not supported yet');
  }
}



class IsoNewEngland implements Iso {
  final String name = 'ISONE';
  static tz.Location location = tz.getLocation('US/Eastern');

  static final Bucket bucket5x16    = Bucket5x16(location);
  static final Bucket bucket7x16    = Bucket7x16(location);
  static final Bucket bucket2x16H   = Bucket2x16H(location);
  static final Bucket bucket2x16    = Bucket2x16(location);
  static final Bucket bucket7x8     = Bucket7x8(location);
  static final Bucket bucket2x8     = Bucket2x8(location);
  static final Bucket bucket7x24    = Bucket7x24(location);
  static final Bucket bucketOffpeak = BucketOffpeak(location);
  static final Bucket bucketPeak    = bucket5x16;
}



//class Caiso extends Iso {
  //static final Location location = getLocation('America/Los_Angeles');
//}

//class Ercot extends Iso {
//  //static final Location location = getLocation('America/Chicago');
//}
