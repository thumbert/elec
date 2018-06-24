import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../holidays/victory_day.dart';
import '../holidays/election_day.dart';
import 'federal_holidays_calendar.dart';


/// RI has Victory Day and Election Day in addition to the
/// 10 Federal holidays.
class RiStateHolidayCalendar extends Calendar {
  static final _federalCalendar = new FederalHolidaysCalendar();
  static final Holiday _victoryDay = new VictoryDay();
  static final Holiday _electionDay = new ElectionDay();

  HolidayType _holidayType;

  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date))
      throw new ArgumentError('$date is not a RI State holiday');
    return _holidayType;
  }

  bool isHoliday(Date date) {
    bool res = false;
    if (_federalCalendar.isHoliday(date)) {
      _holidayType = _federalCalendar.getHolidayType(date);
      return true;
    }

    if (date.month == 8) {
      if (_victoryDay.isDate(date)) {
        res = true;
        _holidayType = HolidayType.victoryDay;
      }
    /// Election Day on even years only!
    } else if (date.month == 11 && date.year % 2 == 0) {

      if (_electionDay.isDate(date)) {
        res = true;
        _holidayType = HolidayType.electionDay;
      }
    }
    return res;
  }

}


