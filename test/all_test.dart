library test_all;

import 'package:timezone/standalone.dart';
import 'analysis/filter/filter_test.dart' as filter;
import 'analysis/seasonal/seasonal_analysis_test.dart' as seasonal_analysis;
import 'physical/gas/time_aggregation_test.dart' as time_aggregation;
import 'physical/gen/solar/lib_solar_elevation_test.dart' as solar_elevation;
import 'time/bucket/bucket_test.dart' as bucket;
import 'time/hourly_schedule_test.dart' as hourly_schedule;
import 'time/hourly_shape_test.dart' as hourly_shape;
import 'time/hour_filter_test.dart' as hour_filter;
import 'time/monthly_bucket_value_test.dart' as monthly_bucket_value;
import 'time/shape/shape_cost_test.dart' as shape_cost;
import 'time/calendar/holiday_test.dart' as holiday;
import 'time/calendar/calendar_test.dart' as calendar;
import 'risk_system/buy_sell_test.dart' as buy_sell;
import 'risk_system/marks/forward_curve_test.dart' as forward_curve;
import 'risk_system/marks/monthly_curve_test.dart' as monthly_curve;
import 'risk_system/marks/volatility_surface_test.dart' as volatility_surface;
import 'risk_system/pricing/calculators/elec_swap/elec_swap_test.dart'
    as elec_swap;
import 'risk_system/reporting/trade_aggregator_test.dart' as trade_aggregator;

void main() async {
  await initializeTimeZone();

  var rootUrl = 'http://localhost:8080/';

  filter.tests();
  seasonal_analysis.tests();
  solar_elevation.tests();
  bucket.tests();
  bucket.aggregateByBucketMonth();

  hour_filter.tests();
  hourly_schedule.tests();
  hourly_shape.tests(rootUrl);
  monthly_bucket_value.tests();
  calendar.main();
  holiday.main();
  buy_sell.tests();
  forward_curve.tests();
  monthly_curve.tests();
  volatility_surface.tests();
  elec_swap.tests(rootUrl);
  shape_cost.tests();
  time_aggregation.tests();
  trade_aggregator.tests();
}
