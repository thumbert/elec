library time.calendar.calendars.federal_holiday_calendar;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../calendar.dart';

/// Federal holidays calendar (10 holidays).  NERC calendar + another 4 ones.
/// http://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
/// In 2021, Jun 19th was added as a Federal holiday by president Biden.
///
class FederalHolidaysCalendar extends Calendar {
  // All Federal holidays
  static final holidays = <Holiday>{
    ...NercCalendar.holidays,
    Holiday.mlkBirthday,
    Holiday.washingtonBirthday,
    Holiday.juneteenth,
    Holiday.columbusDay,
    Holiday.veteransDay,
  };

  @override
  HolidayType getHolidayType(Date date) {
    if (Calendar.nerc.isHoliday3(date.year, date.month, date.day)) {
      return Calendar.nerc.getHolidayType(date);
    }

    switch (date.month) {
      case 1:
        if (Holiday.mlkBirthday.isDate(date)) {
          return HolidayType.mlkBirthday;
        }
        break;
      case 2:
        if (Holiday.washingtonBirthday.isDate(date)) {
          return HolidayType.washingtonBirthday;
        }
        break;
      case 6:
        if (date.year >= 2021 && Holiday.juneteenth.isDate(date)) {
          return HolidayType.juneteenth;
        }
        break;
      case 10:
        if (Holiday.columbusDay.isDate(date)) {
          return HolidayType.columbusDay;
        }
        break;
      case 11:
        if (Holiday.veteransDay.isDate(date)) {
          return HolidayType.veteransDay;
        }
        break;
    }
    return throw ArgumentError('$date is not a Federal holiday');
  }

  @override
  bool isHoliday(Date date) => isHoliday3(date.year, date.month, date.day);

  @override
  bool isHoliday3(int year, int month, int day) {
    if (Calendar.nerc.isHoliday3(year, month, day)) {
      return true;
    }
    return switch (month) {
      1 => Holiday.mlkBirthday.isDate3(year, month, day) ? true : false,
      2 => Holiday.washingtonBirthday.isDate3(year, month, day) ? true : false,
      6 => Holiday.juneteenth.isDate3(year, month, day) ? true : false,
      10 => Holiday.columbusDay.isDate3(year, month, day) ? true : false,
      11 => Holiday.veteransDay.isDate3(year, month, day) ? true : false,
      _ => false,
    };
  }
}
