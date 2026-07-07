import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';

enum PeriodType { summer, winter }

class CapabilityPeriod {
  /// Construct a capacity season from a name like 'Summer 2026' or 'Winter 2026-2027'.
  /// The name should be in the format 'Summer YYYY' or 'Winter YYYY-YYYY'.
  CapabilityPeriod(this.name) {
    final aux = name.split(' ');
    periodType = switch (aux[0]) {
      'Summer' => PeriodType.summer,
      'Winter' => PeriodType.winter,
      _ => throw ArgumentError('Unknown PeriodType: ${aux[0]}')
    };
    final yearStart = int.parse(aux[1].substring(0, 4));

    final startDate = switch (periodType) {
      PeriodType.summer => Date(yearStart, 5, 1, location: NewYorkIso.location),
      PeriodType.winter => Date(yearStart, 11, 1, location: NewYorkIso.location)
    };
    final endDate = switch (periodType) {
      PeriodType.summer =>
        Date(yearStart, 10, 31, location: NewYorkIso.location),
      PeriodType.winter =>
        Date(yearStart + 1, 4, 30, location: NewYorkIso.location)
    };
    term = Term(startDate, endDate);
  }

  /// 'Summer 2026' or 'Winter 2026-2027'
  late final String name;

  /// In America/New_York timezone
  late final Term term;

  late final PeriodType periodType;

  /// Returns a list of months that fall within the capability period.
  List<Month> months() => term.interval.splitLeft((dt) => Month.containing(dt));

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (other is! CapabilityPeriod) return false;
    CapabilityPeriod period = other;
    return period.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
