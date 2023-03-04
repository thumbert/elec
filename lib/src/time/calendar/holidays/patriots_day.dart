import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

class PatriotsDay extends Holiday {
  /// Patriots' Day. See https://en.wikipedia.org/wiki/Election_Day_(United_States)
  /// Set on 3rd Monday in April.  It's a state holiday in MA and ME.
  PatriotsDay() {
    holidayType = HolidayType.patriotsDay;
  }

  @override
  Date forYear(int year, {required Location location}) {
    return makeHoliday(year, 4, 3, DateTime.monday, location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;

}
