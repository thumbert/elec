import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Martin Luther King's birthday is a Federal holiday (not a NERC holiday).
/// Falls on the 3rd Monday in Jan.
class MlkBirthday implements Holiday {
  HolidayType holidayType = HolidayType.mlkBirthday;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, 1, 3, DateTime.monday, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;
}
