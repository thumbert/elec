library time.calendar;

import 'package:date/date.dart';
import 'holiday.dart';


/// A holiday calendar
abstract class Calendar {
  bool isHoliday(Date date);
  HolidayType getHolidayType(Date date);

  /// Get the first business day of this month for this calendar.
  Date firstBusinessDate(Month month) {
    var candidate = month.startDate;
    while (candidate.isWeekend() || isHoliday(candidate)) {
      candidate = candidate.next;
    }
    return candidate;
  }
}

