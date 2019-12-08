library test_all;

import 'package:timezone/standalone.dart';
import 'time/bucket_test.dart' as bucketTest;
import 'time/hourly_schedule_test.dart' as hourlyScheduleTest;
import 'time/hour_filter_test.dart' as hourFilterTest;
import 'time/monthly_bucket_value_test.dart' as monthlyBucketValueTest;
import 'holiday_test.dart' as holidayTest;
import 'calendar_test.dart' as calendarTest;
import 'risk_system/marks/monthly_curve_test.dart' as monthlyCurveTest;
import 'risk_system/reporting/trade_aggregator_test.dart' as tradeAggregatorTest;

main() async {
  await initializeTimeZone();

  bucketTest.testBucket();
  bucketTest.aggregateByBucketMonth();
  hourFilterTest.tests();
  hourlyScheduleTest.tests();
  monthlyBucketValueTest.tests();
  calendarTest.main();
  holidayTest.main();
  monthlyCurveTest.tests();
  tradeAggregatorTest.tests();



}