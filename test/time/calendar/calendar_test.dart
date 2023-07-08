library calendar_test;

import 'package:elec/elec.dart';
import 'package:elec/time.dart';
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
      var calendar = Calendar.nerc;
      expect(
          calendar.firstBusinessDate(Month.utc(2019, 9)), Date.utc(2019, 9, 3));
      expect(
          calendar.firstBusinessDate(Month.utc(2020, 1)), Date.utc(2020, 1, 2));
      expect(
          calendar.firstBusinessDate(Month.utc(2020, 2)), Date.utc(2020, 2, 3));
    });

    test('NERC Calendar', () {

      var days = [
        //
        (year: 2018, month: 1, day: 1),
        (year: 2018, month: 5, day: 28),
        (year: 2018, month: 7, day: 4),
        (year: 2018, month: 9, day: 3),
        (year: 2018, month: 11, day: 22),
        (year: 2018, month: 12, day: 25),
        //
        (year: 2021, month: 1, day: 1),
        (year: 2021, month: 5, day: 31),
        (year: 2021, month: 7, day: 5),
        (year: 2021, month: 9, day: 6),
        (year: 2021, month: 11, day: 25),
        (year: 2021, month: 12, day: 25),
        //
        (year: 2022, month: 1, day: 1),
        (year: 2022, month: 5, day: 30),
        (year: 2022, month: 7, day: 4),
        (year: 2022, month: 9, day: 5),
        (year: 2022, month: 11, day: 24),
        (year: 2022, month: 12, day: 26),
        //
        (year: 2023, month: 1, day: 2),
        (year: 2023, month: 5, day: 29),
        (year: 2023, month: 7, day: 4),
        (year: 2023, month: 9, day: 4),
        (year: 2023, month: 11, day: 23),
        (year: 2023, month: 12, day: 25),
        //
        (year: 2027, month: 1, day: 1),
        (year: 2027, month: 5, day: 31),
        (year: 2027, month: 7, day: 5),
        (year: 2027, month: 9, day: 6),
        (year: 2027, month: 11, day: 25),
        (year: 2027, month: 12, day: 25),
      ];
      expect(Calendar.nerc.isHoliday3(2023, 1, 1), false);
      for (var date in days) {
        expect(Calendar.nerc.isHoliday3(date.year, date.month, date.day), true);
        // expect(Calendar.nerc.isHoliday(Date.utc(date.year, date.month, date.day)), true);
      }
    });

    test('NERC Holidays 2018', () {
      var calendar = Calendar.nerc;
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
      expect(calendar.isHoliday(Date.utc(2022, 11, 8)), true); // mid-term
      expect(calendar.isHoliday(Date.utc(2020, 11, 3)), true); // presidential
    });
  });
}

/// See how fast isHoliday(date) is.
/// For 10 years repeated 25 times it takes:
///  - 33 ms without caching.
/// FWIW: A Rust implementation takes 4 ms.
void speedTest() {
  var location = getLocation('America/New_York');
  var term = Term.parse('Jan21-Dec30', location);
  var calendar = NercCalendar();
  var count = 0;
  var days = term.days();
  var sw = Stopwatch()..start();
  for (var i = 0; i < 25; i++) {
    for (var date in days) {
      // if (calendar.isHoliday3(date.year, date.month, date.day)) {
      if (calendar.isHoliday(date)) {
      //   print(date);
        count++;
      }
    }
  }
  sw.stop();
  print('Time spent: ${sw.elapsedMilliseconds} millis');
  print('Count of holidays: $count');
  assert(count == 1500);
}

void main() {
  initializeTimeZones();
  // tests();
  speedTest();
}
