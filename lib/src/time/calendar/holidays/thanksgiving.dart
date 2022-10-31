import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

/// Thanksgiving is a Federal holiday (and a NERC holiday).
/// Falls on the 4th Thursday in Nov.
class Thanksgiving implements Holiday {
  @override
  HolidayType holidayType = HolidayType.thanksgiving;

  @override
  Date forYear(int year, {required Location location}) {
    return makeHoliday(year, 11, 4, DateTime.thursday, location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;
}
