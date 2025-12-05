import 'package:date/date.dart';
import 'package:elec/time.dart';

class DayFilter {
  /// All the arguments specify what days to keep in the filter.
  /// If empty don't apply the respective filter at all.
  DayFilter({
    required this.years,
    required this.months,
    required this.days,
    required this.daysOfWeek,
    required this.specialDays,
    required this.holidays,
  });

  /// Years contained in the filter
  final Set<int> years;

  /// Months of year, 1-12
  final Set<int> months;

  /// Days of month
  final Set<int> days;

  /// Days of week, Mon=1, Sun=7
  final Set<int> daysOfWeek;

  /// Hand-picked days (UTC)
  final Set<Date> specialDays;

  /// Holidays to keep in the filter
  final Set<Holiday> holidays;

  /// The empty filter passes everything!
  DayFilter.empty()
      : years = <int>{},
        months = <int>{},
        days = <int>{},
        daysOfWeek = <int>{},
        specialDays = <Date>{},
        holidays = <Holiday>{};

  /// Check if this day is in the filter
  bool hasDay(Date date) {
    if (years.isNotEmpty && !years.contains(date.year)) return false;
    if (months.isNotEmpty && !months.contains(date.month)) return false;
    if (days.isNotEmpty && !days.contains(date.day)) return false;
    if (daysOfWeek.isNotEmpty && !daysOfWeek.contains(date.weekday)) {
      return false;
    }
    if (holidays.isNotEmpty &&
        holidays.every((e) => !e.isDate3(date.year, date.month, date.day))) {
      return false;
    }
    if (specialDays.isNotEmpty && !specialDays.contains(date)) {
      return false;
    }
    return true;
  }

  /// Return all the days in term that satisfy this filter
  List<Date> getDays(Term term) => term.days().where((e) => hasDay(e)).toList();

  /// Check if this time filter is empty (doesn't have to do anything)
  bool isEmpty() =>
      years.isEmpty &&
      months.isEmpty &&
      days.isEmpty &&
      daysOfWeek.isEmpty &&
      specialDays.isEmpty &&
      holidays.isEmpty;

  bool isNotEmpty() => !isEmpty();

  /// Construct a time filter from the minimal description only.
  static DayFilter fromJson(Map<String, dynamic> x) {
    var years = x['years'] ?? <int>{};
    var months = x['months'] ?? <int>{};
    var days = x['days'] ?? <int>{};
    var dayOfWeek = x['dayOfWeek'] ?? <int>{};
    var holidays = <Holiday>{};
    if (x['holidays'] != null) {
      for (var holidayName in x['holidays']) {
        holidays.add(Holiday.parse(holidayName));
      }
    }
    return DayFilter(
        years: years.toSet().cast<int>(),
        months: months.toSet().cast<int>(),
        days: days.toSet().cast<int>(),
        daysOfWeek: dayOfWeek.toSet().cast<int>(),
        specialDays: <Date>{},
        holidays: holidays);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (years.isNotEmpty) 'years': years,
      if (months.isNotEmpty) 'months': months,
      if (days.isNotEmpty) 'days': days,
      if (daysOfWeek.isNotEmpty) 'daysOfWeek': daysOfWeek,
      if (holidays.isNotEmpty)
        'holidays': holidays.map((e) => e.holidayType.name).toSet(),
    };
  }

  DayFilter copyWith({
    Set<int>? years,
    Set<int>? months,
    Set<int>? days,
    Set<int>? daysOfWeek,
    Set<Date>? specialDays,
    Set<Holiday>? holidays,
  }) =>
      DayFilter(
          years: years ?? this.years,
          months: months ?? this.months,
          days: days ?? this.days,
          daysOfWeek: daysOfWeek ?? this.daysOfWeek,
          specialDays: specialDays ?? this.specialDays,
          holidays: holidays ?? this.holidays);
}
