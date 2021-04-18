import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import '../holiday.dart';


/// Good Friday is a state holiday in CT.
class GoodFriday implements Holiday {
  @override
  HolidayType holidayType = HolidayType.goodFriday;
  /// https://en.wikipedia.org/wiki/Good_Friday#Calculating_the_date
  final Map<int,Date> _goodFriday = {
    2008:  Date(2008, 3, 21),
    2009:  Date(2009, 4, 10),
    2010:  Date(2010, 4, 2),
    2011:  Date(2011, 4, 22),
    2012:  Date(2012, 4, 6),
    2013:  Date(2013, 3, 29),
    2014:  Date(2014, 4, 18),
    2015:  Date(2015, 4, 3),
    2016:  Date(2016, 3, 25),
    2017:  Date(2017, 4, 14),
    2018:  Date(2018, 3, 30),
    2019:  Date(2019, 4, 19),
    2020:  Date(2020, 4, 10),
    2021:  Date(2021, 4, 2),
    2022:  Date(2022, 4, 15),
    2023:  Date(2023, 4, 7),
    2024:  Date(2024, 3, 29),
    2025:  Date(2025, 4, 18),
    2026:  Date(2026, 4, 3),
    2027:  Date(2027, 3, 26),
    2028:  Date(2028, 4, 14),
    2029:  Date(2029, 3, 30),
    2030:  Date(2030, 4, 19),
  };
  @override
  Date forYear(int year, {Location location}) {

    var candidate = _goodFriday[year];
    candidate =  Date(candidate.year, candidate.month,
        candidate.day, location: location);
    if (candidate.weekday != 5) {
      throw  StateError('$candidate is not a Friday!');
    }
    return candidate;
  }

  @override
  bool isDate(Date date) =>
    forYear(date.year, location: date.location) == date;
}
