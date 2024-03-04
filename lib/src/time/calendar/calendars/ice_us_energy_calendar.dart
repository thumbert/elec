library time.calendar.calendars.federal_holiday_calendar;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../calendar.dart';

///
class IceUsEnergyHolidaysCalendar extends Calendar {
  final holidays = <Holiday>{
    Holiday.newYear,
    Holiday.goodFriday,
    Holiday.christmas,
  };

  @override
  HolidayType getHolidayType(Date date) {
    switch (date.month) {
      case 1:
        if (Holiday.newYear.isDate3(date.year, date.month, date.day)) {
          return HolidayType.newYear;
        }
        break;
      case 3:
        if (Holiday.goodFriday.isDate3(date.year, date.month, date.day)) {
          return HolidayType.goodFriday;
        }
        break;
      case 4:
        if (Holiday.goodFriday.isDate3(date.year, date.month, date.day)) {
          return HolidayType.goodFriday;
        }
        break;
      case 12:
        if (Holiday.christmas.isDate3(date.year, date.month, date.day)) {
          return HolidayType.christmas;
        }
        break;
    }
    return throw ArgumentError('$date is not a ICE US Energy holiday');
  }

  @override
  bool isHoliday(Date date) => isHoliday3(date.year, date.month, date.day);

  @override
  bool isHoliday3(int year, int month, int day) {
    return switch (month) {
      1 => Holiday.newYear.isDate3(year, month, day) ? true : false,
      3 => Holiday.goodFriday.isDate3(year, month, day) ? true : false,
      4 => Holiday.goodFriday.isDate3(year, month, day) ? true : false,
      12 => Holiday.christmas.isDate3(year, month, day) ? true : false,
      _ => false,
    };
  }
}
