part of elec.risk_system;

class PriceCurve extends TimeSeries<Map<Bucket, num>> with MarksCurve {
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

  /// A simple forward curve model for daily and monthly values extending
  /// a TimeSeries<Map<Bucket,num>>.  There are no gaps in the observations.
  PriceCurve();

  /// A simple forward curve model for daily and monthly values extending
  /// a TimeSeries<Map<Bucket,num>>.  There are no gaps in the observations.
  /// Support only daily and monthly observations.
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

  /// Input document is of this form
  /// ```
  /// {
  ///   'terms': ['2020-01-15', ... '2020-02', ...],
  ///   'buckets': {
  ///     '5x16': [81.5, 80.17, ...],
  ///     '2x16H': [70.2, 67.32, ...],
  ///     '7x8': [45.7, 42.81, ...],
  ///   }
  /// }
  /// ```
  PriceCurve.fromMongoDocument(
      Map<String, dynamic> document, Location location) {
    var buckets = {
      for (String b in document['buckets'].keys) b: Bucket.parse(b)
    };
    final bKeys = buckets.keys.toList();
    var terms = document['terms'] as List;
    var xs = <IntervalTuple<Map<Bucket, num>>>[];
    for (var i = 0; i < terms.length; i++) {
      var value = <Bucket, num>{};
      for (var bucket in bKeys) {
        num v = document['buckets'][bucket][i];
        if (v != null) {
          value[buckets[bucket]] = v;
        }
      }
      ;
      Interval term;
      if (terms[i].length == 7) {
        term = Month.parse(terms[i], location: location);
      } else if (terms[i].length == 10) {
        term = Date.parse(terms[i], location: location);
      } else {
        throw ArgumentError('Unsupported term ${terms[i]}');
      }
      xs.add(IntervalTuple(term, value));
    }
    addAll(xs);
  }

  @override
  Set<Bucket> get buckets {
    _buckets ??= values.map((e) => e.keys).expand((e) => e).toSet();
    return _buckets;
  }

  Set<Bucket> _buckets;

  /// an hourly timeseries cache
  TimeSeries<num> _ts;

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
  /// [Date]s.  Can be empty.
  PriceCurve dailyComponent() {
    return PriceCurve.fromIterable(where((e) => e.interval is Date));
  }

  /// Get the monthly part of the curve.  All intervals are [Month]s.
  /// Can be empty.
  PriceCurve monthlyComponent() {
    return PriceCurve.fromIterable(where((e) => e.interval is Month));
  }

  /// get the first month that is marked
  Month get firstMonth {
    var aux = firstWhere((e) => e.interval is Month, orElse: () => null);
    if (aux == null) return null;
    return aux.interval;
  }

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
          if (value.isNotEmpty) out.add(IntervalTuple(date, value));
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

  /// Construct a Mongo document from a [PriceCurve].
  /// ```
  /// {
  ///   'fromDate': '2020-06-15',
  ///   'curveId': 'elec_isone_4011_lmp_da',
  ///   'terms': ['2020-06-16', ..., '2020-07', '2020-08', ..., '2026-12'],
  ///   'buckets': {
  ///     '5x16': [27.10, 26.25, ...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
  /// }
  ///```
  @override
  Map<String, dynamic> toMongoDocument(Date fromDate, String curveId) {
    var _buckets = values.map((e) => e.keys).expand((e) => e).toSet();
    var terms = <String>[];
    var buckets = Map.fromIterables(_buckets.map((e) => e.name),
        List.generate(_buckets.length, (index) => <num>[]));
    for (var obs in observations) {
      if (obs.interval is Month) {
        Month month = obs.interval;
        terms.add(month.toIso8601String());
      } else {
        terms.add(obs.interval.toString());
      }
      for (var bucket in _buckets) {
        buckets[bucket.name].add(obs.value[bucket]);
      }
    }
    return {
      'fromDate': fromDate.toString(),
      'curveId': curveId,
      'terms': terms,
      'buckets': buckets,
    };
  }

