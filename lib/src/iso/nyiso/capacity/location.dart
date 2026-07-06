import 'package:elec/src/iso/load_zone.dart';

import '../../iso.dart';

enum CapacityLocation {
  gjLocality, // Zones G, H, I, J
  longIsland, // Zone K
  lowerHudsonValley, // Zones G, H, I
  nyc, // Zone J
  nyca, // New York Control Area (all the zones)
  hq,
  ieso,
  ne,
  pjm,
  restOfPool; // Zones A, B, C, D, E, F

  static CapacityLocation parse(String x) {
    return switch (x) {
      'G-J Locality' => CapacityLocation.gjLocality,
      'Long Island' || 'LI' => CapacityLocation.longIsland,
      'Lower Hudson Valley'  || 'LHV' => CapacityLocation.lowerHudsonValley,
      'NYC' => CapacityLocation.nyc,
      'NYCA' => CapacityLocation.nyca,
      'HQ' => CapacityLocation.hq,
      'IESO' => CapacityLocation.ieso,
      'NE' => CapacityLocation.ne,
      'PJM' => CapacityLocation.pjm,
      'Rest of Pool' || 'ROP' => CapacityLocation.restOfPool,
      _ => throw ArgumentError('Unknown CapacityLocation: $x')
    };
  }

  String get name {
    return switch (this) {
      CapacityLocation.gjLocality => 'G-J Locality',
      CapacityLocation.longIsland => 'Long Island',
      CapacityLocation.lowerHudsonValley => 'Lower Hudson Valley',
      CapacityLocation.nyc => 'NYC',
      CapacityLocation.nyca => 'NYCA',
      CapacityLocation.hq => 'HQ',
      CapacityLocation.ieso => 'IESO',
      CapacityLocation.ne => 'NE',
      CapacityLocation.pjm => 'PJM',
      CapacityLocation.restOfPool => 'Rest of Pool',
    };
  }

  String get shortName {
    return switch (this) {
      CapacityLocation.gjLocality => 'G-J Locality',
      CapacityLocation.longIsland => 'LI',
      CapacityLocation.lowerHudsonValley => 'LHV',
      CapacityLocation.nyc => 'NYC',
      CapacityLocation.nyca => 'NYCA',
      CapacityLocation.hq => 'HQ',
      CapacityLocation.ieso => 'IESO',
      CapacityLocation.ne => 'NE',
      CapacityLocation.pjm => 'PJM',
      CapacityLocation.restOfPool => 'ROP',
    };
  }

  List<LoadZone> get zones {
    return switch (this) {
      CapacityLocation.gjLocality => [
          NewYorkIso.zoneG,
          NewYorkIso.zoneH,
          NewYorkIso.zoneI,
          NewYorkIso.zoneJ
        ],
      CapacityLocation.longIsland => [NewYorkIso.zoneK],
      CapacityLocation.lowerHudsonValley => [
          NewYorkIso.zoneG,
          NewYorkIso.zoneH,
          NewYorkIso.zoneI
        ],
      CapacityLocation.nyc => [NewYorkIso.zoneJ],
      CapacityLocation.nyca => [
          NewYorkIso.zoneA,
          NewYorkIso.zoneB,
          NewYorkIso.zoneC,
          NewYorkIso.zoneD,
          NewYorkIso.zoneE,
          NewYorkIso.zoneF,
          NewYorkIso.zoneG,
          NewYorkIso.zoneH,
          NewYorkIso.zoneI,
          NewYorkIso.zoneJ,
          NewYorkIso.zoneK,
        ],
      CapacityLocation.hq => [],
      CapacityLocation.ieso => [],
      CapacityLocation.ne => [],
      CapacityLocation.pjm => [],
      CapacityLocation.restOfPool => [
          NewYorkIso.zoneA,
          NewYorkIso.zoneB,
          NewYorkIso.zoneC,
          NewYorkIso.zoneD,
          NewYorkIso.zoneE,
          NewYorkIso.zoneF
        ],
    };
  }
}
