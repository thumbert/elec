import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';


/// Connecticut has Lincoln's Birthday, Good Friday in addition to the
/// Federal holidays.
class CtStateHolidayCalendar extends Calendar {
  late HolidayType _holidayType;

  @override
  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date)) {
      throw ArgumentError('$date is not a CT State holiday');
    }
    return _holidayType;
  }

  @override
  bool isHoliday(Date date) {
    var res = false;
    if (Calendar.federalHolidays.isHoliday(date)) {
      _holidayType = Calendar.federalHolidays.getHolidayType(date);
      return true;
    }

    if (date.month == 2) {
      if (Holiday.lincolnBirthday.isDate(date)) {
        res = true;
        _holidayType = HolidayType.lincolnBirthday;
      }

    } else if (date.month == 3 || date.month == 4) {
      if (Holiday.goodFriday.isDate(date)) {
        res = true;
        _holidayType = HolidayType.goodFriday;
      }
    }
    return res;
  }
}


