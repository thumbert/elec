library test.risk_system.marks.forward_curve_test;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/risk_system/marks/forward_curve.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Forward curve tests: ', () {
    var location = getLocation('America/New_York');
    var aux = File('test/risk_system/marks/marks_test.json').readAsStringSync();
    var xs = json.decode(aux) as List;
    // a power curve, daily and monthly, 3 buckets
    var x0 = (xs[0]['observations'] as List).cast<Map<String, dynamic>>();
    var curve0 = ForwardCurve.fromJson(x0, location);
    // a gas curve, 7x24 bucket
    var x1 = (xs[1]['observations'] as List).cast<Map<String, dynamic>>();
    test('from the 3 standard buckets', () {
      expect(curve0.length, 11);
      expect(curve0.first.value.length, 2);
      expect(curve0.toJson(), x0);
    });
    test('from the flat bucket only', () {
      var curve = ForwardCurve.fromJson(x1, location);
      expect(curve.length, 11);
      expect(curve.first.value.length, 1);
      expect(curve.toJson(), x1);
    });
    test('filter only the monthly values', () {
      var curve0m =
          ForwardCurve.fromIterable(curve0.where((e) => e.interval is Month));
      expect(curve0m.length, 5);
    });
    test('expand to daily', () {
      var curve0P1 = curve0.expandToDaily(Month(2020, 8, location: location));
      expect(curve0P1.length, 41);
      expect(curve0P1.monthlyComponent().first.interval,
          Month(2020, 9, location: location));
      var curve0P2 = curve0.expandToDaily(Month(2020, 9, location: location));
      expect(curve0P2.monthlyComponent().first.interval,
          Month(2020, 10, location: location));
    });
    test('toHourly', () {
      var ts = curve0.toHourly();
      expect(
          ts.first.interval, Hour.beginning(TZDateTime(location, 2020, 7, 26)));
      expect(ts.last.interval, Hour.ending(TZDateTime(location, 2021)));
      var n = Term.parse('26Jul20-31Dec20', location).hours().length;
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
    test('add two forward curves element by element', () {
      var c1 = ForwardCurve.fromIterable([
        IntervalTuple(Month(2020, 1),
            {Bucket.b5x16: 60, Bucket.b2x16H: 50, Bucket.b7x8: 45}),
        IntervalTuple(Month(2020, 2),
            {Bucket.b5x16: 57, Bucket.b2x16H: 48, Bucket.b7x8: 41}),
        IntervalTuple(Month(2020, 3),
            {Bucket.b5x16: 47, Bucket.b2x16H: 36, Bucket.b7x8: 29}),
      ]);
      var c2 = ForwardCurve.fromIterable([
        IntervalTuple(Month(2020, 1),
            {Bucket.b5x16: 0.1, Bucket.b2x16H: 0.11, Bucket.b7x8: 0.21}),
        IntervalTuple(Month(2020, 2),
            {Bucket.b5x16: 0.2, Bucket.b2x16H: 0.12, Bucket.b7x8: 0.22}),
        IntervalTuple(Month(2020, 3),
            {Bucket.b5x16: 0.3, Bucket.b2x16H: 0.13, Bucket.b7x8: 0.23}),
      ]);
      var c3 = c1 + c2;
      expect(c3.length, 3);
      expect(c3.first.interval, Month(2020, 1));
      expect(c3.first.value,
          {Bucket.b5x16: 60.1, Bucket.b2x16H: 50.11, Bucket.b7x8: 45.21});
    });
    test('subtract two forward curves element by element', () {
      var c1 = ForwardCurve.fromIterable([
        IntervalTuple(Month(2020, 1),
            {Bucket.b5x16: 60, Bucket.b2x16H: 50, Bucket.b7x8: 45}),
        IntervalTuple(Month(2020, 2),
            {Bucket.b5x16: 57, Bucket.b2x16H: 48, Bucket.b7x8: 41}),
        IntervalTuple(Month(2020, 3),
            {Bucket.b5x16: 47, Bucket.b2x16H: 36, Bucket.b7x8: 29}),
      ]);
      var c2 = ForwardCurve.fromIterable([
        IntervalTuple(Month(2020, 1),
            {Bucket.b5x16: 0.1, Bucket.b2x16H: 0.11, Bucket.b7x8: 0.21}),
        IntervalTuple(Month(2020, 2),
            {Bucket.b5x16: 0.2, Bucket.b2x16H: 0.12, Bucket.b7x8: 0.22}),
        IntervalTuple(Month(2020, 3),
            {Bucket.b5x16: 0.3, Bucket.b2x16H: 0.13, Bucket.b7x8: 0.23}),
      ]);
      var c3 = c1 - c2;
      expect(c3.length, 3);
      expect(c3.first.interval, Month(2020, 1));
      expect(c3.first.value,
          {Bucket.b5x16: 59.9, Bucket.b2x16H: 49.89, Bucket.b7x8: 44.79});
    });
    test('multiply two forward curves element by element', () {
      var c1 = ForwardCurve.fromIterable([
        IntervalTuple(Month(2020, 1),
            {Bucket.b5x16: 60, Bucket.b2x16H: 50, Bucket.b7x8: 45}),
        IntervalTuple(Month(2020, 2),
            {Bucket.b5x16: 57, Bucket.b2x16H: 48, Bucket.b7x8: 41}),
        IntervalTuple(Month(2020, 3),
            {Bucket.b5x16: 47, Bucket.b2x16H: 36, Bucket.b7x8: 29}),
      ]);
      var c2 = ForwardCurve.fromIterable([
        IntervalTuple(Month(2020, 1),
            {Bucket.b5x16: 2, Bucket.b2x16H: 5, Bucket.b7x8: 3}),
        IntervalTuple(Month(2020, 2),
            {Bucket.b5x16: 0.2, Bucket.b2x16H: 0.12, Bucket.b7x8: 0.22}),
        IntervalTuple(Month(2020, 3),
            {Bucket.b5x16: 0.3, Bucket.b2x16H: 0.13, Bucket.b7x8: 0.23}),
      ]);
      var c3 = c1 / c2;
      expect(c3.length, 3);
      expect(c3.first.interval, Month(2020, 1));
      expect(c3.first.value,
          {Bucket.b5x16: 30, Bucket.b2x16H: 10, Bucket.b7x8: 15});
    });
  });
}

void main() async {
  await initializeTimeZone();
  tests();
}
