library load.solar.lib_solar_elevation;

import 'dart:math';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

var coordinates = <String,Coordinates>{
  'BOS': Coordinates(42.34, -71.03),
};


class Coordinates {
  num latitude;
  num longitude;
  Coordinates(this.latitude, this.longitude);
}


/// Calculate the solar elevation angle in degrees.
/// The elevation angle (used interchangeably with altitude angle) is the
/// angular height of the sun in the sky measured from the horizontal.
/// The elevation is 0° at sunrise and 90° when the sun is directly overhead
/// (which occurs for example at the equator on the spring and fall equinoxes).
/// This function implements the spreadsheet calculations from
/// https://www.esrl.noaa.gov/gmd/grad/solcalc/calcdetails.html
/// For more general details see:
/// https://www.pveducation.org/pvcdrom/properties-of-sunlight/elevation-angle
///
/// [latitude] is positive to North, [longitude] is positive to East.
///
/// The tilt angle has a major impact on the solar radiation incident on a
/// surface. For a fixed tilt angle, the maximum power over the course of a year
/// is obtained when the tilt angle is equal to the latitude of the location.
num solarElevationAngle(num latitude, num longitude, TZDateTime dt) {
  if (dt.isBefore(DateTime(1901)) || dt.isAfter(DateTime(2099))) {
    throw UnimplementedError(
        'Calculation is valid only between years 1901-2099');
  }

  var offset = dt.timeZoneOffset.inHours;
  var time = dt
          .difference(TZDateTime(dt.location, dt.year, dt.month, dt.day))
          .inMinutes /
      1440;
  var julianDay = _julianDay(dt);
  var julianCentury = (julianDay - 2451545) / 36525;
  var geomMeanLongSun =
      (280.46646 + julianCentury * (36000.76983 + julianCentury * 0.0003032)) %
          360; // in degrees
  var geomMeanAnomSun = 357.52911 +
      julianCentury * (35999.05029 - 0.0001537 * julianCentury); // in degrees
  var eccenticity = 0.016708634 -
      julianCentury * (0.000042037 + 0.0000001267 * julianCentury);
  var sunEqOfCtr = sin(_rad(geomMeanAnomSun)) *
          (1.914602 - julianCentury * (0.004817 + 0.000014 * julianCentury)) +
      sin(_rad(2 * geomMeanAnomSun)) * (0.019993 - 0.000101 * julianCentury) +
      sin(_rad(3 * geomMeanAnomSun)) * 0.000289;

  var sunTrueLong = geomMeanLongSun + sunEqOfCtr; // in degrees

  var sunAppLong = sunTrueLong -
      0.00569 -
      0.00478 * sin(_rad(125.04 - 1934.136 * julianCentury)); // in degrees
  var meanObliqEcliptic = 23 +
      (26 +
              ((21.488 -
                      julianCentury *
                          (46.815 +
                              julianCentury *
                                  (0.00059 - julianCentury * 0.001813)))) /
                  60) /
          60; // in degrees
  var obliqCorr = meanObliqEcliptic +
      0.00256 * cos(_rad(125.04 - 1934.136 * julianCentury));

  var sunDeclin =
      _degree(asin(sin(_rad(obliqCorr)) * sin(_rad(sunAppLong)))); // in degrees

  var varY = tan(_rad(obliqCorr / 2)) * tan(_rad(obliqCorr / 2));

  var eqOfTime = 4 *
      _degree(varY * sin(2 * _rad(geomMeanLongSun)) -
          2 * eccenticity * sin(_rad(geomMeanAnomSun)) +
          4 *
              eccenticity *
              varY *
              sin(_rad(geomMeanAnomSun)) *
              cos(2 * _rad(geomMeanLongSun)) -
          0.5 * varY * varY * sin(4 * _rad(geomMeanLongSun)) -
          1.25 * eccenticity * eccenticity * sin(2 * _rad(geomMeanAnomSun)));

  var trueSolarTime = (time * 1440 + eqOfTime + 4 * longitude - 60 * offset) %
      1440; // in minutes

  var hourAngle = (trueSolarTime / 4 < 0)
      ? trueSolarTime / 4 + 180
      : trueSolarTime / 4 - 180; // in degrees

  var solarZenithAngle = _degree(acos(
      sin(_rad(latitude)) * sin(_rad(sunDeclin)) +
          cos(_rad(latitude)) * cos(_rad(sunDeclin)) * cos(_rad(hourAngle))));

  var solarElevationAngle = 90 - solarZenithAngle;
  return solarElevationAngle;
}

final _origin = 25569;

/// An approximation valid between years 1901-2099.
num _julianDay(DateTime dt) {
  var shift = Date.fromTZDateTime(dt as TZDateTime).value + _origin;
  var offset = dt.timeZoneOffset.inHours / 24;
  return shift + 2415018.5 + (dt.hour * 60 + dt.minute) / 1440 - offset;
}

num _rad(num degree) => degree * pi / 180;

num _degree(num radian) => 180 * radian / pi;
