import 'package:elec/src/time/calendar/calendar.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';

Map<Date, String> assignHolidays(List<Date> dates, Calendar calendar) {
  var out = <Date,String>{};
  for (var date in dates) {
    if (calendar.isHoliday(date)) {
      out[date] = calendar.getHolidayType(date).name;
    }
  }
  return out;
}


/// Make a holiday if you know the month, week of the month, and weekday
Date makeHoliday(
    int year, int month, int weekOfMonth, int weekday, {required Location location}) {
  var wdayBom = DateTime(year, month, 1).weekday;
  var inc = weekday - wdayBom;
  if (inc < 0) inc += 7;
  return Date(year, month, 7 * (weekOfMonth - 1) + inc + 1,
    location: location);
}
