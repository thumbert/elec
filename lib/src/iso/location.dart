library iso.location;

import 'dart:async';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/ftr/auction.dart';


abstract class Location {
  int ptid;
  String name;
  Iso iso;

  factory Location() {

  }

}

class NepoolLocation implements Location {
  int ptid;
  String name;
  Iso iso = new Nepool();

  NepoolLocation.fromPtid(this.ptid);
  NepoolLocation.fromName(this.name);

}
