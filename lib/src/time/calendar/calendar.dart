library time.calendar;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';


abstract class Calendar {
  bool isHoliday(Date day);
}

class NercCalendar extends Calendar {
  bool isHoliday(Date date) {
    switch (date.month) {
      case 1:
        if (Holiday.isNercNewYearsEve(date)) return true;
        break;
      case 5:
        if (Holiday.isMemorialDay(date)) return true;
        break;
      case 7:
        if (Holiday.isNercFourthOfJuly(date)) return true;
        break;
      case 9:
        if (Holiday.isLaborDay(date)) return true;
        break;
      case 11:
        if (Holiday.isThanksgiving(date)) return true;
        break;
      case 12:
        if (Holiday.isNercChristmas(date)) return true;
        break;
      default:
        return false;
    }

    return false;  /// should never get here
  }
}