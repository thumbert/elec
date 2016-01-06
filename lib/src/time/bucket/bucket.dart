library elec.bucket;

import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/iso/iso.dart';

abstract class Bucket {
  Calendar calendar;
  String name;
  Iso iso;

  /**
   * Is this hour in the bucket?
   */
  bool containsHour(Hour hour);
}


class Bucket7x24 extends Bucket {
  final String name = '7x24';
  Location location;

  Bucket7x24(Location this.location);

  bool containsHour(Hour hour) => true;
}

class Bucket7x8 extends Bucket {
  final String name = '7x8';
  Location location;
  Calendar calendar = new NercCalendar();

  Bucket7x8(Location this.location);

  bool containsHour(Hour hour) {
    if (hour.start.location != location)
      throw new ArgumentError('Hour location doesn\'t match Iso location');
    if (hour.start.hour <= 6 || hour.start.hour == 23)
      return true;

    return false;
  }
}

class Bucket5x16 extends Bucket {
  final String name = '5x16';
  Location location;
  Calendar calendar = new NercCalendar();

  Bucket5x16(Location this.location);

  bool containsHour(Hour hour) {
    if (hour.start.location != location)
      throw new ArgumentError('Hour location doesn\'t match iso location');
    int dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour < 7 || hour.start.hour == 23) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday(hour.currentDate))
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

  bool containsHour(Hour hour) {
    if (hour.start.location != location)
      throw new ArgumentError('Hour location doesn\'t match iso location');
    int dayOfWeek = hour.currentDate.weekday;
    if (hour.start.hour < 7 || hour.start.hour == 23)
      return false;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (calendar.isHoliday(hour.currentDate))
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

  bool containsHour(Hour hour) {
    if (hour.start.location != location)
      throw new ArgumentError('Hour location doesn\'t match Iso location');
    int dayOfWeek = hour.start.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (hour.start.hour < 7 || hour.start.hour == 23)
        return true;
      if (calendar.isHoliday(hour.currentDate))
        return true;
    }

    return false;
  }
}