import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

extension LeapYearPolicyExt on TimeSeries<num> {
  /// Apply a given leap year policy to this timeseries.
  TimeSeries<num> applyLeapYearPolicy(LeapYearPolicy policy) {
    return policy(this);
  }
}

abstract class LeapYearPolicy {
  TimeSeries<num> call(TimeSeries<num> xs);

  /// Do nothing with the timeseries.  Keep data as is.
  static LeapYearPolicy none = _LeapYearPolicyNone();

  ///  Remove all 29Feb observations from leap years.  After applying this
  ///  all years will have 28 observations in Feb.
  static LeapYearPolicy remove29Feb = _LeapYearPolicyRemove29Feb();

  /// Create an additional observation in Feb for non leap years.
  /// For non-leap years only,
  /// split the 28 Feb observation into 2 observations with intervals
  /// [yyyy-02-28 00:00 -> yyyy-02-28 12:00) and
  /// [yyyy-02-28 12:00 -> yyyy-03-01 00:00).
  /// Leap years are not modified.  Both leap and non-leap years will have
  /// 29 values in Feb.
  ///
  /// This policy works for daily timeseries only.
  static LeapYearPolicy split28FebNonLeap = _LeapYearPolicySplit28FebNonLeap();
}

class _LeapYearPolicyNone extends LeapYearPolicy {
  @override
  TimeSeries<num> call(TimeSeries<num> xs) => xs;
}

class _LeapYearPolicyRemove29Feb extends LeapYearPolicy {
  @override
  TimeSeries<num> call(TimeSeries<num> xs) {
    return TimeSeries.fromIterable(
        xs.where((e) => e.interval != Date.utc(e.interval.start.year, 2, 29)));
  }
}

class _LeapYearPolicySplit28FebNonLeap extends LeapYearPolicy {
  @override
  TimeSeries<num> call(TimeSeries<num> xs) {
    if (xs.isNotEmpty && xs.first.interval is! Date) {
      throw StateError('Policy works only with daily timeseries.');
    }
    var ts = TimeSeries<num>();
    for (var x in xs) {
      var start = x.interval.start;
      if (start.year % 4 != 0 && start.month == 2 && start.day == 28) {
        var mid = start.add(Duration(hours: 12));
        ts.add(IntervalTuple(Interval(start, mid), x.value));
        ts.add(IntervalTuple(Interval(mid, x.interval.end), x.value));
      } else {
        ts.add(x);
      }
    }
    return ts;
  }
}
