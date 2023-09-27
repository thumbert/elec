library test.fiancial.lib_asian_option_test;

import 'package:date/date.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';


class AsianSettlement {
  /// An arithmetic settlement with equal weighting for all settlement days.
  AsianSettlement({required this.settlementDays});

  final List<Date> settlementDays;

  /// Input [priceTrajectory] needs to be a daily timeseries.
  num price(TimeSeries<num> priceTrajectory) {
    var res = 0.0;
    var i=0;
    for (var e in priceTrajectory) {
      if (e.interval == settlementDays[i]) {
        res += e.value;
        i++;
      }
    }
    if (settlementDays.length != i) {
      throw StateError('Missing settlement data.');
    }
    return res/settlementDays.length;
  }

  /// Return the settlement price as it gets formed on each settlement day.
  /// The last value of this timeseries is the settlement price.
  TimeSeries<num> settlementSeries(TimeSeries<num> priceTrajectory) {
    var res = TimeSeries<num>();
    var i=0;
    for (var e in priceTrajectory) {
      if (e.interval == settlementDays[i]) {
        if (i == 0) {
          res.add(e);
        } else {
          var value = (res.last.value*i + e.value)/(i+1);
          res.add(IntervalTuple(e.interval, value));
        }
        i++;
      }
    }
    if (res.length != settlementDays.length) {
      throw StateError('Missing settlement data.');
    }
    return res;
  }


}

void tests() {
  test('Simple settlement, all days', () {
    var days = [
      Date.utc(2023, 8, 28),
      Date.utc(2023, 8, 29),
      Date.utc(2023, 8, 30),
      Date.utc(2023, 8, 31),
    ];
    var settlement = AsianSettlement(settlementDays: days);
    var prices = TimeSeries.from(days, [10, 12, 11, 10]);
    expect(settlement.price(prices), 10.75);
  });
  test('Not all days settlement', () {

  });


}


void example() {

}


void main() {
  tests();
}