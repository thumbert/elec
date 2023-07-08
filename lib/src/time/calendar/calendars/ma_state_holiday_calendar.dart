import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../holidays/patriots_day.dart';
import 'federal_holidays_calendar.dart';


/// Massachusetts has Patriots' Day in addition to the
/// 10 Federal holidays.
class MaStateHolidayCalendar extends Calendar {
  static final _federalCalendar = FederalHolidaysCalendar();
  static final Holiday _patriotsDay = PatriotsDay();

  late HolidayType _holidayType;

  @override
  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date)) {
      throw ArgumentError('$date is not a MA State holiday');
    }
    return _holidayType;
  }

  @override
  bool isHoliday(Date date) {
    var res = false;
    if (_federalCalendar.isHoliday(date)) {
      _holidayType = _federalCalendar.getHolidayType(date);
      return true;
    }

    if (date.month == 4) {
      if (_patriotsDay.isDate(date)) {
        res = true;
        _holidayType = HolidayType.patriotsDay;
      }
    }
    return res;
  }

  @override
  bool isHoliday3(int year, int month, int day) {
    // TODO: implement isHoliday3
    throw UnimplementedError();
  }

}


