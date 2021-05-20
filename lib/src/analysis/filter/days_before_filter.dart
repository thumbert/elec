library elec.analysis.filter.days_before_filter;

import 'package:date/date.dart';
import 'base_filter.dart';

class DaysBeforeFilter extends BaseFilter {
  Date asOfDate;
  int dayCount;

  /// Days in historical data set that satisfy the filter.
  late Set<Date> days;

  /// Get all the days [dayCount] days before [asOfDate], not including
  /// [asOfDate].
  DaysBeforeFilter(this.asOfDate, {this.dayCount = 14}) {
    days = asOfDate.previousN(dayCount).toSet();
  }

  @override
  bool contains(Date date) => days.contains(date);
}