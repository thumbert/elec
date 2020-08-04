library test_all;

import 'package:timezone/standalone.dart';
import 'analysis/filter/filter_test.dart' as filter;
import 'analysis/seasonal/seasonal_analysis_test.dart' as seasonal_analysis;
import 'gen/solar/lib_solar_elevation_test.dart' as solar_elevation;
import 'time/bucket/bucket_test.dart' as bucket;
import 'time/hourly_schedule_test.dart' as hourly_schedule;
import 'time/hourly_shape_test.dart' as hourly_shape;
import 'time/hour_filter_test.dart' as hour_filter;
import 'time/monthly_bucket_value_test.dart' as monthly_bucket_value;
import 'time/shape/shape_cost_test.dart' as shape_cost;
import 'time/calendar/holiday_test.dart' as holiday;
import 'time/calendar/calendar_test.dart' as calendar;
import 'risk_system/marks/monthly_curve_test.dart' as monthly_curve;
import 'risk_system/pricing/calculators/elec_calc_cdf/elec_calc_cdf_test.dart' as elec_calc_cdf;
import 'risk_system/reporting/trade_aggregator_test.dart' as trade_aggregator;

void main() async {
  await initializeTimeZone();

  var rootUrl = 'http://localhost:8080/';

  filter.tests();
  seasonal_analysis.tests();
  solar_elevation.tests();
  bucket.testBucket();
  bucket.aggregateByBucketMonth();
  hour_filter.tests();
  hourly_schedule.tests();
  hourly_shape.tests(rootUrl);
  monthly_bucket_value.tests();
  calendar.main();
  holiday.main();
  monthly_curve.tests();
  elec_calc_cdf.tests(rootUrl);
  shape_cost.tests();
  trade_aggregator.tests();



}