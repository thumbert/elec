library calendar_test;

import 'package:elec/elec.dart';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec/src/time/calendar/calendars/federal_holidays_calendar.dart';
import 'package:elec/src/time/calendar/calendars/ct_state_holiday_calendar.dart';
import 'package:elec/src/time/calendar/calendars/ri_state_holiday_calendar.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Test calendar', () {
    test('first business day of the month', () {
      var calendar = NercCalendar();
      expect(
          calendar.firstBusinessDate(Month.utc(2019, 9)), Date.utc(2019, 9, 3));
      expect(
          calendar.firstBusinessDate(Month.utc(2020, 1)), Date.utc(2020, 1, 2));
      expect(
          calendar.firstBusinessDate(Month.utc(2020, 2)), Date.utc(2020, 2, 3));
    });

    test('NERC Holidays 2018', () {
      var calendar = NercCalendar();
      expect(calendar.isHoliday(Date.utc(2018, 1, 1)), true);
      expect(
          calendar.getHolidayType(Date.utc(2018, 1, 1)), HolidayType.newYear);
      expect(calendar.isHoliday(Date.utc(2018, 5, 28)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 5, 28)),
          HolidayType.memorialDay);
      expect(calendar.isHoliday(Date.utc(2018, 7, 4)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 7, 4)),
          HolidayType.independenceDay);
      expect(calendar.isHoliday(Date.utc(2018, 9, 3)), true);
      expect(
          calendar.getHolidayType(Date.utc(2018, 9, 3)), HolidayType.laborDay);
      expect(calendar.isHoliday(Date.utc(2018, 11, 22)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 11, 22)),
          HolidayType.thanksgiving);
      expect(calendar.isHoliday(Date.utc(2018, 12, 25)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 12, 25)),
          HolidayType.christmas);
    });

    test('Federal Holidays 2018', () {
      var calendar = FederalHolidaysCalendar();
      expect(calendar.isHoliday(Date.utc(2018, 1, 1)), true);
      expect(
          calendar.getHolidayType(Date.utc(2018, 1, 1)), HolidayType.newYear);
      expect(calendar.isHoliday(Date.utc(2018, 1, 15)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 1, 15)),
          HolidayType.mlkBirthday);
      expect(calendar.isHoliday(Date.utc(2018, 2, 19)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 2, 19)),
          HolidayType.washingtonBirthday);
      expect(calendar.isHoliday(Date.utc(2018, 5, 28)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 5, 28)),
          HolidayType.memorialDay);
      expect(calendar.isHoliday(Date.utc(2018, 7, 4)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 7, 4)),
          HolidayType.independenceDay);
      expect(calendar.isHoliday(Date.utc(2018, 9, 3)), true);
      expect(
          calendar.getHolidayType(Date.utc(2018, 9, 3)), HolidayType.laborDay);
      expect(calendar.isHoliday(Date.utc(2018, 11, 22)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 10, 8)),
          HolidayType.columbusDay);
      expect(calendar.isHoliday(Date.utc(2018, 10, 8)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 11, 12)),
          HolidayType.veteransDay);
      expect(calendar.isHoliday(Date.utc(2018, 11, 12)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 11, 22)),
          HolidayType.thanksgiving);
      expect(calendar.isHoliday(Date.utc(2018, 12, 25)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 12, 25)),
          HolidayType.christmas);
    });

    test('CT State Holidays 2011', () {
      var calendar = CtStateHolidayCalendar();
      expect(calendar.isHoliday(Date.utc(2011, 2, 11)), true);
      expect(calendar.getHolidayType(Date.utc(2011, 2, 11)),
          HolidayType.lincolnBirthday);
      expect(calendar.isHoliday(Date.utc(2011, 4, 22)), true);
      expect(calendar.getHolidayType(Date.utc(2011, 4, 22)),
          HolidayType.goodFriday);
    });

    test('RI State Holidays 2018', () {
      var calendar = RiStateHolidayCalendar();
      expect(calendar.isHoliday(Date.utc(2018, 11, 6)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 11, 6)),
          HolidayType.electionDay);
      expect(calendar.isHoliday(Date.utc(2018, 8, 13)), true);
      expect(calendar.getHolidayType(Date.utc(2018, 8, 13)),
          HolidayType.victoryDay);
    });
  });
}

/// See how fast isHoliday(date) is.
/// For 10 years repeated 24 times it takes:
///  - 80 ms without caching
///  - 32 ms with LRU Map caching
///  - 32 ms with a regular Map
///  -  4 ms just iterating
void speedTest() {
  var location = getLocation('America/New_York');
  var term = Term.parse('Jan21-Dec30', location);
  var calendar = NercCalendar();
  var count = 0;
  var days = term.days();
  var sw = Stopwatch()..start();
  for (var i = 0; i < 24; i++) {
    for (var date in days) {
      if (calendar.isHoliday(date)) {
        count++;
      }
    }
  }
  sw.stop();
  print(sw.elapsedMilliseconds);
  print(count);
}

void main() {
  initializeTimeZones();
  // tests();
  speedTest();
}
