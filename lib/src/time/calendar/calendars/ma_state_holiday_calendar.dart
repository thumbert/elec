import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';


/// Massachusetts has Patriots' Day in addition to the
/// 10 Federal holidays.
class MaStateHolidayCalendar extends Calendar {
  late HolidayType _holidayType;

  @override
  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date)) {
      throw ArgumentError('$date is not a MA State holiday');
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

    if (date.month == 4) {
      if (Holiday.patriotsDay.isDate(date)) {
        res = true;
        _holidayType = HolidayType.patriotsDay;
      }
    }
    return res;
  }
}


