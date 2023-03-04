import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../holiday_utils.dart';

class DayAfterThanksgiving extends Holiday {
  /// Day after Thanksgiving is a state holiday in NH.
  DayAfterThanksgiving() {
    holidayType = HolidayType.dayAfterThanksgiving;
  }

  @override
  Date forYear(int year, {required Location location}) {
    var candidate = makeHoliday(year, 11, 4, DateTime.thursday, location: location);
    return candidate.add(1);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;
}
