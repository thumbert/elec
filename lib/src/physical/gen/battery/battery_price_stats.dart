library physical.gen.battery.battery_price_stats;

import 'package:collection/collection.dart' hide IterableNumberExtension;
import 'package:dama/dama.dart';
import 'package:date/date.dart';

import 'package:more/collection.dart';
import 'package:table/table.dart';
import 'package:timeseries/timeseries.dart';

/// For each day of the hourly timeseries [ts] calculate the best blocks
/// of [n] continuous hours to charge and discharge the battery.
///
/// When selecting the blocks with the lowest/highest price, make sure that
/// the blocks are not overlapping and that the min price block (charging)
/// comes before the max price block (discharging)
///
///  * [n] is the number of consecutive hours
///  * [minIndex] is the index of the hours when prices are the lowest
///  * [maxIndex] is the index of the hours when prices are the highest
///
TimeSeries<({int minIndex, num minPrice, int maxIndex, num maxPrice})>
    minMaxDailyPriceForBlock(TimeSeries<num> ts, int n) {
  var dailyTs = ts.groupByIndex((e) => Date.containing(e.start));
  return TimeSeries<
      ({
        int minIndex,
        num minPrice,
        int maxIndex,
        num maxPrice
      })>.fromIterable(dailyTs.map((obs) {
    var chunks = obs.value
        .window(n)
        .mapIndexed((i, es) => (index: i, price: es.mean()))
        .toList();
    // check all possible pairs of charging/discharging blocks and
    // keep the one with the largest spread
    num maxDiff = -999.99;
    var iMinBest = -1;
    var iMaxBest = -1;
    for (var iMin = 0; iMin < (chunks.length - n); iMin++) {
      for (var iMax = iMin + n - 1; iMax < chunks.length; iMax++) {
        var diff = chunks[iMax].price - chunks[iMin].price;
        if (diff > maxDiff) {
          maxDiff = diff;
          iMinBest = chunks[iMin].index;
          iMaxBest = chunks[iMax].index;
        }
      }
    }
    return IntervalTuple<
        ({
          int minIndex,
          num minPrice,
          int maxIndex,
          num maxPrice
        })>(obs.interval, (
      minIndex: chunks[iMinBest].index,
      minPrice: chunks[iMinBest].price,
      maxIndex: chunks[iMaxBest].index,
      maxPrice: chunks[iMaxBest].price
    ));
  }));
}

/// For a given hourly timeseries of prices [hourlyPrices], tabulate
/// the number of days when a given block of hours is best for charging or
/// discharging.
///
///
List<Map<String, dynamic>> tabulateBestBlocks(
    {required TimeSeries<num> hourlyPrices, required int n}) {
  var dailyBlocks = minMaxDailyPriceForBlock(hourlyPrices, n);

  var nest = Nest()
    ..key((e) => e.minIndex)
    ..key((e) => e.maxIndex)
    ..rollup((List es) => {
          'count': es.length,
          'averageSpread': mean(es.map((e) => e.maxPrice - e.minPrice))
        });
  var res = nest.map(dailyBlocks.values.toList());
  var aux = flattenMap(res, ['minIndex', 'maxIndex'])!;

  return aux;
}



// class BestBlocks {
//   BestBlocks(
//       {required this.term,
//       required this.chargeStartIndex,
//       required this.dischargeStartIndex,
//       required this.count,
//       required this.averageSpread});

//   /// Term for the results
//   final Term term;

//   /// Index of hour of the day when charging should start.
//   /// Note that this is not equal with the hour of the day in
//   /// DST days.
//   final int chargeStartIndex;

//   /// Index of hour of the day when discharging should start
//   /// Note that this is not equal with the hour of the day in
//   /// DST days.
//   final int dischargeStartIndex;

//   /// Number of days in the term with these starting hours for
//   /// the charging/discharging block.
//   final int count;

//   /// The average spread for the days in the term with these
//   /// starting hours for the charging/discharging block.
//   /// Spread for one day is the average price during discharge
//   /// hours minus the average price during charging hours,
//   /// in $/MWh
//   final num averageSpread;
// }

