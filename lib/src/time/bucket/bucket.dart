library elec.bucket;

import 'package:timezone/standalone.dart';
import 'package:timeseries/time/calendar.dart';
import 'package:timeseries/time/date.dart';
import 'package:timeseries/elec/iso.dart';

abstract class Bucket {
  static final Duration H1 = new Duration(hours: 1);
  Calendar calendar;
  String name;
  //Iso iso;

  /**
   * Does this bucket contains the HourEnding dt?
   * [dt] needs to be an hour ending DateTime (0 min, 0 seconds, 0 millis)
   * If the location of [dt] is not the same as the [iso] location, error.
   */
  bool containsHourEnding(TZDateTime dt) => containsHourBeginning(dt.subtract(Bucket.H1));

  /**
   * Does this bucket contains the HourBeginning dt?
   */
  bool containsHourBeginning(TZDateTime dt);

  /**
   * Count the number of Hour Ending hours between start and end that belong to this bucket.
   * [start] is an HourEnding DateTime
   * [end] is an HourEnding DateTime
   */
//  int hoursIn(DateTime start, DateTime end) {
//    int hrs = 0;
//    var current = start;
//    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
//      if (containsHourEnding(current))
//        hrs += 1;
//    }
//
//    return hrs;
//  }
}


class Bucket7x24 extends Bucket {
  final String name = '7x24';
  Iso iso;
  Calendar calendar = new NercCalendar();

  Bucket7x24(Iso this.iso);

  bool containsHourEnding(DateTime dt) => true;
  bool containsHourBeginning(DateTime dt) => true;
}

class Bucket7x8 extends Bucket {
  final String name = '7x8';
  Location location;
  Calendar calendar = new NercCalendar();

  Bucket7x8(Location this.location);

  bool containsHourBeginning(TZDateTime dt) {
    if (dt.location != location)
      throw new ArgumentError('dt location doesn\'t match iso location');
    if (dt.hour <= 6 || dt.hour == 23)
      return true;

    return false;
  }
}

class Bucket5x16 extends Bucket {
  final String name = '5x16';
  Location location;
  Calendar calendar = new NercCalendar();

  Bucket5x16(Location this.location);

  bool containsHourBeginning(TZDateTime dt) {
    if (dt.location != location)
      throw new ArgumentError('dt location doesn\'t match iso location');
    int dayOfWeek = dt.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (dt.hour < 7 || dt.hour == 23) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday(new Date(dt.year, dt.month, dt.day)))
          /// it's a holiday
          return false;
        else
          return true;
      }
    }

    return false;
  }
}

class Bucket2x16H extends Bucket {
  final String name = '2x16H';
  Location location;
  Calendar calendar = new NercCalendar();

  Bucket2x16H(Location this.location);

  bool containsHourBeginning(TZDateTime dt) {
    if (dt.location != location)
      throw new ArgumentError('dt location doesn\'t match iso location');
    int dayOfWeek = dt.weekday;
    if (dt.hour < 7 || dt.hour == 23)
      return false;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (calendar.isHoliday(new Date(dt.year, dt.month, dt.day)))
        return true;
      else
        return false;
    }

    return false;
  }
}

class BucketOffpeak extends Bucket {
  final String name = 'Offpeak';
  Location location;
  Calendar calendar = new NercCalendar();

  BucketOffpeak(Location this.location);

  bool containsHourBeginning(TZDateTime dt) {
    if (dt.location != location)
      throw new ArgumentError('dt location doesn\'t match iso location');
    int dayOfWeek = dt.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (dt.hour < 7 || dt.hour == 23)
        return true;
      if (calendar.isHoliday(new Date(dt.year, dt.month, dt.day)))
        return true;
    }

    return false;
  }
}