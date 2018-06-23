library calendar_test;

import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec/src/time/calendar/calendars/federal_holidays_calendar.dart';
import 'package:elec/src/time/calendar/calendars/ct_state_holiday_calendar.dart';

calendarTests(){
  group('Test calendar', (){
    test('NERC Holidays 2018', (){
      var calendar = new NercCalendar();
      expect(calendar.isHoliday(new Date(2018, 1, 1)), true);
      expect(calendar.getHolidayType(new Date(2018, 1, 1)), HolidayType.newYear);
      expect(calendar.isHoliday(new Date(2018, 5, 28)), true);
      expect(calendar.getHolidayType(new Date(2018, 5, 28)), HolidayType.memorialDay);
      expect(calendar.isHoliday(new Date(2018, 7, 4)), true);
      expect(calendar.getHolidayType(new Date(2018, 7, 4)), HolidayType.independenceDay);
      expect(calendar.isHoliday(new Date(2018, 9, 3)), true);
      expect(calendar.getHolidayType(new Date(2018, 9, 3)), HolidayType.laborDay);
      expect(calendar.isHoliday(new Date(2018, 11, 22)), true);
      expect(calendar.getHolidayType(new Date(2018, 11, 22)), HolidayType.thanksgiving);
      expect(calendar.isHoliday(new Date(2018, 12, 25)), true);
      expect(calendar.getHolidayType(new Date(2018, 12, 25)), HolidayType.christmas);
    });

    test('Federal Holidays 2018', (){
      var calendar = new FederalHolidaysCalendar();
      expect(calendar.isHoliday(new Date(2018, 1, 1)), true);
      expect(calendar.getHolidayType(new Date(2018, 1, 1)), HolidayType.newYear);
      expect(calendar.isHoliday(new Date(2018, 1, 15)), true);
      expect(calendar.getHolidayType(new Date(2018, 1, 15)), HolidayType.mlkBirthday);
      expect(calendar.isHoliday(new Date(2018, 2, 19)), true);
      expect(calendar.getHolidayType(new Date(2018, 2, 19)), HolidayType.washingtonBirthday);
      expect(calendar.isHoliday(new Date(2018, 5, 28)), true);
      expect(calendar.getHolidayType(new Date(2018, 5, 28)), HolidayType.memorialDay);
      expect(calendar.isHoliday(new Date(2018, 7, 4)), true);
      expect(calendar.getHolidayType(new Date(2018, 7, 4)), HolidayType.independenceDay);
      expect(calendar.isHoliday(new Date(2018, 9, 3)), true);
      expect(calendar.getHolidayType(new Date(2018, 9, 3)), HolidayType.laborDay);
      expect(calendar.isHoliday(new Date(2018, 11, 22)), true);
      expect(calendar.getHolidayType(new Date(2018, 10, 8)), HolidayType.columbusDay);
      expect(calendar.isHoliday(new Date(2018, 10, 8)), true);
      expect(calendar.getHolidayType(new Date(2018, 11, 12)), HolidayType.veteransDay);
      expect(calendar.isHoliday(new Date(2018, 11, 12)), true);
      expect(calendar.getHolidayType(new Date(2018, 11, 22)), HolidayType.thanksgiving);
      expect(calendar.isHoliday(new Date(2018, 12, 25)), true);
      expect(calendar.getHolidayType(new Date(2018, 12, 25)), HolidayType.christmas);
    });

    test('CT State Holidays 2011', () {
      var calendar = new CtStateHolidayCalendar();
      expect(calendar.isHoliday(new Date(2011, 2, 11)), true);
//      expect(
//          calendar.getHolidayType(new Date(2011, 2, 11)), HolidayType.lincolnBirthday);
//      expect(calendar.isHoliday(new Date(2011, 4, 22)), true);
//      expect(
//          calendar.getHolidayType(new Date(2011, 4, 22)), HolidayType.goodFriday);
    });
  });
}

main() => calendarTests();