part of elec.risk_system;

class VolatilitySurface extends MarksCurve {
  /// The [xs] keys are strike ratios.  No checks are made to guarantee that
  /// all [TimeSeries] have the same domain.
  VolatilitySurface.fromTimeSeries(
      Map<Tuple2<Bucket, num>, TimeSeries<num>> xs) {
    _strikeRatios = xs.keys.map((e) => e.item2).toList();
    _strikeRatios.sort();
    _terms = xs.values.first.intervals.toList().cast<Month>();

    _data = <Bucket, Map<num/*!*/, TimeSeries<num>/*!*/>>{};
    for (var key in xs.keys) {
      var bucket = key.item1;
      if (!_data.containsKey(bucket)) {
        _data[bucket] = <num/*!*/, TimeSeries<num>/*!*/>{};
      }
      var strikeRatio = key.item2;
      _data[bucket]/*!*/[strikeRatio] = xs[key];
    }
  }

  /// Construct a forward curve given an input in this form.
  ///   [
  ///     {'term': '2020-07', 'strikeRatio': 1, 'bucket': '5x16', 'value': 67.10},
  ///     {'term': '2020-07', 'strikeRatio': 1.5, 'bucket': '5x16', 'value': 70.15},
  ///     ...
  ///   ]
  ///   The inputs are time-ordered with no gaps.  Strike ratio of 1
  ///   (at the money), must always be there.
  VolatilitySurface.fromIterable(List<Map<String, dynamic>> xs,
      {Location location}) {
    _data = <Bucket, Map<num/*!*/, TimeSeries<num>/*!*/>>{};

    for (var x in xs) {
      var bucket = Bucket.parse(x['bucket']);
      if (!_data.containsKey(bucket)) {
        _data[bucket] = <num/*!*/, TimeSeries<num>/*!*/>{};
      }
      num/*!*/ strikeRatio = x['strikeRatio'];
      if (!_data[bucket]/*!*/.containsKey(strikeRatio)) {
        _data[bucket]/*!*/[strikeRatio] = TimeSeries<num>();
      }
      var month = Month.parse(x['term'], location: location);
      _data[bucket]/*!*/[strikeRatio]/*!*/.add(IntervalTuple(month, x['value'] as num/*!*/));
    }
    // FIXME: why get the 1.0?
    _terms = _data.values.first[1.0].intervals.map((e) => e as Month).toList();
    _strikeRatios = _data.values.first.keys.toList();
    _strikeRatios.sort();
  }

  /// The opposite of [toJson] method.
  /// ```
  /// {
  ///   'terms': ['2020-07', '2020-08', ..., '2026-12'],
  ///   'strikeRatio': [0.5, 1, 2]
  ///   'buckets': {
  ///     '5x16': [
  ///        [48.5, 51.2, 54.7],  // for 2020-07, strikeRatio: 0.5, 1, 2
  ///        ...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
  /// }
  ///```
  VolatilitySurface.fromJson(Map<String, dynamic> x, {Location location}) {
    _strikeRatios = (x['strikeRatios'] as List).cast<num>();
    _terms = (x['terms'] as List)
        .map((e) => Month.parse(e, location: location))
        .toList();
    var keys = (x['buckets'] as Map).keys;
    _data = <Bucket, Map<num, TimeSeries<num>>>{};
    for (String _bucket in keys) {
      var y = (x['buckets'][_bucket] as List).cast<List>();
      var bucket = Bucket.parse(_bucket);
      _data[bucket] = <num, TimeSeries<num>>{};
      for (var j = 0; j < _strikeRatios.length; j++) {
        var ts = TimeSeries<num>();
        // populate it
        for (var i = 0; i < _terms.length; i++) {
          ts.add(IntervalTuple(_terms[i], y[i][j] as num));
        }
        _data[bucket][_strikeRatios[j]] = ts;
      }
    }
  }

  /// The inner map has strikeRatios as keys.  The timeseries are all monthly.
  Map<Bucket, Map<num, TimeSeries<num>/*!*/>> _data;

  List<num>/*!*//*!*//*!*/ _strikeRatios;

  /// Strike ratios = StrikePrice/FwdPrice.  The list is ordered increasingly.
  List<num> get strikeRatios => _strikeRatios;

  List<Month>/*!*/ _terms;
  List<Month>/*!*/ get terms => _terms;

