library holiday;

import 'package:timeseries/time/date.dart';

/**
 *  http://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
 */
class Holiday {
  static final Duration duration = new Duration(days: 1);
  Date day;
  String name;

  Holiday();

  Holiday.from(Date this.day);

  toString() => day.toString();

  static Holiday christmas(int year) =>
  new Holiday.from(new Date(year, 12, 25))
    ..name = "Christmas";

  static bool isChristmas(Date date) {
    if (date.month == 12 && date.day == 25) return true; else return false;
  }
  static bool isNercChristmas(Date date) {
    if (date.month == 12) {
      if (date.day == 25 && date.weekday != 7) return true;
      if (date.day == 26 && date.weekday == 1) return true;
    }

    return false;
  }


  static Holiday fourthOfJuly(int year) =>
  new Holiday.from(new Date(year, 7, 4))
    ..name = "4th July";

  static bool isFourthOfJuly(Date date) {
    if (date.month == 7 && date.day == 4) return true; else return false;
  }
  static bool isNercFourthOfJuly(Date date) {
    if (date.month == 7) {
      if (date.day == 4 && date.weekday != 7) return true;
      if (date.day == 5 && date.weekday == 1) return true;
    }
    return false;
  }


  /**
   * Labor Day, 1st Monday in Sep
   */
  static Holiday laborDay(int year) =>
  _makeHoliday(year, DateTime.SEPTEMBER, 1, DateTime.MONDAY)
    ..name = "Labor Day";
  static bool isLaborDay(Date date) {
    if (Holiday.laborDay(date.year).day == date) return true; else return false;
  }

  /**
   * Martin Luther King holiday, 3rd Monday in Jan
   */
  static Holiday martinLutherKing(int year) =>
  _makeHoliday(year, DateTime.JANUARY, 3, DateTime.MONDAY)
    ..name = "Martin Luther King";


  /**
   * Thanksgiving holiday, 4rd Thursday in Nov
   */
  static Holiday thanksgiving(int year) =>
  _makeHoliday(year, DateTime.NOVEMBER, 4, DateTime.THURSDAY)
    ..name = "Thanksgiving";

  static bool isThanksgiving(Date date) {
    if (Holiday.thanksgiving(date.year).day == date) return true; else return false;
  }

  /**
   * Memorial day is on last Monday in May
   */
  static Holiday memorialDay(int year) {
    int wday_eom = new Date(year, 5, 31).weekday;
    return new Holiday()
      ..day = new Date(year, 5, 32 - wday_eom)
      ..name = "Memorial Day";
  }
  static bool isMemorialDay(Date date) {
    if (Holiday.memorialDay(date.year).day == date) return true; else return false;
  }


  static Holiday newYearsEve(int year) =>
  new Holiday.from(new Date(year, 1, 1))
    ..name = "New Year's Eve";
  static bool isNewYearsEve(Date date) {
    if (Holiday.newYearsEve(date.year).day == date) return true; else return false;
  }
  static bool isNercNewYearsEve(Date date) {
    if (date.month == 1) {
      if (date.day == 1 && date.weekday != 7) return true;
      if (date.day == 2 && date.weekday == 1) return true;
    }
    return false;
  }

  /**
   * Make a holiday if you know the month, week of the month, and weekday
   */
  static Holiday _makeHoliday(int year, int month, int weekOfMonth, int weekday) {
    int wday_bom = new DateTime(year, month, 1).weekday;
    int inc = weekday - wday_bom;
    if (inc < 0)
      inc += 7;

    return new Holiday()
      ..day = new Date(year, month, 7 * (weekOfMonth - 1) + inc + 1);
  }
}




