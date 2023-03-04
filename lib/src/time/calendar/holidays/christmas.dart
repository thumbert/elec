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

  @override
  bool isDate(Date date) =>
      date == forYear(date.year, location: date.location);
}
