import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

class MlkBirthday extends Holiday {
  /// Martin Luther King's birthday is a Federal holiday (not a NERC holiday).
  /// Falls on the 3rd Monday in Jan.
  MlkBirthday() {
    holidayType = HolidayType.mlkBirthday;
  }

  @override
  Date forYear(int year, {required Location location}) {
    return makeHoliday(year, 1, 3, DateTime.monday, location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;
}
