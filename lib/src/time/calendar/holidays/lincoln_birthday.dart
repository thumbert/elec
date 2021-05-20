import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';

/// Lincoln's Birthday.  It's a state holiday in CT.  If it falls on Sun
/// it gets observed on the following Monday.
/// For example it was observed on Mon 2/13/2017.
class LincolnBirthday implements Holiday {
  @override
  HolidayType holidayType = HolidayType.lincolnBirthday;

  /// Get Lincoln's birthday for this year
  @override
  Date forYear(int year, {required Location location}) {
    var candidate = Date(year, 2, 12, location: location);
    if (candidate.weekday == 7) candidate = candidate.add(1);
    if (candidate.weekday == 6) candidate = candidate.subtract(1);
    return candidate;
  }

  @override
  bool isDate(Date date) =>
    forYear(date.year, location: date.location) == date;

}


