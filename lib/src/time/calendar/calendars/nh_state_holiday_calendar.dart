import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import '../holidays/day_after_thanksgiving.dart';
import 'federal_holidays_calendar.dart';


/// NH has the day after Thanksgiving in addition to the
/// 10 Federal holidays.
class NhStateHolidayCalendar extends Calendar {
  static final _federalCalendar = new FederalHolidaysCalendar();
  static final Holiday _dayAfterThanksgiving = new DayAfterThanksgiving();

  HolidayType _holidayType;

  HolidayType getHolidayType(Date date) {
    if (!isHoliday(date))
      throw new ArgumentError('$date is not a NH State holiday');
    return _holidayType;
  }

  bool isHoliday(Date date) {
    bool res = false;
    if (_federalCalendar.isHoliday(date)) {
      _holidayType = _federalCalendar.getHolidayType(date);
      return true;
    }

    if (date.month == 11) {
      if (_dayAfterThanksgiving.isDate(date)) {
        res = true;
        _holidayType = HolidayType.dayAfterThanksgiving;
      }
    }
    return res;
  }

}


