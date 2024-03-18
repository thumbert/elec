import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';

class GoodFriday extends Holiday {
  /// Good Friday is a state holiday in CT.
  GoodFriday() {
    holidayType = HolidayType.goodFriday;
  }

  /// https://en.wikipedia.org/wiki/Good_Friday#Calculating_the_date
  final Map<int, Date> _goodFriday = {
    2008: Date.utc(2008, 3, 21),
    2009: Date.utc(2009, 4, 10),
    2010: Date.utc(2010, 4, 2),
    2011: Date.utc(2011, 4, 22),
    2012: Date.utc(2012, 4, 6),
    2013: Date.utc(2013, 3, 29),
    2014: Date.utc(2014, 4, 18),
    2015: Date.utc(2015, 4, 3),
    2016: Date.utc(2016, 3, 25),
    2017: Date.utc(2017, 4, 14),
    2018: Date.utc(2018, 3, 30),
    2019: Date.utc(2019, 4, 19),
    2020: Date.utc(2020, 4, 10),
    2021: Date.utc(2021, 4, 2),
    2022: Date.utc(2022, 4, 15),
    2023: Date.utc(2023, 4, 7),
    2024: Date.utc(2024, 3, 29),
    2025: Date.utc(2025, 4, 18),
    2026: Date.utc(2026, 4, 3),
    2027: Date.utc(2027, 3, 26),
    2028: Date.utc(2028, 4, 14),
    2029: Date.utc(2029, 3, 30),
    2030: Date.utc(2030, 4, 19),
    2031: Date.utc(2031, 4, 11),
  };
  @override
  Date forYear(int year, {required Location location}) {
    var candidate = _goodFriday[year]!;
    candidate = Date(candidate.year, candidate.month, candidate.day,
        location: location);
    if (candidate.weekday != 5) {
      throw StateError('$candidate is not a Friday!');
    }
    return candidate;
  }

  @override
  bool isDate(Date date) => forYear(date.year, location: date.location) == date;
}
