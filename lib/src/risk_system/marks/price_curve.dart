part of elec.risk_system;

class PriceCurve extends TimeSeries<Map<Bucket, num>> with MarksCurve {
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

  TimeSeries<num> _ts;

  /// A simple forward curve model for daily and monthly values extending
  /// a TimeSeries<Map<Bucket,num>>.  There are no gaps in the observations.
  PriceCurve();

  /// A simple forward curve model for daily and monthly values extending
  /// a TimeSeries<Map<Bucket,num>>.  There are no gaps in the observations.
  PriceCurve.fromIterable(Iterable<IntervalTuple<Map<Bucket, num>>> xs) {
    addAll(xs);
  }

  /// Construct a forward curve given an input in this form.  The buckets
  /// can be different, but the covering needs to be complete (no gaps.)
  ///   [
  ///     {'term': '2020-07-17', 'value': {'5x16': 27.10, '7x8': 15.5}},
  ///     {'term': '2020-07-18', 'value': {'2x16H': 22.15, '7x8': 15.5}},
  ///     ...
  ///     {'term': '2020-08', 'value': {'5x16': 31.50, '2x16H': 25.15, '7x8': 18.75}},
  ///     ...
  ///   ]
  ///   The inputs are time-ordered with no gaps.
  PriceCurve.fromJson(List<Map<String, dynamic>> xs, Location location) {
    location ??= UTC;
    for (var x in xs) {
      Interval term;
      if ((x['term'] as String).length == 10) {
        term = Date.parse(x['term'], location: location);
      } else if ((x['term'] as String).length == 7) {
        term = Month.parse(x['term'], fmt: _isoFmt, location: location);
      } else {
        throw ArgumentError('Unsupported term format ${x['term']}');
      }
      var value = {
        for (var e in (x['value'] as Map).entries)
          Bucket.parse(e.key): e.value as num
      };
      add(IntervalTuple(term, value));
    }
  }

  /// Get the entire curve as an hourly timeseries
  /// If the forward curve contains only one bucket, say 2x16H, only the hours
  /// associated with that bucket will be returned in the interval.
  TimeSeries<num> toHourly() {
    if (_ts != null) return _ts;
    _ts = TimeSeries<num>();
    var buckets = <Bucket>{...expand((e) => e.value.keys)};
    if (buckets == {Bucket.b7x8, Bucket.b2x16H, Bucket.b5x16}) {
      // this is fastest
      buckets = {Bucket.b5x16, Bucket.b7x8, Bucket.b2x16H};
    }
    for (var x in this) {
      var hours = x.interval.splitLeft((dt) => Hour.beginning(dt));
      for (var hour in hours) {
        for (var bucket in buckets) {
          if (bucket.containsHour(hour)) {
            _ts.add(IntervalTuple(hour, x.value[bucket]));
            break;
          }
        }
      }
    }
    return _ts;
  }

  /// Calculate the value for this curve for any term and any bucket.
  ///
  num value(Interval interval, Bucket bucket, {HourlyShape hourlyShape}) {
    if (hourlyShape != null) {
      throw ArgumentError('Not implemented yet');
    }
    if (!toHourly().domain.containsInterval(interval)) {
      throw ArgumentError('Forward curve not defined for the entire $interval');
    }
    var avg = 0.0;
    var i = 0;
    var xs = _ts.window(interval);
    for (var x in xs) {
      if (bucket.containsHour(x.interval)) {
        avg += x.value;
        i += 1;
      }
    }
    return avg / i;
  }

  /// Get the daily part of the curve.  Can be empty.  All intervals are
  /// [Date]s.
  PriceCurve dailyComponent() {
    return PriceCurve.fromIterable(where((e) => e.interval is Date));
  }

  /// Get the monthly part of the curve.  All intervals are [Month]s.
  PriceCurve monthlyComponent() {
    return PriceCurve.fromIterable(where((e) => e.interval is Month));
  }

  /// get the first month that is marked
  Month get firstMonth => firstWhere((e) => e.interval is Month).interval;

  /// If there are monthly marks before and including [upTo] month, expand them
  /// into to daily marks (same buckets.)
  PriceCurve expandToDaily(Month upTo) {
    var out = dailyComponent();
    var mCurve = monthlyComponent();
    for (var i = 0; i < mCurve.length; i++) {
      if ((mCurve[i].interval as Month).isAfter(upTo)) {
        out.add(mCurve[i]);
      } else {
        // split into daily curve
        var buckets = mCurve[i].value.keys;
        var dates = (mCurve[i].interval as Month).days();
        for (var date in dates) {
          var hours = date.hours();
          var value = <Bucket, num>{};
          for (var bucket in buckets) {
            for (var hour in hours) {
              if (bucket.containsHour(hour)) {
                value[bucket] = mCurve[i].value[bucket];
                break;
              }
            }
          }
          out.add(IntervalTuple(date, value));
        }
      }
    }
    return out;
  }

