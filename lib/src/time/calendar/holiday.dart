library holiday;

import 'package:date/date.dart';


/// http://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
class Holiday {
  static final Duration duration = new Duration(days: 1);
  Date day;
  String name;

  Holiday();

  Holiday.from(Date this.day);

  toString() => day.toString();

  static Holiday christmas(int year) =>
      new Holiday.from(new Date(year, 12, 25))..name = "Christmas";
  static bool isChristmas(Date date) {
    if (date.month == 12 && date.day == 25)
      return true;
    else
      return false;
  }
  /// If 12/25 Christmas Day falls on Sun, NERC moves it to Mon.
  /// If 12/25 falls on every other day, it stays where it is.
  static bool isNercChristmas(Date date) {
    if (date.month == 12) {
      if (date.day == 25 && date.weekday != 7) return true;
      if (date.day == 26 && date.weekday == 1) return true;
    }

    return false;
  }

  //static Holiday columbusDay(int year)



  static Holiday fourthOfJuly(int year) =>
      new Holiday.from(new Date(year, 7, 4))..name = "4th July";
  static bool isFourthOfJuly(Date date) {
    if (date.month == 7 && date.day == 4)
      return true;
    else
      return false;
  }
  /// If 7/4 Independence Day falls on Sun, NERC moves it to Mon.
  /// If 7/4 falls on every other day, it stays where it is.
  static bool isNercFourthOfJuly(Date date) {
    if (date.month == 7) {
      if (date.day == 4 && date.weekday != 7) return true;
      if (date.day == 5 && date.weekday == 1) return true;
    }
    return false;
  }

  /// Good Friday is a state holiday in CT, but not in MA, RI, NH, ME.
  /// Repeats every 12 years.  Can do better than the map.  //TODO
  static Holiday goodFriday(int year) {
    Map<int,Date> _goodFriday = {
      2013: new Date(2013, 3, 29),
      2014: new Date(2014, 4, 18),
      2015: new Date(2015, 4, 3),
      2016: new Date(2016, 3, 26),
      2017: new Date(2017, 4, 14),
      2018: new Date(2018, 3, 30),
      2019: new Date(2019, 4, 19),
      2020: new Date(2020, 4, 10),
      2021: new Date(2021, 4, 2),
      2022: new Date(2022, 4, 15),
      2023: new Date(2023, 4, 7),
      2024: new Date(2024, 3, 29),
      2025: new Date(2025, 4, 18),
      2026: new Date(2026, 4, 3),
      2027: new Date(2027, 3, 26),
      2028: new Date(2028, 4, 14),
      2029: new Date(2029, 3, 30),
      2030: new Date(2030, 4, 19),
    };
    return new Holiday.from(_goodFriday[year]);
  }
  static bool isGoodFriday(Date date) {
    return Holiday.goodFriday(date.year).day == date ? true : false;
  }


  /// Labor Day, 1st Monday in Sep
  static Holiday laborDay(int year) =>
      _makeHoliday(year, DateTime.SEPTEMBER, 1, DateTime.MONDAY)
        ..name = "Labor Day";
  static bool isLaborDay(Date date) {
    if (Holiday.laborDay(date.year).day == date)
      return true;
    else
      return false;
  }

  /// Lincoln's Birthday.  It's a state holiday in CT.  If it falls on a weekend
  /// it sometimes gets observed on the following Monday, but not always.
  /// For example it was observed on Mon 2/13/2017, but was not moved on
  /// Sun 2/12/2012.
  static Holiday lincolnBirthday(int year) {
    Date day = new Date(year, 2, 12);
    if (year == 2017) day = new Date(2017, 2, 13);
    return new Holiday.from(day)..name = 'Lincoln\'s Birthday';
  }
  static bool isLincolnBirthday(Date date) {
    if (Holiday.lincolnBirthday(date.year).day == date)
      return true;
    else
      return false;
  }


  /// Martin Luther King holiday, 3rd Monday in Jan
  static Holiday martinLutherKing(int year) =>
      _makeHoliday(year, DateTime.JANUARY, 3, DateTime.MONDAY)
        ..name = "Martin Luther King";

  /// Thanksgiving holiday, 4rd Thursday in Nov
  static Holiday thanksgiving(int year) =>
      _makeHoliday(year, DateTime.NOVEMBER, 4, DateTime.THURSDAY)
        ..name = "Thanksgiving";

  static bool isThanksgiving(Date date) {
    if (Holiday.thanksgiving(date.year).day == date)
      return true;
    else
      return false;
  }

  /// Memorial day is on last Monday in May
  static Holiday memorialDay(int year) {
    int wday_eom = new Date(year, 5, 31).weekday;
    return new Holiday()
      ..day = new Date(year, 5, 32 - wday_eom)
      ..name = "Memorial Day";
  }

  static bool isMemorialDay(Date date) {
    if (Holiday.memorialDay(date.year).day == date)
      return true;
    else
      return false;
  }

  static Holiday newYearsEve(int year) =>
      new Holiday.from(new Date(year, 1, 1))..name = "New Year's Eve";
  static bool isNewYearsEve(Date date) {
    if (Holiday.newYearsEve(date.year).day == date)
      return true;
    else
      return false;
  }
  /// If 1/1 New Year's Eve falls on Sun, NERC moves it to Mon.
  /// If 1/1 falls on every other day, it stays where it is.
  static bool isNercNewYearsEve(Date date) {
    if (date.month == 1) {
      if (date.day == 1 && date.weekday != 7) return true;
      if (date.day == 2 && date.weekday == 1) return true;
    }
    return false;
  }

  /// Make a holiday if you know the month, week of the month, and weekday
  static Holiday _makeHoliday(
      int year, int month, int weekOfMonth, int weekday) {
    int wday_bom = new DateTime(year, month, 1).weekday;
    int inc = weekday - wday_bom;
    if (inc < 0) inc += 7;

    return new Holiday()
      ..day = new Date(year, month, 7 * (weekOfMonth - 1) + inc + 1);
  }
}
