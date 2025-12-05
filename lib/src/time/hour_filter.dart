import 'package:date/date.dart';
import 'package:elec/elec.dart';

class HourlyFilter {
  /// Construct an hourly filter
  HourlyFilter();

  var _f = (Hour hour) => true;

  HourlyFilter withBucket(Bucket bucket) {
    f(Hour hour) => _f(hour) && bucket.containsHour(hour);
    return HourlyFilter().._f = f;
  }

  HourlyFilter withHoursBeginningIn(Set<int> hoursBeginning) {
    f(Hour hour) => _f(hour) && hoursBeginning.contains(hour.start.hour);
    return HourlyFilter().._f = f;
  }

  HourlyFilter withMonthOfYear(int month) {
    f(Hour hour) => _f(hour) && hour.start.month == month;
    return HourlyFilter().._f = f;
  }

  HourlyFilter withMonthOfYearIn(Set<int> months) {
    f(Hour hour) => _f(hour) && months.contains(hour.start.month);
    return HourlyFilter().._f = f;
  }

  /// Mon = 1, Sun = 7
  HourlyFilter withWeekday(int dayOfWeek) {
    f(Hour hour) => _f(hour) && hour.start.weekday == dayOfWeek;
    return HourlyFilter().._f = f;
  }

  /// Mon = 1, Sun = 7
  HourlyFilter withWeekdayIn(Set<int> daysOfWeek) {
    f(Hour hour) => _f(hour) && daysOfWeek.contains(hour.start.weekday);
    return HourlyFilter().._f = f;
  }

  HourlyFilter withYearsIn(Set<int> years) {
    f(Hour hour) => _f(hour) && years.contains(hour.start.year);
    return HourlyFilter().._f = f;
  }

  /// Return the iterable of hours that satisfy this filter
  Iterable<Hour> hours(Interval interval) {
    return interval
        .splitLeft((dt) => Hour.beginning(dt))
        .where((hour) => _f(hour));
  }
}
