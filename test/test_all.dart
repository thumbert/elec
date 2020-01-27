library test_all;

import 'package:timezone/standalone.dart';
import 'time/bucket/bucket_test.dart' as bucket;
import 'time/hourly_schedule_test.dart' as hourly_schedule;
import 'time/hour_filter_test.dart' as hour_filter;
import 'time/monthly_bucket_value_test.dart' as monthly_bucket_value;
import 'time/shape/shape_cost_test.dart' as shape_cost;
import 'time/calendar/holiday_test.dart' as holiday;
import 'time/calendar/calendar_test.dart' as calendar;
import 'risk_system/marks/monthly_curve_test.dart' as monthly_curve;
import 'risk_system/reporting/trade_aggregator_test.dart' as trade_aggregator;

void main() async {
  await initializeTimeZone();

  bucket.testBucket();
  bucket.aggregateByBucketMonth();
  hour_filter.tests();
  hourly_schedule.tests();
  monthly_bucket_value.tests();
  calendar.main();
  holiday.main();
  monthly_curve.tests();
  shape_cost.tests();
  trade_aggregator.tests();



}