  @override
  Set<Bucket> get buckets => _data.keys.toSet();

  /// Calculate the volatility value for a given month and strikeRatio
  /// by linear interpolation for now.  If the [strikeRatio] is below
  /// the marked values, return the first marked value.  If the [strikeRatio]
  /// is above the marked values, return the last marked value.
  ///
  /// Will throw if the bucket or month doesn't exist.
  num value(Bucket bucket, Month month, num strikeRatio) {
    if (strikeRatio <= strikeRatios.first) {
      return _data[bucket][strikeRatios.first].observationAt(month).value;
    } else if (strikeRatio >= strikeRatios.last) {
      return _data[bucket][strikeRatios.last].observationAt(month).value;
    }
    // for sure iMin will now have a value that works
    var iMin = strikeRatios.lastIndexWhere((e) => e <= strikeRatio);
    if (strikeRatios[iMin] == strikeRatio) {
      /// perfect hit, no interpolation needed
      return _data[bucket][strikeRatio].observationAt(month).value;
    }

    /// interpolate linearly
    var xMin = strikeRatios[iMin];
    var xMax = strikeRatios[iMin + 1];
    var vMin = _data[bucket][xMin].observationAt(month).value;
    var vMax = _data[bucket][xMax].observationAt(month).value;
    var slope = (vMax - vMin) / (xMax - xMin);
    return slope * (strikeRatio - xMin) + vMin;
  }

  /// Get the entire volatility forward curve for a given bucket and strikeRatio
  TimeSeries<num> getVolatilityCurve(Bucket bucket, num strikeRatio) {
    return TimeSeries.fromIterable(terms.map(
        (month) => IntervalTuple(month, value(bucket, month, strikeRatio))));
  }

  /// Format this forward curve to a compact json format.
  /// ```
  /// {
  ///   'terms': ['2020-07', '2020-08', ..., '2026-12'],
  ///   'strikeRatio': [0.5, 1, 2]
  ///   'buckets': {
  ///     '5x16': [
  ///        [48.5, 51.2, 54.7],  // for 2020-07, strikeRatio: 0.5, 1, 2
  ///        ...],
  ///     '2x16H': [...],
  ///     '7x8': [...],
  ///   }
  /// }
  ///```
  Map<String, dynamic> toJson() {
    var out = <String, dynamic>{
      'terms': terms.map((e) => e.toIso8601String()).toList(),
      'strikeRatios': strikeRatios,
      'buckets': {for (var bucket in buckets) bucket.toString(): <List<num>>[]},
    };
    for (var bucket in _data.keys) {
      var _bucket = bucket.toString();
      for (var j = 0; j < terms.length; j++) {
        var one = <num>[];
        for (var strikeRatio in strikeRatios) {
          var xs = _data[bucket][strikeRatio];
          one.add(xs[j].value);
        }
        out['buckets'][_bucket].add(one);
      }
    }
    return out;
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Extend this forward curve periodically by year.  That is, if the curve
  /// is defined only through Dec25, construct Jan26 by applying function [f]
  /// to Jan25 values, etc.  By default, function [f] is the identity function.
  VolatilitySurface extendPeriodicallyByYear(Month endMonth,
      {num Function(num) f}) {
    f ??= (x) => x;
    var n = terms.length;
    var month = terms.last.next;
    var xs = toJson();
    while (!month.isAfter(endMonth)) {
      xs['terms'].add(month.toIso8601String());
      for (var bucket in buckets) {
        var values = xs['buckets'][bucket.toString()] as List;
        var row = (values[n - 12] as List).map((e) => f(e)).toList();
        xs['buckets'][bucket.toString()].add(row);
      }
      month = month.next;
      n++;
    }
    return VolatilitySurface.fromJson(xs, location: terms.first.location);
  }

  /// Truncate this volatility surface to the given [interval].
  void window(Interval interval) {
    for (var bucket in buckets) {
      for (var strikeRatio in strikeRatios) {
        _data[bucket][strikeRatio] = TimeSeries.fromIterable(
            _data[bucket][strikeRatio].window(interval));
      }
    }
    _terms = _terms.where((month) => interval.containsInterval(month)).toList();
  }

  @override
  Map<String, dynamic> toMongoDocument(Date fromDate, String curveId) {
    return {
      'fromDate': fromDate.toString(),
      'curveId': curveId,
      ...toJson(),
    };
  }
}
