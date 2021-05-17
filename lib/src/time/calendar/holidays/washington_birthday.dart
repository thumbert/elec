import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';
import '../_holiday_utils.dart';

/// Washington's Birthday (Presidents' Day).  It's a federal holiday.
/// Is celebrated on the 3rd Monday in February.
class WashingtonBirthday implements Holiday {
  @override
  HolidayType holidayType = HolidayType.washingtonBirthday;

  @override
  Date forYear(int year, {Location/*!*/ location}) {
    return makeHoliday(year, 2, 3, DateTime.monday, location: location);
  }

  @override
  bool isDate(Date date) =>
      forYear(date.year, location: date.location) == date;

}


