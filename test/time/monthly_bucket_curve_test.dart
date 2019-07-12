library test.time.monthly_bucket_curve;

import 'package:elec/src/time/bucket/month_bucket_curve.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/time/bucket/month_bucket_value.dart';


tests() {
  var location = getLocation('US/Eastern');
  var b5x16 = IsoNewEngland.bucket5x16;
  var b2x16H = IsoNewEngland.bucket2x16H;
  var bOffpeak = IsoNewEngland.bucketOffpeak;
  group('Monthly bucket curve', () {
    test('one month, 5x16, 7x8 buckets only', () {
      var month = Month(2019, 1, location: location);
      var values = [
        MonthBucketValue(month, b5x16,  81.50),
        MonthBucketValue(month, b2x16H, 65.25),
      ];
      var mbc = MonthBucketCurve(values);
      expect(mbc.months, [month]);
      expect(mbc.buckets, {b5x16, b2x16H});
      var ts = mbc.toHourly();
      expect(ts.length, 496);
    });
    test('several months, several buckets', () {
      var months = [
        Month(2019, 1, location: location),
        Month(2019, 2, location: location),
        Month(2019, 3, location: location),
      ];
      var ts5x16 = TimeSeries.from(months, [81.50, 79.65, 56.75]);
      var tsOffpeak = TimeSeries.from(months, [61.50, 58.65, 49.85]);
      var mbc = MonthBucketCurve.from([b5x16, bOffpeak], [ts5x16, tsOffpeak]);
      expect(mbc.buckets, {bOffpeak, b5x16});
      expect(mbc.months, months);
      var ts = mbc.toHourly();
      expect(ts.length, 2159);
    });
  });
}


main() async {
  await initializeTimeZone();
  tests();
}