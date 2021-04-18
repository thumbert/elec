import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../holidays/lincoln_birthday.dart';
import '../holidays/good_friday.dart';
import 'federal_holidays_calendar.dart';


/// Connecticut has Lincoln's Birthday, Good Friday in addition to the
/// Federal holidays.
class CtStateHolidayCalendar extends Calendar {
  static final _federalCalendar = FederalHolidaysCalendar();
  static final Holiday _lincolnBirthday = LincolnBirthday();
  static final Holiday _goodFriday = GoodFriday();

  HolidayType _holidayType;

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
    if (_federalCalendar.isHoliday(date)) {
      _holidayType = _federalCalendar.getHolidayType(date);
      return true;
    }

    if (date.month == 2) {
      if (_lincolnBirthday.isDate(date)) {
        res = true;
        _holidayType = HolidayType.lincolnBirthday;
      }

    } else if (date.month == 3 || date.month == 4) {
      if (_goodFriday.isDate(date)) {
        res = true;
        _holidayType = HolidayType.goodFriday;
      }
    }
    return res;
  }

}


