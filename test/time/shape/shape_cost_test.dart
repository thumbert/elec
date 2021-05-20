library test.time.shape.shape_cost_test;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/time/shape/shape_cost.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/standalone.dart';

void tests() {
  group('Shape cost tests:', () {
    var location = getLocation('America/New_York');
    test('one day', () {
      var interval = parseTerm('1Jan18', tzLocation: location)!;
      var buckets = [
        IsoNewEngland.bucket7x24,
      ];
      var hours = interval.splitLeft((dt) => Hour.beginning(dt));
      var price = TimeSeries.from(hours, [
        32.72,
        33.68,
        32.99,
        30,
        30.3,
        28.29,
        28.52,
        31.79,
        31.5,
        33.39,
        30.63,
        32.26,
        30.04,
        29.66,
        26.31,
        30.7,
        38.88,
        45.59,
        41.85,
        39.91,
        38.13,
        32.47,
        33.94,
        31.32,
      ]);
      var quantity = TimeSeries.from(hours, [
        2943.135,
        2802.993,
        2810.21,
        2850.705,
        2918.441,
        3124.219,
        3441.647,
        3626.63,
        3700.04,
        3691.846,
        3664.97,
        3596.919,
        3584.848,
        3575.548,
        3550.508,
        3642.329,
        3852.95,
        4182.384,
        4172.441,
        4130.356,
        3956.047,
        3813.315,
        3515.182,
        3272.428,
      ]);
      var cost = shapeCost(price, quantity, buckets,
          timeAggregation: TimeAggregation.term);
      expect(cost[buckets.first]!.first.value.toStringAsFixed(3), '0.317');
    });
  });
}

void main() async {
  await initializeTimeZone();
  tests();
}
