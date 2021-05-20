import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import '../holiday.dart';

/// New Year eve is a federal holiday.  If it falls on a Sun, it gets observed
/// on the following Monday.
class NewYear implements Holiday {
  @override
  HolidayType holidayType = HolidayType.newYear;

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
}
