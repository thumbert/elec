// library test.time.hourly_shape_test;
//
// import 'package:dama/dama.dart';
// import 'package:elec/elec.dart';
// import 'package:elec/risk_system.dart';
// import 'package:elec/src/time/hourly_schedule.dart';
// import 'package:elec/src/time/shape/hourly_shape.dart';
// import 'package:elec_server/client/isoexpress/dalmp.dart';
// import 'package:test/test.dart';
// import 'package:http/http.dart';
// import 'package:timezone/standalone.dart';
// import 'package:date/date.dart';
// import 'package:timeseries/timeseries.dart';
// import 'package:elec/src/time/bucket/bucket.dart';
// import 'package:elec_server/client/marks/forward_marks.dart';
//
// void tests(String rootUrl) async {
//   var client = DaLmp(Client(), rootUrl: rootUrl);
//   var buckets = {Bucket.b5x16, Bucket.b2x16H, Bucket.b7x8};
//   var location = getLocation('America/New_York');
//   TimeSeries<num> ts;
//
//   group('HourlyShape tests:', () {
//     setUp(() async {
//       ts = await client.getHourlyLmp(
//           4000, LmpComponent.lmp, Date.utc(2019, 1, 1), Date.utc(2019, 12, 31));
//     });
//     test('from timeseries', () {
//       var hs = HourlyShape.fromTimeSeries(ts, buckets);
//       expect(hs.data.length, 12);
//       var s0 = hs.data.first.value;
//       expect(s0.keys.toSet(), buckets.toSet());
//       expect(s0[Bucket.b5x16].length, 16);
//     });
//     test('check normalization of 7x8 bucket in March', () {
//       /// because of DST, the sum of hourly shape factors in the
//       /// 7x8 bucket does not equal 8.
//       var term = Month.parse('Mar19', location: location);
//       var hs = HourlyShape.fromTimeSeries(ts, buckets);
//       var shape7x8 = hs.data.observationAt(term).value[Bucket.b7x8];
//       expect(shape7x8.map((e) => e.toStringAsFixed(11)).toList(), [
//         '0.98482254062',
//         '0.93316329161',
//         '0.92084042749',
//         '0.91586658561',
//         '0.94501148905',
//         '1.04732339820',
//         '1.30553653041',
//         '0.94488220241',
//       ]);
//       // construct the timeseries from the hourly shape
//       var xs = HourlySchedule.fromHourlyShape(hs).toHourly(term);
//       var xs7x8 = TimeSeries.fromIterable(
//           xs.where((e) => Bucket.b7x8.containsHour(e.interval)));
//       var res = mean(xs7x8.values);
//
//       /// the average price will equal the monthly bucket price
//       expect(res.toStringAsFixed(8), '1.00000000');
//     });
//
//     test('toHourly', () {
//       var hs = HourlyShape.fromTimeSeries(ts, buckets);
//       var term = Term.parse('15Jan19-15Feb19', location);
//       var xs = hs.toHourly(interval: term.interval);
//       expect(xs.first.interval.start, TZDateTime(location, 2019, 1, 15));
//       expect(xs.last.interval.end, TZDateTime(location, 2019, 2, 16));
//       expect(xs.first.value.toStringAsFixed(7), '0.9807817');
//       expect(xs.last.value.toStringAsFixed(7), '0.9539886');
//     });
//
//     test('to Json/from Json', () {
//       var hs = HourlyShape.fromTimeSeries(ts, buckets);
//       var out = hs.toJson();
//       expect(out.keys.toSet(), {'terms', 'buckets'});
//       var hs1 = HourlyShape.fromJson(out, location);
//       expect(hs1.data.length, 12);
//       expect(hs1.data.first.value.keys.toSet(),
//           {Bucket.b5x16, Bucket.b2x16H, Bucket.b7x8});
//     });
//     test('extend hourly shape', () {
//       var hs = HourlyShape.fromTimeSeries(ts, buckets);
//       var hs1 = HourlyShape()
//         ..buckets = buckets
//         ..data = TimeSeries.from(
//             Term.parse('Jan20-Dec21', location)
//                 .interval
//                 .splitLeft((dt) => Month.fromTZDateTime(dt)),
//             [
//               ...hs.data.values,
//               ...hs.data.values,
//             ]);
//       expect(hs1.data.domain, Term.parse('Jan20-Dec21', location).interval);
// //      var encoder = JsonEncoder.withIndent('  ');
// //      print(encoder.convert(hs1.toJson()));
//     });
//     test('window', () {
//       var hs = HourlyShape.fromTimeSeries(ts, buckets);
//       hs.window(Term.parse('Mar19-Oct19', location).interval);
//       expect(hs.data.first.interval, Month(2019, 3, location: location));
//       expect(hs.data.last.interval, Month(2019, 10, location: location));
//     });
//   });
// }
//
// void speedTests(String rootUrl) async {
//   var location = getLocation('America/New_York');
//   var curveId = 'isone_energy_4000_hourlyshape';
//   var client = ForwardMarks(Client(), rootUrl: rootUrl);
//
//   var hs = await client.getHourlyShape(curveId, Date.utc(2020, 5, 29),
//       tzLocation: location);
//
//   print('Use toHourly() on an HourlySchedule for an Jan21-Dec26 interval.');
//   var term = Term.parse('Jan21-Dec26', location);
//   var interval = term.interval;
//   var hSchedule = HourlySchedule.fromHourlyShape(hs);
//   var sw = Stopwatch()..start();
//   hSchedule.toHourly(interval);
//   sw.stop();
//   print('From HourlySchedule.fromHourlyShape: ${sw.elapsedMilliseconds}');
//
//   sw.reset();
//   sw.start();
//   hs.toHourly(interval: interval);
//   sw.stop();
//   print('From HourlyShape toHourly: ${sw.elapsedMilliseconds}');
//
//   sw.reset();
//   var hSchedule4 = HourlySchedule.byBucket(
//       {Bucket.b2x16H: 15, Bucket.b7x8: 8, Bucket.b5x16: 25});
//   sw.start();
//   hSchedule4.toHourly(interval);
//   sw.stop();
//   print('From HourlySchedule.byBucket: ${sw.elapsedMilliseconds}');
//
//   sw.reset();
//   var months = interval.splitLeft((dt) => Month.fromTZDateTime(dt));
//   var tss2 = TimeSeries.from(months, List.filled(months.length, 10));
//   var hSchedule6 = HourlySchedule.fromTimeSeries(tss2);
//   sw.start();
//   hSchedule6.toHourly(interval);
//   sw.stop();
//   print('From HourlySchedule.fromTimeSeries: ${sw.elapsedMilliseconds}');
//
//   sw.reset();
//   sw.start();
//   tss2.interpolate(Duration(hours: 1));
//   sw.stop();
//   print('From from TimeSeries.interpolate: ${sw.elapsedMilliseconds}');
//
//   var hSchedule2 = HourlySchedule.filled(50);
//   sw.reset();
//   sw.start();
//   hSchedule2.toHourly(interval);
//   sw.stop();
//   print('From HourlySchedule.fill: ${sw.elapsedMilliseconds}');
//
//   sw.reset();
//   sw.start();
//   TimeSeries.fill(term.hours(), 50);
//   sw.stop();
//   print('From TimeSeries.fill: ${sw.elapsedMilliseconds}');
//
//   sw.reset();
//   sw.start();
//   var n = 8760 * 5;
//   var x = <num>[];
//   for (var i = 0; i < n; i++) {
//     x.add(50);
//   }
//   sw.stop();
//   print('From List.fill: ${sw.elapsedMilliseconds}');
// }
//
// void main() async {
//   await initializeTimeZone();
//   var rootUrl = 'http://localhost:8080/'; // testing
//   tests(rootUrl);
//
//   // await speedTests(rootUrl);
// }
