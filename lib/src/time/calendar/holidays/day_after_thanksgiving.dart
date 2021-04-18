import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Day after Thanksgiving is a state holiday in NH.
class DayAfterThanksgiving implements Holiday {
  @override
  HolidayType holidayType = HolidayType.dayAfterThanksgiving;

  @override
  Date forYear(int year, {Location location}) {
    var candidate = makeHoliday(year, 11, 4, DateTime.thursday, location: location);
    return candidate.add(1);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;
}
