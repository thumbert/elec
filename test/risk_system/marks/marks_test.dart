// library test.risk_system.marks.marks_test;
//
// import 'package:date/date.dart';
// import 'package:elec/src/iso/iso.dart';
// import 'package:elec/src/time/bucket/month_bucket_value.dart';
// import 'package:test/test.dart';
// import 'package:timezone/standalone.dart';
// import 'package:timezone/timezone.dart';
//
// void tests() {
//   group('Electricity marks', () {
//     var location = getLocation('America/New_York');
//     test('the 3 standard buckets', () {
//       var month = Month(2019, 1, location: location);
//       var marks = [
//         MonthBucketValue(month, IsoNewEngland.bucket5x16, 81.25),
//         MonthBucketValue(month, IsoNewEngland.bucket2x16H, 67.50),
//         MonthBucketValue(month, IsoNewEngland.bucket7x8, 35.60)
//       ];
//     });
//   });
// }
//
// void main() async {
//   await initializeTimeZone();
//   tests();
// }
