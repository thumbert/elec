library test.risk_system.pricing.calculators.weather.all_weather_test;

import 'package:timezone/data/latest.dart';
import 'daily_temperature_option_test.dart' as daily_temperature;
import 'index_option_test.dart' as index_option;
import 'index_swap_test.dart' as index_swap;

Future<void> tests(String rootUrl) async {
  await daily_temperature.tests(rootUrl);
  await index_option.tests(rootUrl);
  await index_swap.tests(rootUrl);
}

Future<void> main() async {
  initializeTimeZones();

  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);
}