  /// Return a time series after aligning this price curve with the [other]
  /// price curve.  They now have the same terms (if possible).  For example,
  /// one may had to expand some of the monthly marks to daily, etc.  Only the
  /// overlapping terms are returned.
  TimeSeries<Tuple2<Map<Bucket, num>, Map<Bucket, num>>> align(
      PriceCurve other) {
    // align their domains first
    var domainY = Interval(
        Month.fromTZDateTime(other.domain.start).start, other.domain.end);
    var x = PriceCurve.fromIterable(window(domainY));
    var domainX =
        Interval(Month.fromTZDateTime(domain.start).start, domain.end);
    var y = PriceCurve.fromIterable(other.window(domainX));

    // expand to daily marks as needed
    var m0x = x.firstMonth;
    var m0y = y.firstMonth;
    if (m0x != null && m0y != null) {
      if (m0x.isBefore(m0y)) {
        x = x.expandToDaily(m0y.previous);
      } else if (m0y.isBefore(m0x)) {
        y = y.expandToDaily(m0x.previous);
      }
    }

    // do an inner join
    return x.merge(y, f: (a, b) => Tuple2(a, b));
  }

  /// Create a new price curve from this one using a list of intervals.  This
  /// is useful if the curve is needed with different granularity.
  /// TODO: make it more efficient
  PriceCurve withIntervals(List<Interval> intervals) {
    var aux = align(PriceCurve.fromIterable(
        intervals.map((e) => IntervalTuple(e, {Bucket.atc: 1}))));

    return PriceCurve.fromIterable(
        aux.map((e) => IntervalTuple(e.interval, e.value.item1)));
  }

  /// Add two curves observation by observation and bucket by bucket.
  /// If the curves don't match buckets, nothing is done (strict).
  /// If any of the values is null, return null for that term/bucket.
  @override
  PriceCurve operator +(PriceCurve other) {
    var zs = align(other);
    var out = PriceCurve();
    for (var z in zs) {
      var x = z.value.item1;
      var y = z.value.item2;
      var buckets = {...x.keys, ...y.keys};
      var one = <Bucket, num>{};
      for (var bucket in buckets) {
        if (x.containsKey(bucket) && y.containsKey(bucket)) {
          if (x[bucket] == null || y[bucket] == null) {
            one[bucket] = null;
          } else {
            one[bucket] = x[bucket] + y[bucket];
          }
        }
      }
      out.add(IntervalTuple(z.interval, one));
    }
    return out;
  }

  /// Subtract two curves element by element.
  /// If the curves don't match buckets, nothing is done (strict).
  PriceCurve operator -(PriceCurve other) {
    var zs = align(other);
    var out = PriceCurve();
    for (var z in zs) {
      var x = z.value.item1;
      var y = z.value.item2;
      var buckets = {...x.keys, ...y.keys};
      var one = <Bucket, num>{};
      for (var bucket in buckets) {
        if (x.containsKey(bucket) && y.containsKey(bucket)) {
          if (x[bucket] == null || y[bucket] == null) {
            one[bucket] = null;
          } else {
            one[bucket] = x[bucket] - y[bucket];
          }
        }
      }
      out.add(IntervalTuple(z.interval, one));
    }
    return out;
  }

  /// Multiply two curves element by element.
  /// If the curves don't match buckets, nothing is done (strict).
  PriceCurve operator *(PriceCurve other) {
    var zs = align(other);
    var out = PriceCurve();
    for (var z in zs) {
      var x = z.value.item1;
      var y = z.value.item2;
      var buckets = {...x.keys, ...y.keys};
      var one = <Bucket, num>{};
      for (var bucket in buckets) {
        if (x.containsKey(bucket) && y.containsKey(bucket)) {
          if (x[bucket] == null || y[bucket] == null) {
            one[bucket] = null;
          } else {
            one[bucket] = x[bucket] * y[bucket];
          }
        }
      }
      out.add(IntervalTuple(z.interval, one));
    }
    return out;
  }

  /// Divide two curves element by element.
  /// If the curves don't match buckets, nothing is done (strict).
  PriceCurve operator /(PriceCurve other) {
    var zs = align(other);
    var out = PriceCurve();
    for (var z in zs) {
      var x = z.value.item1;
      var y = z.value.item2;
      var buckets = {...x.keys, ...y.keys};
      var one = <Bucket, num>{};
      for (var bucket in buckets) {
        if (x.containsKey(bucket) && y.containsKey(bucket)) {
          if (x[bucket] == null || y[bucket] == null) {
            one[bucket] = null;
          } else {
            one[bucket] = x[bucket] / y[bucket];
          }
        }
      }
      out.add(IntervalTuple(z.interval, one));
    }
    return out;
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
