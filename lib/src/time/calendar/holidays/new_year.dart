import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import '../holiday.dart';

class NewYear extends Holiday {
  /// New Year eve is a federal holiday.  If it falls on a Sun, it gets observed
  /// on the following Monday.
  NewYear() {
    holidayType = HolidayType.newYear;
  }

  @override
  Date forYear(int year, {required Location location}) {
    var candidate = Date(year, 1, 1, location: location);

    /// If it falls on Sun, celebrate it on Monday
    if (candidate.weekday == 7) candidate = candidate.add(1);
    return candidate;
  }

  @override
  bool isDate(Date date) =>
      date == forYear(date.year, location: date.location);

  bool isDate3(int year, int month, int day) {
    if (month != 1 || day > 2) return false;
    var weekday = DateTime(year).weekday;
    if (weekday == 7 && day == 2) return true;
    if (weekday != 7 && day == 1) return true;
    return false;
  }

}
