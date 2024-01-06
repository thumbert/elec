import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import '../holiday.dart';

class IndependenceDay extends Holiday {
  /// Independence day is a federal holiday.  If it falls on a Sun, it gets observed
  /// on the following Monday.
  IndependenceDay() {
    holidayType = HolidayType.independenceDay;
  }

  @override
  Date forYear(int year, {required Location location}) {
    var candidate = Date(year, 7, 4, location: location);

    /// If it falls on Sun, celebrate it on Monday
    if (candidate.weekday == 7) candidate = candidate.add(1);

    /// What happens if it falls on a Sat??  Apparently nothing
    /// In 2020, 4th Jul fell on Sat, was publicly celebrated on the 3rd
    /// but NERC kept it on the 4th and didn't move it to the 3rd.  Not
    /// sure this will always be the case.
    /// Keep an eye on this.  Will happen again in 2026!
    ///

    return candidate;
  }

  @override
  bool isDate(Date date) => date == forYear(date.year, location: date.location);

  @override
  bool isDate3(int year, int month, int day) {
    if (month != 7) return false;
    if (day != 4 && day != 5) return false;
    var weekday = DateTime(year, 7, 4).weekday;
    if (weekday == 7 && day == 5) return true;
    if (weekday != 7 && day == 4) return true;
    return false;
  }
}
