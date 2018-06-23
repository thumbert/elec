import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Thanksgiving is a Federal holiday (and a NERC holiday).
/// Falls on the 4th Thursday in Nov.
class Thanksgiving implements Holiday {
  HolidayType holidayType = HolidayType.thanksgiving;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, 11, 4, DateTime.THURSDAY, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;
}
