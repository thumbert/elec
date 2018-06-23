import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';

/// Memorial Day is a Federal holiday (and a NERC holiday).
/// Falls on the last Monday in May.
class MemorialDay implements Holiday {
  HolidayType holidayType = HolidayType.memorialDay;

  Date forYear(int year, {Location location}) {
    int wday = new Date(year, 5, 31).weekday;
    return new Date(year, 5, 32-wday, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;
}
