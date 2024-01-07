import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../calendar.dart';

/// NERC Calendar
class NercCalendar extends Calendar {

  // All NERC holidays
  final holidays = <Holiday>{
    Holiday.newYear,
    Holiday.memorialDay,
    Holiday.independenceDay,
    Holiday.laborDay,
    Holiday.thanksgiving,
    Holiday.christmas,
  };

  late HolidayType _holidayType;

  @override
  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date)) {
      throw ArgumentError('$date is not a NERC holiday');
    }
    switch (date.month) {
      case 1:
        _holidayType = HolidayType.newYear;
        break;
      case 5:
        _holidayType = HolidayType.memorialDay;
        break;
      case 7:
        _holidayType = HolidayType.independenceDay;
        break;
      case 9:
        _holidayType = HolidayType.laborDay;
        break;
      case 11:
        _holidayType = HolidayType.thanksgiving;
        break;
      case 12:
        _holidayType = HolidayType.christmas;
        break;
      default:
    }
    return _holidayType;
  }

  @override
  bool isHoliday(Date date) => isHoliday3(date.year, date.month, date.day);

  @override
  bool isHoliday3(int year, int month, int day) {
    return switch (month) {
      1 => Holiday.newYear.isDate3(year, month, day) ? true : false,
      5 => Holiday.memorialDay.isDate3(year, month, day) ? true : false,
      7 => Holiday.independenceDay.isDate3(year, month, day) ? true : false,
      9 => Holiday.laborDay.isDate3(year, month, day) ? true : false,
      11 => Holiday.thanksgiving.isDate3(year, month, day) ? true : false,
      12 => Holiday.christmas.isDate3(year, month, day) ? true : false,
      _ => false,
    };
  }
}
