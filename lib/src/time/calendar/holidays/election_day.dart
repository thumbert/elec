import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Election Day. See https://en.wikipedia.org/wiki/Election_Day_(United_States)
/// Set on 1st Tuesday after November 1st.  It is a state holiday in RI (on
/// even years only!).
class ElectionDay implements Holiday {
  @override
  HolidayType holidayType = HolidayType.electionDay;

  @override
  Date forYear(int year, {Location/*!*/ location}) {
    return makeHoliday(year, 11, 1, DateTime.tuesday, location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;

}
