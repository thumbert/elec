import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Columbus Day.  It's a federal holiday.
/// Is celebrated on the 2rd Monday in October (since 1971).
class ColumbusDay implements Holiday {
  HolidayType holidayType = HolidayType.columbusDay;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, 10, 2, DateTime.MONDAY, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;

}
