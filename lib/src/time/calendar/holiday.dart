library holiday;

import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

enum HolidayType {
  christmas,
  columbusDay,
  dayAfterThanksgiving,
  electionDay,
  goodFriday,
  independenceDay,
  laborDay,
  lincolnBirthday,
  memorialDay,
  mlkBirthday,
  newYear,
  patriotsDay,
  thanksgiving,
  veteransDay,
  victoryDay,
  washingtonBirthday,
}

abstract class Holiday {
  HolidayType holidayType;
  Date forYear(int year, {Location location});
  bool isDate(Date date);
}

