library time.calendar.calendars.federal_holiday_calendar;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../holidays/mlk_birthday.dart';
import '../holidays/washington_birthday.dart';
import '../holidays/columbus_day.dart';
import '../holidays/veterans_day.dart';
import '../calendar.dart';
import 'nerc_calendar.dart';

/// Federal holidays calendar (10 holidays).  NERC calendar + another 4 ones.
/// http://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
class FederalHolidaysCalendar extends Calendar {
  static final _nercCalendar = NercCalendar();
  static final Holiday _mlk = MlkBirthday();
  static final Holiday _washingtonBirthday = WashingtonBirthday();
  static final Holiday _columbus = ColumbusDay();
  static final Holiday _veterans = VeteransDay();

  HolidayType _holidayType;

  @override
  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date)) {
      throw ArgumentError('$date is not a Federal holiday');
    }
    return _holidayType;
  }

  @override
  bool isHoliday(Date date) {
    var res = false;
    if (_nercCalendar.isHoliday(date)) {
      _holidayType = _nercCalendar.getHolidayType(date);
      return true;
    }
    switch (date.month) {
      case 1:
        if (_mlk.isDate(date)) {
          res = true;
          _holidayType = HolidayType.mlkBirthday;
        }
        break;
      case 2:
        if (_washingtonBirthday.isDate(date)) {
          res = true;
          _holidayType = HolidayType.washingtonBirthday;
        }
        break;
      case 10:
        if (_columbus.isDate(date)) {
          res = true;
          _holidayType = HolidayType.columbusDay;
        }
        break;
      case 11:
        if (_veterans.isDate(date)) {
          res = true;
          _holidayType = HolidayType.veteransDay;
        }
        break;
      default:
        return false;
    }
    return res;
  }

}