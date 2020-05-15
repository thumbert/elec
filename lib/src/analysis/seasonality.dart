library analysis.seasonality;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';


/// Define commonly encountered types of seasonality.  There are two components:
/// a grouping (fast) and a path (slow) component.  For a [monthOfYear]
/// seasonality, the groups are the months of the year (1:12) and the paths
/// are the calendar years.
class Seasonality {
  final String name;
  final Map<int,TimeSeries<num>> Function(TimeSeries<num>) toGroups;
  final Map<Interval,TimeSeries<num>> Function(TimeSeries<num>) toPaths;

  Seasonality._internal(this.name, this.toGroups, this.toPaths);

  static Seasonality parse(String x){
    if (x.toLowerCase() == 'monthofyear') {
      return Seasonality.monthOfYear;
    } else if (x.toLowerCase() == 'weekofyear') {
      return Seasonality.weekOfYear;
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

  static var monthOfYear = Seasonality._internal('monthOfYear',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => e.start.month),
          (TimeSeries<num> xs) => _toPath(xs, (e) {
        var year = Interval(TZDateTime(e.interval.start.location, e.interval.start.year),
            TZDateTime(e.interval.start.location, e.interval.start.year + 1));
        return Tuple2(year, e);
      })
  );
  static var weekOfYear = Seasonality._internal('weekOfYear',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => Week.fromTZDateTime(e.start).week),
          (TimeSeries<num> xs) => _toPath(xs, (e) {
        var year = Interval(TZDateTime(e.interval.start.location, e.interval.start.year),
            TZDateTime(e.interval.start.location, e.interval.start.year + 1));
        return Tuple2(year, e);
      })
  );
  static var dayOfYear = Seasonality._internal('dayOfYear',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => Date.fromTZDateTime(e.start).dayOfYear()),
          (TimeSeries<num> xs) => _toPath(xs, (e) {
        var year = Interval(TZDateTime(e.interval.start.location, e.interval.start.year),
            TZDateTime(e.interval.start.location, e.interval.start.year + 1));
        return Tuple2(year, e);
      })
  );
  static var dayOfWeek = Seasonality._internal('dayOfWeek',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => e.start.weekday),
          (TimeSeries<num> xs) => _toPath(xs, (e) => Tuple2(Week.fromTZDateTime(e.interval.start), e))
  );
  static var hourOfDay = Seasonality._internal('hourOfDay',
          (TimeSeries<num> xs) => _groupByIndex(xs, (e) => e.start.hour),
          (TimeSeries<num> xs) => _toPath(xs, (e) => Tuple2(Date.fromTZDateTime(e.interval.start), e))
  );

  @override
  String toString() => name;
}



Map<Interval, TimeSeries<num>> _toPath(TimeSeries<num> xs, Tuple2<Interval,IntervalTuple> Function(IntervalTuple obs) f) {
  var grp = <Interval, TimeSeries<num>>{};
  var n = xs.length;
  for (var i = 0; i < n; i++) {
    var t2 = f(xs[i]);
    grp
        .putIfAbsent(t2.item1, () => TimeSeries<num>())
        .add(t2.item2);
  }
  return grp;
}


Map<int, TimeSeries<K>> _groupByIndex<K>(TimeSeries<K> xs, int Function(Interval interval) f) {
  var grp = <int, TimeSeries<K>>{};
  var n = xs.length;
  for (var i = 0; i < n; i++) {
    var group = f(xs[i].interval);
    grp.putIfAbsent(group, () => TimeSeries<K>()).add(xs[i]);
  }
  return grp;
}

