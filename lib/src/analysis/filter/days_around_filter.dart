library elec.analysis.filter.days_around_filter;

import 'package:date/date.dart';
import 'base_filter.dart';

class DaysAroundFilter extends BaseFilter {
  Date asOfDate;
  int dayCount;

  /// Days in historical data set that satisfy the filter.
  late Set<Date> days;

  /// Get all the [dayCount] days before and after [asOfDate], including
  /// [asOfDate] too.
  DaysAroundFilter(this.asOfDate, {this.dayCount = 7}) {
    days = {
      ...asOfDate.previousN(dayCount),
      asOfDate,
      ...asOfDate.nextN(dayCount),
    };
  }

  @override
  bool contains(Date date) => days.contains(date);
}
