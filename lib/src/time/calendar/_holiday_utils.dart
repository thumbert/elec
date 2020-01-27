import 'package:timezone/timezone.dart';
import 'package:date/date.dart';

/// Make a holiday if you know the month, week of the month, and weekday
Date makeHoliday(
    int year, int month, int weekOfMonth, int weekday, {Location location}) {
  var wday_bom = DateTime(year, month, 1).weekday;
  var inc = weekday - wday_bom;
  if (inc < 0) inc += 7;
  return Date(year, month, 7 * (weekOfMonth - 1) + inc + 1,
    location: location);
}
