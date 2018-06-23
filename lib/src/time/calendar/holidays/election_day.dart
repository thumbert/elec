import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Election Day. See https://en.wikipedia.org/wiki/Election_Day_(United_States)
/// Set on 1st Tuesday after November 1st.
class ElectionDay implements Holiday {
  HolidayType holidayType = HolidayType.electionDay;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, 11, 1, DateTime.TUESDAY, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;

}
