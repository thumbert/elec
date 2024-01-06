import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';


/// RI has Victory Day and Election Day in addition to the
/// 10 Federal holidays.
class RiStateHolidayCalendar extends Calendar {
  late HolidayType _holidayType;

  @override
  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date)) {
      throw ArgumentError('$date is not a RI State holiday');
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

    if (date.month == 8) {
      if (Holiday.victoryDay.isDate(date)) {
        res = true;
        _holidayType = HolidayType.victoryDay;
      }
    /// Election Day on even years only!
    } else if (date.month == 11 && date.year % 2 == 0) {

      if (Holiday.electionDay.isDate(date)) {
        res = true;
        _holidayType = HolidayType.electionDay;
      }
    }
    return res;
  }
}


