import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';

/// Memorial Day is a Federal holiday (and a NERC holiday).
/// Falls on the last Monday in May.
class MemorialDay extends Holiday {
  MemorialDay() {
    holidayType = HolidayType.memorialDay;
  }

  @override
  Date forYear(int year, {required Location location}) {
    var wday = Date.utc(year, 5, 31).weekday;
    return Date(year, 5, 32-wday, location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;
}
