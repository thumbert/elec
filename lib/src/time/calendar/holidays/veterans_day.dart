import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';

/// Veterans Day is a Federal holiday.
class VeteransDay implements Holiday {
  HolidayType holidayType = HolidayType.veteransDay;

  Date forYear(int year, {Location location}) {
    var candidate = new Date(year, 11, 11, location: location);
    // if it falls on Sunday, it gets observed on Monday
    if (candidate.weekday == 7) candidate = candidate.add(1);
    // if it falls on Saturday, it is observed on Friday
    if (candidate.weekday == 6) candidate = candidate.subtract(1);

    return candidate;
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;
}
