import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';

/// Lincoln's Birthday.  It's a state holiday in CT.  If it falls on Sun
/// it gets observed on the following Monday.
/// For example it was observed on Mon 2/13/2017.
class LincolnBirthday implements Holiday {
  HolidayType holidayType = HolidayType.lincolnBirthday;

  /// Get Lincoln's birthday for this year
  Date forYear(int year, {Location location}) {
    var candidate = new Date(year, 2, 12, location: location);
    if (candidate.weekday == 7) candidate = candidate.add(1);
    if (candidate.weekday == 6) candidate = candidate.subtract(1);
    return candidate;
  }

  bool isDate(Date date) =>
    this.forYear(date.year, location: date.location) == date;

}


