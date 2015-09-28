library elec.iso;

import 'package:timezone/standalone.dart';
import 'package:elec/src/time/bucket/bucket.dart';


abstract class Iso {
  static Location location;
}

class Nepool implements Iso {
  static final Location location = getLocation('America/New_York');

  static final bucket5x16    = new Bucket5x16(location);
  static final bucket2x16H   = new Bucket2x16H(location);
  static final bucket7x8     = new Bucket7x8(location);
  static final bucketOffpeak = new BucketOffpeak(location);

}

class Caiso extends Iso {
  static final Location location = getLocation('America/Los_Angeles');
}

class Ercot extends Iso {
  static final Location location = getLocation('America/Chicago');
}