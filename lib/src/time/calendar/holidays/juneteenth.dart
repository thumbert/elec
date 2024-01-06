import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import '../holiday.dart';

/// Independence day is a federal holiday.
class Juneteenth extends Holiday {
  Juneteenth() {
    holidayType = HolidayType.juneteenth;
  }

  @override

  /// Before 2021-06-19, this function will return null as the holiday
  /// didn't exist
  Date? forYear(int year, {required Location location}) {
    // holiday started being observed in 2021
    if (year < 2021) return null;

    var candidate = Date(year, 6, 19, location: location);

    /// If it falls on Sat, celebrate it on Fri
    if (candidate.weekday == 6) candidate = candidate.subtract(1);

    /// If it falls on Sun, celebrate it on Mon
    if (candidate.weekday == 7) candidate = candidate.add(1);
    return candidate;
  }

  @override
  bool isDate(Date date) => date == forYear(date.year, location: date.location);
}
