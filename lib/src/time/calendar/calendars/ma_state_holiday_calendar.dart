import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../holidays/patriots_day.dart';
import 'federal_holidays_calendar.dart';


/// Massachussetts has Patriots' Day in addition to the
/// 10 Federal holidays.
class MaStateHolidayCalendar extends Calendar {
  static final _federalCalendar = new FederalHolidaysCalendar();
  static final Holiday _patriotsDay = new PatriotsDay();

  HolidayType _holidayType;

  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date))
      throw new ArgumentError('$date is not a CT State holiday');
    return _holidayType;
  }

  bool isHoliday(Date date) {
    bool res = false;
    if (_federalCalendar.isHoliday(date)) {
      _holidayType = _federalCalendar.getHolidayType(date);
      return true;
    }

    if (date.month == 4) {
      if (_patriotsDay.isDate(date)) {
        res = true;
        _holidayType = HolidayType.patriotsDay;
      }
    }
    return res;
  }

}


