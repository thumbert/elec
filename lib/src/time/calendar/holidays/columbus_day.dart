import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

/// Columbus Day.  It's a federal holiday.
/// Is celebrated on the 2rd Monday in October (since 1971).
class ColumbusDay implements Holiday {
  @override
  HolidayType holidayType = HolidayType.columbusDay;

  @override
  Date forYear(int year, {required Location location}) {
    return makeHoliday(year, 10, 2, DateTime.monday, location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;

}
