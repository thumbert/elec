library test.risk_system.marks.forward_curve_test;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/risk_system/marks/forward_curve.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';


void tests() {
  group('Forward curve tests: ', () {
    var location = getLocation('America/New_York');
    var aux = File('test/risk_system/marks/marks_test.json').readAsStringSync();
    var xs = json.decode(aux) as List;
    var x0 = (xs[0]['value'] as List).cast<Map<String,dynamic>>();
    var curve0 = ForwardCurve.fromTermBucketMarks(x0, location);
    var x1 = (xs[1]['value'] as List).cast<Map<String,dynamic>>();
    test('from the 3 standard buckets', () {
      expect(curve0.length, 11);
      expect(curve0.first.value.length, 2);
      expect(curve0.toJson(), x0);
    });
    test('from the flat bucket only', () {
      var curve = ForwardCurve.fromTermBucketMarks(x1, location);
      expect(curve.length, 11);
      expect(curve.first.value.length, 1);
      expect(curve.toJson(), x1);
    });
    test('filter only the monthly values', () {
      var curve0m = ForwardCurve.fromIterable(
          curve0.where((e) => e.interval is Month));
      expect(curve0m.length, 5);
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
    test('calculate value for offpeak bucket, term Q4,20 (aggregate months and buckets)', () {
      var term = Term.parse('Q4, 2020', location);
      var value = curve0.value(term.interval, Bucket.offpeak);
      expect(value.toStringAsFixed(4), '28.1768');
    });
    test('calculate value for atc bucket, term 26Ju20-31Jul20 (aggregate months and buckets)', () {
      var term = Term.parse('26Jul20-31Jul20', location);
      var value = curve0.value(term.interval, Bucket.atc);
      expect(value.toStringAsFixed(4), '24.8889');
    });
  });
}

void main() async {
  await initializeTimeZone();
  tests();
}
