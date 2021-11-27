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
  static final Holiday _newYear = NewYear();
  static final Holiday _memorialDay = MemorialDay();
  static final Holiday _independenceDay = IndependenceDay();
  static final Holiday _laborDay = LaborDay();
  static final Holiday _thanksgiving = Thanksgiving();
  static final Holiday _christmas = Christmas();

  late HolidayType _holidayType;

  /// Store all the holidays for one year in a Map
  /// year -> {(month,day)} as we don't care of the type of the holiday.
  final _holidayCache = LruMap<int, Set<Tuple2<int, int>>>(maximumSize: 50);

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
  bool isHoliday(Date date) {
    final year = date.year;
    if (!_holidayCache.containsKey(year)) {
      _addYearToCache(year);
    }

    if (_holidayCache[year]!.contains(Tuple2(date.month, date.day))) {
      return true;
    } else {
      return false;
    }
  }

  /// Add one year to the cache
  void _addYearToCache(int year) {
    var newYear = _newYear.forYear(year, location: UTC)!;
    var memorialDay = _memorialDay.forYear(year, location: UTC)!;
    var indDay = _independenceDay.forYear(year, location: UTC)!;
    var laborDay = _laborDay.forYear(year, location: UTC)!;
    var thanksDay = _thanksgiving.forYear(year, location: UTC)!;
    var christDay = _christmas.forYear(year, location: UTC)!;
    _holidayCache[year] = {
      Tuple2(newYear.month, newYear.day),
      Tuple2(memorialDay.month, memorialDay.day),
      Tuple2(indDay.month, indDay.day),
      Tuple2(laborDay.month, laborDay.day),
      Tuple2(thanksDay.month, thanksDay.day),
      Tuple2(christDay.month, christDay.day),
    };
  }
}
