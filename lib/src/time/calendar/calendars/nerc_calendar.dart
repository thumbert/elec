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
class NercCalendar extends Calendar {
  static final Holiday _newYear = NewYear();
  static final Holiday _memorialDay = MemorialDay();
  static final Holiday _independenceDay = IndependenceDay();
  static final Holiday _laborDay = LaborDay();
  static final Holiday _thanksgiving = Thanksgiving();
  static final Holiday _christmas = Christmas();

  HolidayType _holidayType;

  @override
  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date)) {
      throw ArgumentError('$date is not a NERC holiday');
    }
    return _holidayType;
  }

  @override
  bool isHoliday(Date date) {
    var res = false;
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
