// import 'dart:io';

import 'package:elec/elec.dart';
import 'package:elec/src/physical/load/emk/lib_demand_bids.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
// import 'package:elec/src/physical/price_quantity_pair.dart';

void tests() {
  group('eMkt submission, demand bids test ', () {
    test('fixed bids', () {
      var day = Date(2026, 1, 31, location: getLocation('America/New_York'));
      var hours = day.hours();
      var bids = <DemandBid>[
        DemandBidFixed(
            ptid: 4001, date: day, quantity: TimeSeries.fill(hours, 0.1)),
        DemandBidFixed(
            ptid: 4002, date: day, quantity: TimeSeries.fill(hours, 0.2)),
      ];
      print(toXml(bids, subaccountName: 'WHLGENLD'));
    });
    test('price-sensitive bids', () {
      var day = Date(2026, 1, 31, location: getLocation('America/New_York'));
      var bids = <DemandBid>[
        DemandBidPriceSensitive(
            ptid: 4001,
            date: day,
            schedule: TimeSeries.fromIterable([
              IntervalTuple(
                  Hour.beginning(
                      TZDateTime(IsoNewEngland.location, 2026, 1, 31, 0)),
                  [
                    PriceQuantityPair(999.0, 0.1),
                    PriceQuantityPair(999.10, 0.1)
                  ]),
            ]))
      ];
      print(toXml(bids, subaccountName: 'WHLGENLD'));
    });
  });
  // File('demand_bid_2026-01-31.xml')
  //     .writeAsStringSync(toXml(bids, subaccountName: 'WHLGENLD'));
}

void main() async {
  initializeTimeZones();
  tests();
}
