import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

/// Election Day. See https://en.wikipedia.org/wiki/Election_Day_(United_States)
/// Set on 1st Tuesday after November 1st.  It is a state holiday in RI (on
/// even years only!).
class ElectionDay implements Holiday {
  @override
  HolidayType holidayType = HolidayType.electionDay;

  @override
  Date forYear(int year, {required Location location}) {
    var candidate = makeHoliday(year, 11, 1, DateTime.tuesday, location: location);
    if (candidate.day == 1) {
      candidate = candidate.add(7);
    }
    return candidate;
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;

}
