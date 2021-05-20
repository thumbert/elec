import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Labor Day is a Federal holiday (and a NERC holiday).
class LaborDay implements Holiday {
  @override
  HolidayType holidayType = HolidayType.laborDay;

  @override
  Date forYear(int year, {required Location location}) {
    return makeHoliday(year, DateTime.september, 1, DateTime.monday,
        location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;
}
