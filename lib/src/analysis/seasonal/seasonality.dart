/// Define commonly encountered types of seasonality.  There are two components:
/// a grouping (fast) and a path (slow) component.  For a [monthOfYear]
/// seasonality, the groups are the months of the year (1:12) and the paths
/// are the calendar years.
class Seasonality {
  final String name;

  Seasonality._internal(this.name);

  static Seasonality parse(String x) {
    if (x.toLowerCase() == 'monthofyear') {
      return Seasonality.monthOfYear;
    } else if (x.toLowerCase() == 'weekofyear') {
      return Seasonality.weekOfYear;
    } else if (x.toLowerCase() == 'dayofterm') {
      return Seasonality.dayOfTerm;
    } else if (x.toLowerCase() == 'dayofyear') {
      return Seasonality.dayOfYear;
    } else if (x.toLowerCase() == 'dayofweek') {
      return Seasonality.dayOfWeek;
    } else if (x.toLowerCase() == 'hourofday') {
      return Seasonality.hourOfDay;
    } else {
      throw ArgumentError('Seasonality $x is not supported');
    }
  }

  static var monthOfYear = Seasonality._internal('monthOfYear');
  static var weekOfYear = Seasonality._internal('weekOfYear');
  static var dayOfTerm = Seasonality._internal('dayOfTerm');
  static var dayOfYear = Seasonality._internal('dayOfYear');
  static var dayOfWeek = Seasonality._internal('dayOfWeek');
  static var hourOfDay = Seasonality._internal('hourOfDay');

  @override
  String toString() => name;
}