  /// Format this forward curve to a json format
  ///   [
  ///     {'term': '2020-07-17', 'value': {'5x16': 27.10, '7x8': 15.5}},
  ///     {'term': '2020-07-18', 'value': {'2x16H': 22.15, '7x8': 15.5}},
  ///     ...
  ///     {'term': '2020-08', 'value': {'5x16': 31.50, '2x16H': 25.15, '7x8': 18.75}},
  ///     ...
  ///   ]
  List<Map<String, dynamic>> toJson() {
    var out = <Map<String, dynamic>>[];
    for (var x in this) {
      var one = <String, dynamic>{};
      if (x.interval is Date) {
        one['term'] = (x.interval as Date).toString();
      } else if (x.interval is Month) {
        one['term'] = (x.interval as Month).toIso8601String();
      } else {
        throw ArgumentError('Unsupported term ${x.interval}');
      }
      one['value'] = {for (var e in x.value.entries) e.key.toString(): e.value};
      out.add(one);
    }
    return out;
  }

  /// Make the output ready for a spreadsheet.
  /// Understands only m/dd/yyyy format!
  String toCsv() {
    var dateFmt = DateFormat('M/dd/yyyy');
    var out = <Map<String, dynamic>>[];
    for (var x in this) {
      var one = <String, dynamic>{};
      if (x.interval is Date) {
        one['term'] = (x.interval as Date).toString(dateFmt);
      } else if (x.interval is Month) {
        one['term'] = (x.interval as Month).startDate.toString(dateFmt);
      } else {
        throw ArgumentError('Unsupported term ${x.interval}');
      }
      for (var entry in x.value.entries) {
        one[entry.key.toString()] = entry.value;
      }
      out.add(one);
    }
    return listOfMapToCsv(out);
  }

  /// Add two curves element by element.
  @override
  PriceCurve operator +(PriceCurve other) {
    var ys = merge(other, joinType: JoinType.Outer, f: (x, y) {
      if (x == null) return y as Map<Bucket, num>;
      if (y == null) return x;
      var out = <Bucket, num>{};
      for (var bucket in x.keys) {
        out[bucket] = x[bucket] + y[bucket];
      }
      return out;
    });

    return PriceCurve.fromIterable(ys.observations);
  }

  /// Subtract two curves element by element.
  PriceCurve operator -(PriceCurve other) {
    var ys = merge(other, joinType: JoinType.Outer, f: (x, y) {
      if (x == null) return y as Map<Bucket, num>;
      if (y == null) return x;
      var out = <Bucket, num>{};
      for (var bucket in x.keys) {
        out[bucket] = x[bucket] - y[bucket];
      }
      return out;
    });

    return PriceCurve.fromIterable(ys.observations);
  }

  /// Multiply two curves element by element.
  PriceCurve operator *(PriceCurve other) {
    var ys = merge(other, joinType: JoinType.Outer, f: (x, y) {
      if (x == null) return y as Map<Bucket, num>;
      if (y == null) return x;
      var out = <Bucket, num>{};
      for (var bucket in x.keys) {
        out[bucket] = x[bucket] * y[bucket];
      }
      return out;
    });

    return PriceCurve.fromIterable(ys.observations);
  }

  /// Divide two curves element by element.
  PriceCurve operator /(PriceCurve other) {
    var ys = merge(other, joinType: JoinType.Outer, f: (x, y) {
      if (x == null) return y as Map<Bucket, num>;
      if (y == null) return x;
      var out = <Bucket, num>{};
      for (var bucket in x.keys) {
        out[bucket] = x[bucket] / y[bucket];
      }
      return out;
    });

    return PriceCurve.fromIterable(ys.observations);
  }

  /// Extend this forward curve periodically by year.  That is, if the curve
  /// is defined only through Dec25, construct Jan26 by applying function [f]
  /// to Jan25 values, etc.  By default, function [f] is the identity function.
  PriceCurve extendPeriodicallyByYear(Month endMonth,
      {Map<Bucket, num> Function(Map<Bucket, num>) f}) {
    f ??= (x) => x;
    var n = length;
    var month = (intervals.last as Month).next;
    var fc = PriceCurve.fromIterable(this);
    while (!month.isAfter(endMonth)) {
      var value = fc.values.toList()[n - 12];
      fc.add(IntervalTuple(month, f(value)));
      month = month.next;
      n++;
    }
    return fc;
  }
}
