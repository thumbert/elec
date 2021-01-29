library test.risk_system.marks.volatility_surface_test;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';

Map<String, dynamic> _getJson() {
  return {
    'terms': [
      '2020-08',
      '2020-09',
      '2020-10',
      '2020-11',
      '2020-12',
      '2021-01',
      '2021-02',
      '2021-03',
      '2021-04',
      '2021-05',
      '2021-06',
      '2021-07'
    ],
    'strikeRatios': [0.5, 1, 2.0],
    'buckets': {
      '5x16': [
        [0.50, 0.55, 0.70],
        [0.40, 0.45, 0.60],
        [0.37, 0.40, 0.55],
        [0.45, 0.5, 0.65],
        [0.45, 0.5, 0.65],
        [0.95, 1.05, 1.25],
        [0.95, 1.05, 1.25],
        [0.75, 0.95, 1.05],
        [0.45, 0.5, 0.65],
        [0.45, 0.5, 0.65],
        [0.45, 0.5, 0.65],
        [0.50, 0.55, 0.70]
      ],
      '2x16H': [
        [0.45, 0.50, 0.60],
        [0.44, 0.49, 0.59],
        [0.43, 0.48, 0.58],
        [0.42, 0.47, 0.57],
        [0.41, 0.46, 0.56],
        [0.40, 0.45, 0.55],
        [0.39, 0.44, 0.54],
        [0.38, 0.43, 0.53],
        [0.37, 0.43, 0.53],
        [0.36, 0.43, 0.53],
        [0.35, 0.43, 0.53],
        [0.34, 0.43, 0.53],
      ],
      '7x8': [
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
        [0.34, 0.43, 0.53],
      ],
    }
  };
}

Map<Tuple2<Bucket, num>, TimeSeries<num>> _getTimeSeries() {
  var months = Term.parse('Aug20-Jul21', UTC)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt));
  return {
    Tuple2(Bucket.b5x16, 1): TimeSeries.from(months, [
      0.55,
      0.45,
      0.4,
      0.5,
      0.5,
      1.05,
      1.05,
      0.95,
      0.5,
      0.5,
      0.5,
      0.55,
    ]),
    Tuple2(Bucket.b5x16, 2): TimeSeries.from(months, [
      0.7,
      0.6,
      0.55,
      0.65,
      0.65,
      1.25,
      1.25,
      1.05,
      0.65,
      0.65,
      0.65,
      0.7,
    ]),
  };
}

void tests() {
  group('Volatility surface tests: ', () {
    var location = getLocation('America/New_York');
    var vs = VolatilitySurface.fromJson(_getJson(), location: location);
    test('from TimeSeries', () {
      var vs = VolatilitySurface.fromTimeSeries(_getTimeSeries());
      var ts = vs.value(Bucket.b5x16, Month(2020, 8), 1.5);
      expect(ts, 0.625);
    });
    test('from Json', () {
      expect(vs.buckets, {Bucket.b5x16, Bucket.b2x16H, Bucket.b7x8});
      expect(vs.terms.first, Month(2020, 8, location: location));
      expect(vs.terms.last, Month(2021, 7, location: location));
      expect(vs.strikeRatios, [0.5, 1, 2]);
      var ts = vs.value(Bucket.b5x16, Month(2020, 8, location: location), 1);
      expect(ts, 0.55);
    });
    test('toJson', () {
      var out = vs.toJson();
      expect(out['strikeRatios'], [0.5, 1, 2.0]);
      expect((out['buckets'] as Map).keys.toSet(), {
        '5x16',
        '2x16H',
        '7x8',
      });
      var terms = out['terms'] as List;
      expect(terms.first, '2020-08');
      expect(terms.last, '2021-07');
      expect(out['buckets']['5x16'].first, [0.5, 0.55, 0.7]);
    });
    test('volatility value', () {
      var v0 = vs.value(Bucket.b5x16, Month(2020, 10, location: location), 1);
      expect(v0, 0.4);
    });
    test('interpolate strikeRatios for volatility value', () {
      // vol is marked only for [0.5, 1, 2] strike ratios
      expect(
          vs.value(Bucket.b5x16, Month(2020, 8, location: location), 0.3), 0.5);
      expect(vs.value(Bucket.b5x16, Month(2020, 8, location: location), 1.5),
          0.625);
      expect(
          vs.value(Bucket.b5x16, Month(2020, 8, location: location), 2.2), 0.7);
    });

    test('extend periodically by year', () {
      var vsX = vs.extendPeriodicallyByYear(Month(2022, 12, location: location),
          f: (x) => 0.9 * x);
      expect(vsX.terms.length, 29);
      var v1 = vsX.getVolatilityCurve(Bucket.b5x16, 1.0);
      expect(
          v1
              .observationAt(Month(2021, 8, location: location))
              .value
              .toStringAsFixed(3),
          '0.495');
      expect(v1.intervals.last, Month(2022, 12, location: location));
      expect(
          v1
              .observationAt(Month(2022, 12, location: location))
              .value
              .toStringAsFixed(3),
          '0.405');
    });
    test('window', () {
      vs.window(Term.parse('Oct20-Dec20', location).interval);
      expect(vs.terms.first, Month(2020, 10, location: location));
      expect(vs.terms.last, Month(2020, 12, location: location));
    });
  });
}

void main() async {
  await initializeTimeZone();
  tests();
}
