library risk_system.locations.location;

import 'package:elec/risk_system.dart';
import 'package:timezone/timezone.dart' as tz;

abstract class Location {
  Commodity? commodity;
  tz.Location? tzLocation;
}