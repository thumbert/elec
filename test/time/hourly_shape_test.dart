library test.time.hourly_shape_test;

import 'dart:convert';

import 'package:dama/dama.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/common_enums.dart';
import 'package:elec/src/time/hourly_schedule.dart';
import 'package:elec/src/time/shape/hourly_shape.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/time/bucket/bucket.dart';

void tests(String rootUrl) async {
  var client = DaLmp(Client(), rootUrl: rootUrl);
  var buckets = [Bucket.b5x16, Bucket.b2x16H, Bucket.b7x8];
  var location = getLocation('America/New_York');
  TimeSeries<num> ts;

  group('HourlyShape tests:', () {
    setUp(() async {
      ts = await client.getHourlyLmp(
          4000, LmpComponent.lmp, Date(2019, 1, 1), Date(2019, 12, 31));
    });
    test('from timeseries', () {
      var hs = HourlyShape.fromTimeSeries(ts, buckets);
      expect(hs.data.length, 12);
      var s0 = hs.data.first.value;
      expect(s0.keys.toSet(), buckets.toSet());
      expect(s0[Bucket.b5x16].length, 16);
    });
    test('check 7x8 in March', () {
      var term = Term.parse('Mar19', location);
      var hs = HourlyShape.fromTimeSeries(ts, buckets);
      var xs = HourlySchedule.fromHourlyShape(hs).toHourly(term.interval);
      var xs7x8 = TimeSeries.fromIterable(xs
          .where((e) => Bucket.b7x8.containsHour(e.interval)));
      var res = mean(xs7x8.values);
      expect(res.toStringAsFixed(8), '1.00000000');
    });
    test('to Json/from Json', () {
      var hs = HourlyShape.fromTimeSeries(ts, buckets);
      var out = hs.toJson();
      expect(out.keys.toSet(), {'terms', 'buckets'});
      var hs1 = HourlyShape.fromJson(out, location);
      expect(hs1.data.length, 12);
      expect(hs1.data.first.value.keys.toSet(),
          {Bucket.b5x16, Bucket.b2x16H, Bucket.b7x8});
    });
    test('extend hourly shape', () {
      var hs = HourlyShape.fromTimeSeries(ts, buckets);
      var hs1 = HourlyShape()
        ..buckets = buckets
        ..data = TimeSeries.from(
            Term.parse('Jan20-Dec21', location)
                .interval
                .splitLeft((dt) => Month.fromTZDateTime(dt)),
            [
              ...hs.data.values,
              ...hs.data.values,
            ]);
      expect(hs1.data.domain, Term.parse('Jan20-Dec21', location).interval);
//      var encoder = JsonEncoder.withIndent('  ');
//      print(encoder.convert(hs1.toJson()));
    });
  });
}

//tests(String rootUrl) {
//  var location = getLocation('America/New_York');
//  group('Electricity marks:', () {
//    test('the 3 standard buckets', () {
//      var b5x16 = Bucket5x16(location);
//      var b2x16H = Bucket2x16H(location);
//      var b7x8 = Bucket7x8(location);
//
//      var weights = [
//        HourlyWeights(b5x16, List.filled(16, 1.0)),
//        HourlyWeights(b2x16H, List.filled(16, 1.0)),
//        HourlyWeights(b7x8, List.filled(8, 1.0)),
//      ];
//
//      var marks = [
//        BucketPrice(b5x16, 81.25),
//        BucketPrice(b2x16H, 67.50),
//        BucketPrice(b7x8, 35.60),
//      ];
//
//      var month = Month(2018, 1, location: location);
//      var hourlyMarks = toHourlyFromMonthlyBucketMark(month, marks, weights);
//      expect(hourlyMarks.length, 744);
//      var values = hourlyMarks.values.toList();
//      expect(values[0], 35.6);
//      expect(values[8], 67.5); // New Year's Eve
////      hourlyMarks.take(32).forEach(print);
//      expect(values[32], 81.25);
//    });
//    test('shape monthly marks', () {
//      var monthlyMarks = TimeSeries.fromIterable([
//        IntervalTuple(Month(2018,1,location: location), ElectricityMarks(81.25, 67.50, 35.60)),
//        IntervalTuple(Month(2018,2,location: location), ElectricityMarks(80.50, 66.40, 32.45)),
//      ]);
//      print(monthlyMarks);
//    });
//
//
//  });
//}

void main() async {
  await initializeTimeZone();
  var rootUrl = 'http://localhost:8080/'; // testing
  await tests(rootUrl);
}
