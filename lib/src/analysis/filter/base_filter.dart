library elec.analysis.filter.base_filter;

import 'package:date/date.dart';

abstract class BaseFilter {
  bool contains(Date date);
}

class DateFilter extends BaseFilter {
  late List<BaseFilter> _filters;

  DateFilter() {
    _filters = <BaseFilter>[];
  }

  void add(BaseFilter filter) {
    _filters.add(filter);
  }

  @override
  bool contains(Date date) => _filters.every((filter) => filter.contains(date));
}



class MonthOfYearFilter extends BaseFilter {
  Set<Month> months;
  /// Keep only days that have month of year in the Set [months].
  MonthOfYearFilter(this.months);
  @override
  bool contains(Date date) => months.contains(date.month);
}

class WeekdayFilter extends BaseFilter {
  @override
  bool contains(Date date) => !date.isWeekend();
}

class WeekendFilter extends BaseFilter {
  @override
  bool contains(Date date) => date.isWeekend();
}
