library elec.iso;

import 'package:timezone/standalone.dart' as tz;
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/iso/location.dart';


abstract class Iso {
  String get name;
  //static final IsoNewEngland = new NewEngland();
}



class IsoNewEngland implements Iso {
  final String name = 'ISONE';
  static tz.Location location = tz.getLocation('US/Eastern');

  static final bucket5x16    = new Bucket5x16(location);
  static final bucket2x16H   = new Bucket2x16H(location);
  static final bucket7x8     = new Bucket7x8(location);
  static final bucket7x24    = new Bucket7x24(location);
  static final bucketOffpeak = new BucketOffpeak(location);
  static final bucketPeak    = new Bucket5x16(location);

  //static final Location hub = new NepoolLocation.fromPtid(4000)..name='Hub';

}



//class Caiso extends Iso {
  //static final Location location = getLocation('America/Los_Angeles');
//}

//class Ercot extends Iso {
//  //static final Location location = getLocation('America/Chicago');
//}