import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';

/// Connecticut has Lincoln's Birthday, Good Friday
class CtHolidayCalendar extends Calendar {

  bool isHoliday(Date date) {

  }

}

class LincolnBirthday {
  /// Get Lincoln's birthday for this year
  static Date forYear(int year) {
    return new Date(year, 2, 14);
  }
  static bool isDate(Date date) {
    var candidate = LincolnBirthday.forYear(date.year);
    return candidate.value == date.value;
  }
}

