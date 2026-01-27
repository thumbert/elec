// import 'dart:io';

import 'package:elec/src/physical/load/emk/lib_demand_bids.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
// import 'package:elec/src/physical/price_quantity_pair.dart';

void tests() {
  var day = Date(2026, 1, 31, location: getLocation('America/New_York'));
  var hours = day.hours();
  var bids4001 = DemandBidFixed(
      ptid: 4001, date: day, quantity: TimeSeries.fill(hours, 0.1));

  var virtuals = <DemandBid>[bids4001];
  print(toXml(virtuals, subaccountName: 'WHLGENLD'));
  // File('demand_bid_2026-01-31.xml')
  //     .writeAsStringSync(toXml(virtuals, subaccountName: 'WHLGENLD'));
}

void main() async {
  initializeTimeZones();
  tests();
}
