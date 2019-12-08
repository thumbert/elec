library time.hourly_filter;

import 'package:date/date.dart';
import 'package:elec/elec.dart';

class HourlyFilter {
  final Interval interval;

  bool Function(Hour) f;

  bool call(Hour hour) => f(hour);

  /// Construct an hourly filter for a given interval.
  HourlyFilter(this.interval) {
    f = (Hour hour) => interval.containsInterval(hour);
  }

  HourlyFilter withBucket(Bucket bucket) {
    return HourlyFilter(interval)
      ..f = (Hour hour) => f(hour) && bucket.containsHour(hour);
  }

  HourlyFilter withHoursBeginningIn(Set<int> hoursBeginning) {
    return HourlyFilter(interval)
      ..f = (Hour hour) => f(hour) && hoursBeginning.contains(hour.start.hour);
  }

  HourlyFilter withMonthOfYear(int month) {
    return HourlyFilter(interval)
      ..f = (Hour hour) => f(hour) && month == hour.start.month;
  }

  HourlyFilter withMonthOfYearIn(Set<int> months) {
    return HourlyFilter(interval)
      ..f = (Hour hour) => f(hour) && months.contains(hour.start.month);
  }

  HourlyFilter withWeekday(int day) {
    return HourlyFilter(interval)
      ..f = (Hour hour) => f(hour) && day == hour.start.weekday;
  }

  HourlyFilter withWeekdayIn(Set<int> days) {
    return HourlyFilter(interval)
      ..f = (Hour hour) => f(hour) && days.contains(hour.start.weekday);
  }

  HourlyFilter withYearsIn(Set<int> years) {
    return HourlyFilter(interval)
      ..f = (Hour hour) => f(hour) && years.contains(hour.start.year);
  }

  /// Return the iterable of hours that satisfy this filter
  Iterable<Hour> hours() {
    return interval
        .splitLeft((dt) => Hour.beginning(dt))
        .cast<Hour>()
        .where((hour) => f(hour));
  }
}
