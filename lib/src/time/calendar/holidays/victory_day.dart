import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Victory Day. See https://en.wikipedia.org/wiki/Victory_Day
/// Set on 2nd Monday of August.  It is a state holiday in RI.
class VictoryDay implements Holiday {
  HolidayType holidayType = HolidayType.victoryDay;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, 8, 2, DateTime.monday, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;

}
