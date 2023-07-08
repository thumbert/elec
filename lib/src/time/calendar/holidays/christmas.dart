import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import '../holiday.dart';

/// Christmas eve is a federal holiday.  If it falls on a Sun, it gets observed
/// on the following Monday.
class Christmas extends Holiday {
  Christmas() {
    holidayType = HolidayType.christmas;
  }

  @override
  Date forYear(int year, {required Location location}) {
    var candidate = Date(year, 12, 25, location: location);
    /// If it falls on Sun, celebrate it on Monday
    if (candidate.weekday == 7) candidate = candidate.add(1);
    return candidate;
  }

  @Deprecated('Replace with isDate3')
  @override
  bool isDate(Date date) =>
      date == forYear(date.year, location: date.location);
  
  bool isDate3(int year, int month, int day) {
    if (month != 12) return false;
    if (day != 25 && day != 26) return false;
    var weekday = DateTime(year, 12, 25).weekday;
    if (weekday == 7 && day == 26) return true;
    if (weekday != 7 && day == 25) return true;
    return false;
  }

}
