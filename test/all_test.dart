library test_all;

import 'package:timezone/data/latest.dart';
import 'analysis/filter/filter_test.dart' as filter;
import 'analysis/format/seasonal_format_test.dart' as seasonal_format;
import 'analysis/seasonal/seasonal_analysis_test.dart' as seasonal_analysis;
import 'financial/black_scholes/black_scholes_test.dart' as black_scholes;
import 'physical/gas/time_aggregation_test.dart' as time_aggregation;
import 'physical/gen/solar/lib_solar_elevation_test.dart' as solar_elevation;
import 'physical/ftr/ftr_auction_test.dart' as ftr_auction;
import 'physical/ftr/ftr_path_test.dart' as ftr_path;
import 'time/bucket/bucket_test.dart' as bucket;
import 'time/hourly_schedule_test.dart' as hourly_schedule;
import 'time/hourly_shape_test.dart' as hourly_shape;
import 'time/hour_filter_test.dart' as hour_filter;
import 'time/monthly_bucket_value_test.dart' as monthly_bucket_value;
import 'time/shape/shape_cost_test.dart' as shape_cost;
import 'time/calendar/holiday_test.dart' as holiday;
import 'time/calendar/calendar_test.dart' as calendar;
import 'time/last_trading_day_test.dart' as last_trading_day;
import 'risk_system/buy_sell_test.dart' as buy_sell;
import 'risk_system/market_test.dart' as market;
import 'risk_system/marks/price_curve_test.dart' as price_curve;
import 'risk_system/marks/monthly_curve_test.dart' as monthly_curve;
import 'risk_system/marks/volatility_surface_test.dart' as volatility_surface;
import 'risk_system/pricing/calculators/elec_swap/elec_swap_test.dart'
    as elec_swap;
import 'risk_system/pricing/calculators/elec_option/elec_option_daily_test.dart'
    as elec_daily_option;
import 'risk_system/pricing/calculators/weather/all_weather_test.dart'
    as all_weather;

import 'risk_system/reporting/trade_aggregator_test.dart' as trade_aggregator;
import 'weather/leap_year_policy_test.dart' as leap_year_policy;
import 'weather/lib_weather_utils.dart' as weather_utils;

void main() async {
  initializeTimeZones();

  var rootUrl = 'http://localhost:8080';

  filter.tests();
  buy_sell.tests();
  market.tests();
  seasonal_analysis.tests();
  solar_elevation.tests();
  ftr_auction.tests();
  ftr_path.tests(rootUrl);
  black_scholes.tests();
  bucket.tests();
  bucket.aggregateByBucketMonth();

  hour_filter.tests();
  hourly_schedule.tests();
  hourly_shape.tests(rootUrl);
  monthly_bucket_value.tests();
  calendar.tests();
  holiday.tests();
  last_trading_day.tests();
  price_curve.tests();
  monthly_curve.tests();
  volatility_surface.tests();
  elec_swap.tests(rootUrl);
  elec_daily_option.tests(rootUrl);
  all_weather.tests(rootUrl);
  seasonal_format.tests();
  shape_cost.tests();
  time_aggregation.tests();
  trade_aggregator.tests();
  leap_year_policy.tests();
  weather_utils.tests();
}
