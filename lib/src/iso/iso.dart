library elec.iso;

import 'package:timezone/standalone.dart' as tz;
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/iso/location.dart';


abstract class Iso {
  String get name;
}



class IsoNewEngland implements Iso {
  final String name = 'ISONE';
  static tz.Location location = tz.getLocation('US/Eastern');

  static final Bucket bucket5x16    = new Bucket5x16(location);
  static final Bucket bucket7x16    = new Bucket7x16(location);
  static final Bucket bucket2x16H   = new Bucket2x16H(location);
  static final Bucket bucket2x16    = new Bucket2x16(location);
  static final Bucket bucket7x8     = new Bucket7x8(location);
  static final Bucket bucket7x24    = new Bucket7x24(location);
  static final Bucket bucketOffpeak = new BucketOffpeak(location);
  static final Bucket bucketPeak    = bucket5x16;
}



//class Caiso extends Iso {
  //static final Location location = getLocation('America/Los_Angeles');
//}

//class Ercot extends Iso {
//  //static final Location location = getLocation('America/Chicago');
//}
