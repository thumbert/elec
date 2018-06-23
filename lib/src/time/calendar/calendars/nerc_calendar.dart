import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../holidays/new_year.dart';
import '../holidays/memorial_day.dart';
import '../holidays/independence_day.dart';
import '../holidays/labor_day.dart';
import '../holidays/thanksgiving.dart';
import '../holidays/christmas.dart';
import '../calendar.dart';

/// NERC Calendar
class NercCalendar implements Calendar {
  static final Holiday _newYear = new NewYear();
  static final Holiday _memorialDay = new MemorialDay();
  static final Holiday _independenceDay = new IndependenceDay();
  static final Holiday _laborDay = new LaborDay();
  static final Holiday _thanksgiving = new Thanksgiving();
  static final Holiday _christmas = new Christmas();

  HolidayType _holidayType;

  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date))
      throw new ArgumentError('$date is not a NERC holiday');
    return _holidayType;
  }

  bool isHoliday(Date date) {
    bool res = false;
    switch (date.month) {
      case 1:
        if (_newYear.isDate(date)) res = true;
        _holidayType = HolidayType.newYear;
        break;
      case 5:
        if (_memorialDay.isDate(date)) res = true;
        _holidayType = HolidayType.memorialDay;
        break;
      case 7:
        if (_independenceDay.isDate(date)) res = true;
        _holidayType = HolidayType.independenceDay;
        break;
      case 9:
        if (_laborDay.isDate(date)) res = true;
        _holidayType = HolidayType.laborDay;
        break;
      case 11:
        if (_thanksgiving.isDate(date)) res = true;
        _holidayType = HolidayType.thanksgiving;
        break;
      case 12:
        if (_christmas.isDate(date)) res = true;
        _holidayType = HolidayType.christmas;
        break;
      default:
        return false;
    }
    return res;
  }
}
