import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

class LaborDay extends Holiday {
  /// Labor Day is a Federal holiday (and a NERC holiday).
  LaborDay() {
    holidayType = HolidayType.laborDay;
  }

  @override
  Date forYear(int year, {required Location location}) {
    return makeHoliday(year, DateTime.september, 1, DateTime.monday,
        location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;

  @override
  bool isDate3(int year, int month, int day) {
    if (month != 9 || day > 7) return false;
    var dayOfMonth = dayOfMonthHoliday(year, 9, 1, DateTime.monday);
    if (dayOfMonth == day) return true;
    return false;
  }
}
