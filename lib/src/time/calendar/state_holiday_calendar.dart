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
    var candidate = new Date(year, 2, 12);
    if (candidate.weekday == 7)
      candidate = candidate.add(1);
    return candidate;
  }
  static bool isDate(Date date) {
    var candidate = LincolnBirthday.forYear(date.year);
    return candidate.value == date.value;
  }
}

