import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Washington's Birthday (Presidents' Day).  It's a federal holiday.
/// Is celebrated on the 3rd Monday in February.
class WashingtonBirthday implements Holiday {
  HolidayType holidayType = HolidayType.washingtonBirthday;

  Date forYear(int year, {Location location}) {
    return makeHoliday(year, 2, 3, DateTime.MONDAY, location: location);
  }

  bool isDate(Date date) =>
      this.forYear(date.year, location: date.location) == date;

}


