import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';

/// Veterans Day is a Federal holiday.
class VeteransDay implements Holiday {
  @override
  HolidayType holidayType = HolidayType.veteransDay;

  @override
  Date forYear(int year, {required Location location}) {
    var candidate = Date(year, 11, 11, location: location);
    // if it falls on Sunday, it gets observed on Monday
    if (candidate.weekday == 7) candidate = candidate.add(1);
    // if it falls on Saturday, it is observed on Friday
    if (candidate.weekday == 6) candidate = candidate.subtract(1);

    return candidate;
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;
}
