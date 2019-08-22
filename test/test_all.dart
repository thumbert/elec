library test_all;

import 'package:timezone/standalone.dart';
import 'time/bucket_test.dart' as bucketTest;
import 'time/hourly_schedule_test.dart' as hourlyScheduleTest;
import 'time/monthly_bucket_value_test.dart' as monthlyBucketValueTest;
import 'time/monthly_bucket_curve_test.dart' as monthlyBucketCurveTest;
import 'holiday_test.dart' as holidayTest;
import 'calendar_test.dart' as calendarTest;
import 'risk_system/marks/monthly_curve_test.dart' as monthlyCurveTest;
import 'risk_system/reporting/trade_aggregator_test.dart' as tradeAggregatorTest;

main() async {
  await initializeTimeZone();

  bucketTest.testBucket();
  bucketTest.aggregateByBucketMonth();
  hourlyScheduleTest.tests();
  monthlyBucketValueTest.tests();
  monthlyBucketCurveTest.tests();
  calendarTest.main();
  holidayTest.main();
  monthlyCurveTest.tests();
  tradeAggregatorTest.tests();



}