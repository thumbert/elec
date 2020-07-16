library test.time.monthly_bucket_value;

import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/time/bucket/month_bucket_value.dart';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';

tests() {
  var location = getLocation('America/New_York');
  group('Monthly bucket value:', () {
    test('equality check', () {
      var month = Month(2019, 1, location: location);
      var bucket = IsoNewEngland.bucket5x16;
      var mbv1 = MonthBucketValue(month, bucket, 81.50);
      var mbv2 = MonthBucketValue(month, bucket, 81.50);
      var mbv3 = MonthBucketValue(month, bucket, 81.51);
      expect(mbv1 == mbv2, true);
      expect(mbv1 != mbv3, true);
    });
    test('5x16 bucket only, toHourly', () {
      var month = Month(2019, 1, location: location);
      var bucket = IsoNewEngland.bucket5x16;
      var mbv = MonthBucketValue(month, bucket, 81.50);
      var ts = mbv.toHourly();
      expect(ts.length, 352);
    });
  });
}


main() async {
  await initializeTimeZone();
  tests();
}