library time.calendar;

import 'package:date/date.dart';
import 'holiday.dart';


/// A holiday calendar
abstract class Calendar {
  bool isHoliday(Date date);
  HolidayType getHolidayType(Date date);
}

