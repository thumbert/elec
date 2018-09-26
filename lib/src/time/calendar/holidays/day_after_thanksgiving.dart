import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Day after Thanksgiving is a state holiday in NH.
class DayAfterThanksgiving implements Holiday {
  HolidayType holidayType = HolidayType.dayAfterThanksgiving;

  Date forYear(int year, {Location location}) {
    var candidate = makeHoliday(year, 11, 4, DateTime.thursday, location: location);
    return candidate.add(1);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;
}
