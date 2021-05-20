library time.hourly_filter;

import 'package:date/date.dart';
import 'package:elec/elec.dart';

class HourlyFilter {
  final Interval? interval;

  late bool Function(Hour) _f;

  bool call(Hour hour) => _f(hour);

  /// Construct an hourly filter for a given interval.
  HourlyFilter(this.interval) {
    _f = (Hour hour) => interval!.containsInterval(hour);
  }

  HourlyFilter withBucket(Bucket bucket) {
    return HourlyFilter(interval)
      .._f = (Hour hour) => _f(hour) && bucket.containsHour(hour);
  }

  HourlyFilter withHoursBeginningIn(Set<int> hoursBeginning) {
    return HourlyFilter(interval)
      .._f = (Hour hour) => _f(hour) && hoursBeginning.contains(hour.start.hour);
  }

  HourlyFilter withMonthOfYear(int month) {
    return HourlyFilter(interval)
      .._f = (Hour hour) => _f(hour) && month == hour.start.month;
  }

  HourlyFilter withMonthOfYearIn(Set<int> months) {
    return HourlyFilter(interval)
      .._f = (Hour hour) => _f(hour) && months.contains(hour.start.month);
  }

  HourlyFilter withWeekday(int day) {
    return HourlyFilter(interval)
      .._f = (Hour hour) => _f(hour) && day == hour.start.weekday;
  }

  HourlyFilter withWeekdayIn(Set<int> days) {
    return HourlyFilter(interval)
      .._f = (Hour hour) => _f(hour) && days.contains(hour.start.weekday);
  }

  HourlyFilter withYearsIn(Set<int> years) {
    return HourlyFilter(interval)
      .._f = (Hour hour) => _f(hour) && years.contains(hour.start.year);
  }

  /// Return the iterable of hours that satisfy this filter
  Iterable<Hour> hours() {
    return interval!
        .splitLeft((dt) => Hour.beginning(dt))
        .where((hour) => _f(hour));
  }
}
