library iso.location;

import 'package:timezone/timezone.dart' as tz;
import 'package:elec/elec.dart';
import 'package:elec/src/iso/iso.dart';


abstract class Location {
  String? name;
  Iso? iso;
  tz.Location get tzLocation;
}

//class IsoNewEnglandLocation implements Location {
//  int ptid;
//  String name;
//
//  final tz.Location tzLocation = tz.getLocation('America/New_York');
//  Iso iso = new IsoNewEngland();
//
//  NepoolLocation.fromPtid(this.ptid) {}
//  NepoolLocation.fromName(this.name) {}
//
//  Bucket get bucket2x16H => new Bucket2x16H(tzLocation);
//  Bucket get bucket5x16  => new Bucket5x16(tzLocation);
//  Bucket get bucket7x8   => new Bucket7x8(tzLocation);
//  Bucket get bucket7x24  => new Bucket7x24(tzLocation);
//  Bucket get bucketOffpeak  => new BucketOffpeak(tzLocation);
//
//}
