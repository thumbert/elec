library time.calendar;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendars/federal_holidays_calendar.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'holiday.dart';

/// A holiday calendar
abstract class Calendar {
  static final federalHolidays = FederalHolidaysCalendar();
  static final nerc = NercCalendar();

  bool isHoliday3(int year, int month, int day);
  bool isHoliday(Date date);
  HolidayType getHolidayType(Date date);

  /// Get the first business day of this month for this calendar.
  @Deprecated('Use firstBusinessDateFrom instead')
  Date firstBusinessDate(Month month) {
    var candidate = month.startDate;
    while (candidate.isWeekend() || isHoliday(candidate)) {
      candidate = candidate.next;
    }
    return candidate;
  }

  bool isBusinessDate(Date date) => !date.isWeekend() && !isHoliday(date);
  
  /// Return the first business date that comes *after* [date].
  Date firstBusinessDateFrom(Date date) {
    var candidate = date.next;
    while (candidate.isWeekend() || isHoliday(candidate)) {
      candidate = candidate.next;
    }
    return candidate;
  }

  /// Return the last business date that comes *before* [date]
  Date lastBusinessDateFrom(Date date) {
    var candidate = date.previous;
    while (candidate.isWeekend() || isHoliday(candidate)) {
      candidate = candidate.previous;
    }
    return candidate;
  }
}
