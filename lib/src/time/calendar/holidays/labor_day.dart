import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Labor Day is a Federal holiday (and a NERC holiday).
class LaborDay implements Holiday {
  HolidayType holidayType = HolidayType.laborDay;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, DateTime.SEPTEMBER, 1, DateTime.MONDAY,
        location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;
}
