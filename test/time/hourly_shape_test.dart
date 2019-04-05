library test.time.hourly_shape_test;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/risk_system/marks/electricity_marks.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/time/bucket/hourly_bucket_weights.dart';

TimeSeries<num> toHourlyFromMonthlyBucketMark(Month month, List<BucketPrice> marks, List<HourlyWeights> weights){
  var hours = month.splitLeft((dt) => Hour.containing(dt)).cast<Hour>();
  var price = Map.fromIterable(marks, key: (e) => e.bucket, value: (e) => e.price);
  var ts = TimeSeries<num>();
  for (var hour in hours) {
    for (var weight in weights) {
      var bucket = weight.bucket;
      if (bucket.containsHour(hour)) {
        var hourEnding = hour.start.hour + 1;
        ts.add(IntervalTuple(hour, price[bucket] * weight.value(hourEnding)));
        continue;
      }
    }
  }
  return ts;
}


tests() {
  var location = getLocation('US/Eastern');
  group('Electricity marks:', () {
    test('the 3 standard buckets', () {
      var b5x16 = Bucket5x16(location);
      var b2x16H = Bucket2x16H(location);
      var b7x8 = Bucket7x8(location);

      var weights = [
        HourlyWeights(b5x16, List.filled(16, 1.0)),
        HourlyWeights(b2x16H, List.filled(16, 1.0)),
        HourlyWeights(b7x8, List.filled(8, 1.0)),
      ];

      var marks = [
        BucketPrice(b5x16, 81.25),
        BucketPrice(b2x16H, 67.50),
        BucketPrice(b7x8, 35.60),
      ];

      var month = Month(2018, 1, location: location);
      var hourlyMarks = toHourlyFromMonthlyBucketMark(month, marks, weights);
      expect(hourlyMarks.length, 744);
      var values = hourlyMarks.values.toList();
      expect(values[0], 35.6);
      expect(values[8], 67.5); // New Year's Eve
//      hourlyMarks.take(32).forEach(print);
      expect(values[32], 81.25);
    });
    test('shape monthly marks', () {
      var monthlyMarks = TimeSeries.fromIterable([
        IntervalTuple(Month(2018,1,location: location), ElectricityMarks(81.25, 67.50, 35.60)),
        IntervalTuple(Month(2018,2,location: location), ElectricityMarks(80.50, 66.40, 32.45)),
      ]);
      print(monthlyMarks);
    });


  });
}


main() async {
  await initializeTimeZone();
  tests();
}