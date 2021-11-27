library test.risk_system.marks.forward_curve_test;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';

void tests() {
  group('Forward curve tests: ', () {
    var location = getLocation('America/New_York');
    var aux = File('test/risk_system/marks/marks_test.json').readAsStringSync();
    var xs = json.decode(aux) as List;
    // a power curve, daily and monthly, 3 buckets
    var x0 = (xs[0]['observations'] as List).cast<Map<String, dynamic>>();
    var curve0 = PriceCurve.fromJson(x0, location);
    // a gas curve, 7x24 bucket
    var x1 = (xs[1]['observations'] as List).cast<Map<String, dynamic>>();

    test('fromMongoDocument', () {
      var document = {
        'fromDate': '2020-08-17',
        'curveId': '1',
        'terms': ['2020-11-01', '2020-11-02', '2020-12', '2021-01', '2021-02'],
        'buckets': {
          '5x16': [null, 6, 7, 8, 9],
          '2x16H': [6.2, null, 7.2, 8.2, 9.2],
          '7x8': [2.1, 2.1, 3.1, 4.1, 5.1],
        }
      };
      var pc = PriceCurve.fromMongoDocument(document, UTC);
      expect(pc.length, 5);
      expect(pc[0].value, {Bucket.b2x16H: 6.2, Bucket.b7x8: 2.1});
      expect(pc[1].value, {Bucket.b5x16: 6, Bucket.b7x8: 2.1});
    });

    test('from the 3 standard buckets', () {
      expect(curve0.length, 13);
      expect(curve0.first.value.length, 2);
      expect(curve0.toJson(), x0);
    });
    test('from the flat bucket only', () {
      var curve = PriceCurve.fromJson(x1, location);
      expect(curve.length, 11);
      expect(curve.first.value.length, 1);
      expect(curve.toJson(), x1);
    });
    test('toMongoDocument', () {
      var out = curve0.toMongoDocument(
          Date.utc(2020, 10, 1), 'isone_energy_4000_da_lmp');
      expect(out['fromDate'], '2020-10-01');
      expect(out['curveId'], 'isone_energy_4000_da_lmp');
      expect((out['terms'] as List).length, 13);
      expect((out['terms'] as List).last, '2021-02');
      expect((out['buckets'] as Map).keys.toSet(), {'5x16', '2x16H', '7x8'});
    });
    test('filter only the monthly values', () {
      var curve0m =
          PriceCurve.fromIterable(curve0.where((e) => e.interval is Month));
      expect(curve0m.length, 7);
    });
    test('first month', () {
      expect(curve0.firstMonth, Month(2020, 8, location: location));
    });
    test('expand to daily', () {
      var curve0P1 = curve0.expandToDaily(Month(2020, 8, location: location));
      expect(curve0P1.length, 43);
      expect(curve0P1.monthlyComponent().first.interval,
          Month(2020, 9, location: location));
      var curve0P2 = curve0.expandToDaily(Month(2020, 9, location: location));
      expect(curve0P2.monthlyComponent().first.interval,
          Month(2020, 10, location: location));
    });
    test('expand to daily is idempotent', () {
      /// nothing to do here
      var curve0P1 = curve0.expandToDaily(Month(2020, 7, location: location));
      expect(curve0P1.length, curve0.length);
    });
    test('expand to daily a daily curve doesn\'t fail', () {
      var curve0d = curve0.dailyComponent();
      var curve2 = curve0d + curve0;
      expect(curve2.length, 6);
      expect(curve2.firstMonth, null);
      expect(curve2.first.value[Bucket.b2x16H], 55.0);
    });
    test('toHourly', () {
      var ts = curve0.toHourly();
      expect(
          ts.first.interval, Hour.beginning(TZDateTime(location, 2020, 7, 26)));
      expect(ts.last.interval, Hour.ending(TZDateTime(location, 2021, 3)));
      var n = Term.parse('26Jul20-28Feb21', location).hours().length;
      expect(ts.length, n);
    });
    test('calculate value for offpeak bucket (aggregate 2x16H, 7x8)', () {
      var month = Month(2020, 8, location: location);
      var value = curve0.value(month, Bucket.offpeak);
      expect(value.toStringAsFixed(4), '21.4216');
    });
    test('calculate value for peak bucket, term Q4,20 (aggregate months)', () {
      var term = Term.parse('Q4, 2020', location);
      var value = curve0.value(term.interval, Bucket.b5x16);
      expect(value.toStringAsFixed(4), '35.0625');
    });
    test('return NaN value if the bucket is not covered', () {
      var x3 = (xs[3]['observations'] as List).cast<Map<String, dynamic>>();
      var curve = PriceCurve.fromJson(x3, location);
      // this curve has only the 7x8 bucket
      var term = Term.parse('Q4, 2020', location);
      var value = curve.value(term.interval, Bucket.b2x16H);
      expect(value.isNaN, true);
    });
    test(
        'calculate value for offpeak bucket, term Q4,20 (aggregate months and buckets)',
        () {
      var term = Term.parse('Q4, 2020', location);
      var value = curve0.value(term.interval, Bucket.offpeak);
      expect(value.toStringAsFixed(4), '28.1768');
    });
    test(
        'calculate value for atc bucket, term 26Ju20-31Jul20 (aggregate months and buckets)',
        () {
      var term = Term.parse('26Jul20-31Jul20', location);
      var value = curve0.value(term.interval, Bucket.atc);
      expect(value.toStringAsFixed(4), '24.8889');
    });
    test('extend periodically by year', () {
      var x2 = (xs[2]['observations'] as List).cast<Map<String, dynamic>>();
      var curve = PriceCurve.fromJson(x2, location);
      var curveX =
          curve.extendPeriodicallyByYear(Month(2022, 12, location: location));
      expect(curveX.length, 29);
      expect(
          curveX
              .observationAt(Month(2022, 1, location: location))
              .value[Bucket.atc],
          3.11);
      expect(
          curveX
              .observationAt(Month(2022, 2, location: location))
              .value[Bucket.atc],
          3.12);
      expect(
          curveX
              .observationAt(Month(2022, 12, location: location))
              .value[Bucket.atc],
          3.16);
    });
    test('with intervals', () {
      var pc = PriceCurve.fromMongoDocument({
        'fromDate': '2020-08-17',
        'terms': ['2020-10', '2020-11', '2020-12', '2021-01', '2021-02'],
        'buckets': {
          '5x16': [5, 6, 7, 8, 9],
        }
      }, UTC);
      var intervals = [
        Date.utc(2020, 11, 1), // it's a Sun, won't show up in the output
        Date.utc(2020, 11, 2),
        Date.utc(2020, 11, 3),
        Date.utc(2020, 11, 4),
        Month.utc(2020, 12),
        Month.utc(2021, 1),
        Month.utc(2021, 2),
      ];
      var pc2 = pc.withIntervals(intervals);
      expect(pc2.length, 6);
      expect(pc2.first.interval, Date.utc(2020, 11, 2));
    });
    test('align two PriceCurves', () {
      var x = PriceCurve.fromJson([
        {
          'term': '2021-01-29',
          'value': {'5x16': 69, '7x8': 40}
        },
        {
          'term': '2021-01-30',
          'value': {'2x16H': 68, '7x8': 42}
        },
        {
          'term': '2021-01-31',
          'value': {'2x16H': 67, '7x8': 43}
        },
        {
          'term': '2021-02-13',
          'value': {'2x16H': 52, '7x8': 42}
        },
        {
          'term': '2021-03',
          'value': {'5x16': 53}
        },
        {
          'term': '2021-04',
          'value': {'5x16': 54}
        },
      ], UTC);
      var y = PriceCurve.fromJson([
        {
          'term': '2020-11',
          'value': {'5x16': 69.2}
        },
        {
          'term': '2020-12',
          'value': {'5x16': 68.2}
        },
        {
          'term': '2021-01',
          'value': {'5x16': 67.2, '2x16H': 65.2, '7x8': 40.2}
        },
        {
          'term': '2021-02',
          'value': {'5x16': 52.2, '2x16H': 47.2, '7x8': 36.2}
        },
        {
          'term': '2021-03',
          'value': {'5x16': 53.2}
        },
        {
          'term': '2021-04',
          'value': {'5x16': 54.2}
        },
        {
          'term': '2021-05',
          'value': {'5x16': 55.2}
        },
        {
          'term': '2021-06',
          'value': {'5x16': 56.2}
        },
      ], UTC);
      var out = x.align(y);
      expect(out.length, 6);
      expect(out.intervals.toList(), [
        Date.utc(2021, 1, 29),
        Date.utc(2021, 1, 30),
        Date.utc(2021, 1, 31),
        Date.utc(2021, 2, 13),
        Month.utc(2021, 3),
        Month.utc(2021, 4),
      ]);
      expect(out.values.first.item1, {Bucket.b5x16: 69, Bucket.b7x8: 40});
      expect(out.values.first.item2, {Bucket.b5x16: 67.2, Bucket.b7x8: 40.2});
    });

    test('add two forward curves element by element', () {
      var c1 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1),
            {Bucket.b5x16: 60, Bucket.b2x16H: 50, Bucket.b7x8: 45}),
        IntervalTuple(Month.utc(2020, 2),
            {Bucket.b5x16: 57, Bucket.b2x16H: 48, Bucket.b7x8: 41}),
        IntervalTuple(Month.utc(2020, 3),
            {Bucket.b5x16: 47, Bucket.b2x16H: 36, Bucket.b7x8: 29}),
      ]);
      var c2 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1),
            {Bucket.b5x16: 0.1, Bucket.b2x16H: 0.11, Bucket.b7x8: 0.21}),
        IntervalTuple(Month.utc(2020, 2),
            {Bucket.b5x16: 0.2, Bucket.b2x16H: 0.12, Bucket.b7x8: 0.22}),
        IntervalTuple(Month.utc(2020, 3),
            {Bucket.b5x16: 0.3, Bucket.b2x16H: 0.13, Bucket.b7x8: 0.23}),
      ]);
      var c3 = c1 + c2;
      expect(c3.length, 3);
      expect(c3.first.interval, Month.utc(2020, 1));
      expect(c3.first.value,
          {Bucket.b5x16: 60.1, Bucket.b2x16H: 50.11, Bucket.b7x8: 45.21});
    });
    test('add two price curves, non-matching terms with expansion', () {
      var c1 = PriceCurve.fromIterable([
        IntervalTuple(Date.utc(2020, 1, 29), {Bucket.b5x16: 60}),
        IntervalTuple(Date.utc(2020, 1, 30), {Bucket.b5x16: 61}),
        IntervalTuple(Date.utc(2020, 1, 31), {Bucket.b5x16: 62}),
        IntervalTuple(Month.utc(2020, 2), {Bucket.b5x16: 57}),
        IntervalTuple(Month.utc(2020, 3), {Bucket.b5x16: 47}),
      ]);
      var c2 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1), {Bucket.b5x16: 0.1}),
        IntervalTuple(Month.utc(2020, 2), {Bucket.b5x16: 0.2}),
        IntervalTuple(Month.utc(2020, 3), {Bucket.b5x16: 0.3}),
      ]);
      var c3 = c1 + c2;
      expect(c3.length, 5);
      expect(c3.first.interval, Date.utc(2020, 1, 29));
      expect(c3[0].value, {Bucket.b5x16: 60.1});
      expect(c3[1].value, {Bucket.b5x16: 61.1});
      expect(c3[2].value, {Bucket.b5x16: 62.1});
      expect(c3[3].value, {Bucket.b5x16: 57.2});
    });
    test('add two price curves, non-matching terms with expansion', () {
      var c1 = PriceCurve.fromIterable([
        IntervalTuple(Date.utc(2020, 1, 29), {Bucket.b5x16: 60}),
        IntervalTuple(Month.utc(2020, 2), {Bucket.b5x16: 57}),
        IntervalTuple(Month.utc(2020, 3), {Bucket.b5x16: 47}),
      ]);
      var c2 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1), {Bucket.b5x16: 0.1}),
        IntervalTuple(Month.utc(2020, 2), {Bucket.b5x16: 0.2}),
        IntervalTuple(Month.utc(2020, 3), {Bucket.b5x16: 0.3}),
      ]);
      var c3 = c1 + c2;
      expect(c3.length, 3);
      expect(c3.first.interval, Date.utc(2020, 1, 29));
      expect(c3[0].value, {Bucket.b5x16: 60.1});
      expect(c3[1].value, {Bucket.b5x16: 57.2});
    });

    test('subtract two forward curves element by element', () {
      var c1 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1),
            {Bucket.b5x16: 60, Bucket.b2x16H: 50, Bucket.b7x8: 45}),
        IntervalTuple(Month.utc(2020, 2),
            {Bucket.b5x16: 57, Bucket.b2x16H: 48, Bucket.b7x8: 41}),
        IntervalTuple(Month.utc(2020, 3),
            {Bucket.b5x16: 47, Bucket.b2x16H: 36, Bucket.b7x8: 29}),
      ]);
      var c2 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1),
            {Bucket.b5x16: 0.1, Bucket.b2x16H: 0.11, Bucket.b7x8: 0.21}),
        IntervalTuple(Month.utc(2020, 2),
            {Bucket.b5x16: 0.2, Bucket.b2x16H: 0.12, Bucket.b7x8: 0.22}),
        IntervalTuple(Month.utc(2020, 3),
            {Bucket.b5x16: 0.3, Bucket.b2x16H: 0.13, Bucket.b7x8: 0.23}),
      ]);
      var c3 = c1 - c2;
      expect(c3.length, 3);
      expect(c3.first.interval, Month.utc(2020, 1));
      expect(c3.first.value,
          {Bucket.b5x16: 59.9, Bucket.b2x16H: 49.89, Bucket.b7x8: 44.79});
    });
    test('multiply two forward curves element by element', () {
      var c1 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1),
            {Bucket.b5x16: 60, Bucket.b2x16H: 50, Bucket.b7x8: 45}),
        IntervalTuple(Month.utc(2020, 2),
            {Bucket.b5x16: 57, Bucket.b2x16H: 48, Bucket.b7x8: 41}),
        IntervalTuple(Month.utc(2020, 3),
            {Bucket.b5x16: 47, Bucket.b2x16H: 36, Bucket.b7x8: 29}),
      ]);
      var c2 = PriceCurve.fromIterable([
        IntervalTuple(Month.utc(2020, 1),
            {Bucket.b5x16: 2, Bucket.b2x16H: 5, Bucket.b7x8: 3}),
        IntervalTuple(Month.utc(2020, 2),
            {Bucket.b5x16: 0.2, Bucket.b2x16H: 0.12, Bucket.b7x8: 0.22}),
        IntervalTuple(Month.utc(2020, 3),
            {Bucket.b5x16: 0.3, Bucket.b2x16H: 0.13, Bucket.b7x8: 0.23}),
      ]);
      var c3 = c1 / c2;
      expect(c3.length, 3);
      expect(c3.first.interval, Month.utc(2020, 1));
      expect(c3.first.value,
          {Bucket.b5x16: 30, Bucket.b2x16H: 10, Bucket.b7x8: 15});
    });
  });
}

/// As of 2021-11-28, desktop Intel i7-6700 CPU @ 3.40GHz x 8, Ubuntu 16.04
/// 100 times, all 3 buckets take 40 ms.
/// Bucket 5x16 alone takes 26 ms
/// Bucket atc alone takes 32 ms
/// Bucket offpeak alone takes 24 ms
void speedTest() {
  var location = getLocation('America/New_York');
  var aux = File('test/risk_system/marks/marks_test.json').readAsStringSync();
  var xs = json.decode(aux) as List;
  var x0 = (xs[0]['observations'] as List).cast<Map<String, dynamic>>();
  var curve0 = PriceCurve.fromJson(x0, location);
  var term = Term.parse('Q4, 2020', location);
  late num v1, v2, v3;
  var sw = Stopwatch()..start();
  for (var i = 0; i < 100; i++) {
    v2 = curve0.value(term.interval, Bucket.atc);
    v1 = curve0.value(term.interval, Bucket.b5x16);
    v3 = curve0.value(term.interval, Bucket.offpeak);
  }
  sw.stop();
  print(sw.elapsedMilliseconds);
  print(v3);
}

void main() async {
  initializeTimeZones();
  // tests();
  speedTest();
}
