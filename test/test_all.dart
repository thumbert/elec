library test_all;

import 'package:timezone/standalone.dart';
import 'time/bucket_test.dart' as bucketTest;
import 'time/monthly_bucket_value_test.dart' as monthlyBucketValueTest;
import 'time/monthly_bucket_curve_test.dart' as monthlyBucketCurveTest;
import 'holiday_test.dart' as holidayTest;
import 'calendar_test.dart' as calendarTest;


main() async {
  await initializeTimeZone();

  bucketTest.test_bucket();
  bucketTest.aggregateByBucketMonth();
  monthlyBucketValueTest.tests();
  monthlyBucketCurveTest.tests();
  calendarTest.main();
  holidayTest.main();



}