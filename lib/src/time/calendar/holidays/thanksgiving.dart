import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

/// Thanksgiving is a Federal holiday (and a NERC holiday).
/// Falls on the 4th Thursday in Nov.
class Thanksgiving extends Holiday {
  Thanksgiving() {
    holidayType = HolidayType.thanksgiving;
  }

  @override
  Date forYear(int year, {required Location location}) {
    return makeHoliday(year, 11, 4, DateTime.thursday, location: location);
  }


  @override
  bool isDate(Date date) => isDate3(date.year, date.month, date.day);

  @override
  bool isDate3(int year, int month, int day) {
    if (month != 11) return false;
    if (day < 22 || day > 28) return false;
    var dayOfMonth = dayOfMonthHoliday(year, 11, 4, DateTime.thursday);
    if (dayOfMonth == day) return true;
    return false;
  }
}
