import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Patriots' Day. See https://en.wikipedia.org/wiki/Election_Day_(United_States)
/// Set on 3rd Monday in April.  It's a state holiday in MA and ME.
class PatriotsDay implements Holiday {
  HolidayType holidayType = HolidayType.patriotsDay;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, 4, 3, DateTime.monday, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;

}
