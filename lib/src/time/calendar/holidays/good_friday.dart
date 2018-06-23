import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';


/// Good Friday is a state holiday in CT.
class GoodFriday implements Holiday {
  HolidayType holidayType = HolidayType.goodFriday;
  /// https://en.wikipedia.org/wiki/Good_Friday#Calculating_the_date
  Map<int,Date> _goodFriday = {
    2008: new Date(2008, 3, 21),
    2009: new Date(2009, 4, 10),
    2010: new Date(2010, 4, 2),
    2011: new Date(2011, 4, 22),
    2012: new Date(2012, 4, 6),
    2013: new Date(2013, 3, 29),
    2014: new Date(2014, 4, 18),
    2015: new Date(2015, 4, 3),
    2016: new Date(2016, 3, 25),
    2017: new Date(2017, 4, 14),
    2018: new Date(2018, 3, 30),
    2019: new Date(2019, 4, 19),
    2020: new Date(2020, 4, 10),
    2021: new Date(2021, 4, 2),
    2022: new Date(2022, 4, 15),
    2023: new Date(2023, 4, 7),
    2024: new Date(2024, 3, 29),
    2025: new Date(2025, 4, 18),
    2026: new Date(2026, 4, 3),
    2027: new Date(2027, 3, 26),
    2028: new Date(2028, 4, 14),
    2029: new Date(2029, 3, 30),
    2030: new Date(2030, 4, 19),
  };
  Date forYear(int year, {Location location}) {

    var candidate = _goodFriday[year];
    candidate = new Date(candidate.year, candidate.month,
        candidate.day, location: location);
    if (candidate.weekday != 5)
      throw new StateError('$candidate is not a Friday!');
    return candidate;
  }

  bool isDate(Date date) =>
    this.forYear(date.year, location: date.location) == date;
}
