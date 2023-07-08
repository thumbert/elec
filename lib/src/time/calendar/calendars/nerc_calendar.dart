import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import 'package:quiver/collection.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import '../holidays/new_year.dart';
import '../holidays/memorial_day.dart';
import '../holidays/independence_day.dart';
import '../holidays/labor_day.dart';
import '../holidays/thanksgiving.dart';
import '../holidays/christmas.dart';
import '../calendar.dart';

/// NERC Calendar
class NercCalendar extends Calendar {
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

  @Deprecated('Use isHoliday3.')
  @override
  bool isHoliday(Date date) => isHoliday3(date.year, date.month, date.day);

  /// Note: the implementation of [isHoliday3] is about 30% faster than
  /// [isHoliday].
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
