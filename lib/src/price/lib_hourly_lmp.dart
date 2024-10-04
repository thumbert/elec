library price.lib_hourly_lmp.dart;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
// import 'package:more/more.dart' hide IndexedIterableExtension;
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

typedef Ptid = int;

class SummaryStats {
  SummaryStats(this.ts);

  /// [ts] is an hourly timeseries
  final TimeSeries<num> ts;

  /// Calculate the minimum/maximum price for a consecutive block of [n] hours
  /// by day.
  ///
  /// When selecting the chunk with the lowest/highest price, make sure that
  /// the blocks are not overlapping!
  ///
  /// [n] is the block size (number of consecutive hours)
  ///
//   TimeSeries<({int minIndex, num minPrice, int maxIndex, num maxPrice})>
//       blockPriceStatisticByMonth(int n) {

//     var nest = Nest()
//       ..key((IntervalTuple<num> e) => Month.containing(e.interval.start));

//     var out = <Map<String,dynamic>>[];
//     var startHour = List.generate(20, (i) => i);
//     for (var startHour in )

//     var dailyTs = ts.groupByIndex((e) => Month.containing(e.start));
//     return TimeSeries<
//         ({
//           int minIndex,
//           num minPrice,
//           int maxIndex,
//           num maxPrice
//         })>.fromIterable(dailyTs.map((obs) {
//       var chunks = obs.value
//           .window(n)
//           .mapIndexed((i, es) => (index: i, price: es.mean()))
//           .toList();
//       // when selecting the chunk with the lowest/highest price, need to make sure the
//       // blocks are not overlapping!
//       chunks.sort((a, b) => a.price.compareTo(b.price));
//       // print(chunks.join('\n'));

//       // deal with the unlikely degenerate case
//       if (chunks.first.price == chunks.last.price) {}

//       var minIndex = 0;
//       var maxIndex = chunks.length - 1;
//       // deal with the unlikely degenerate case (all prices are the same)
//       if (chunks.first.price == chunks.last.price) {
//         return IntervalTuple<
//             ({
//               int minIndex,
//               num minPrice,
//               int maxIndex,
//               num maxPrice
//             })>(obs.interval, (
//           minIndex: chunks[minIndex].index,
//           minPrice: chunks[minIndex].price,
//           maxIndex: chunks[maxIndex].index,
//           maxPrice: chunks[maxIndex].price
//         ));
//       }

//       // Check if there is overlap between the blocks.
//       // If it is, you have to reject the choice and find another pair.
//       while (overlap(iA: chunks[minIndex].index, iB: chunks[maxIndex].index, size: n)) {
//         // check the next two possible candidate pairs
//         var dP10 = chunks[maxIndex].price - chunks[minIndex + 1].price;
//         var dP01 = chunks[maxIndex - 1].price - chunks[minIndex].price;
//         if (dP10 > dP01) {
//           minIndex += 1;
//         } else {
//           maxIndex -= 1;
//         }
//       }
//       return IntervalTuple<
//           ({
//             int minIndex,
//             num minPrice,
//             int maxIndex,
//             num maxPrice
//           })>(obs.interval, (
//         minIndex: chunks[minIndex].index,
//         minPrice: chunks[minIndex].price,
//         maxIndex: chunks[maxIndex].index,
//         maxPrice: chunks[maxIndex].price
//       ));
//     }));
//   }
// }
}

Map<Ptid, TimeSeries<num>> getHourlyLmpIsone(
    {required List<Ptid> ptids,
    required Market market,
    required LmpComponent component,
    required Term term}) {
  assert(term.location == IsoNewEngland.location);
  final con = switch (market.name) {
    'DA' => Connection(
        '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/da_lmp.duckdb',
        Config(accessMode: AccessMode.readOnly)),
    'RT' => Connection(
        '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/rt_lmp.duckdb',
        Config(accessMode: AccessMode.readOnly)),
    _ => throw StateError('$market not supported!')
  };
  var cname = switch (component.name) {
    'lmp' => 'lmp',
    'congestion' => 'mcc',
    'loss' => 'mlc',
    _ => throw StateError('Invalid component $component'),
  };
  final query = """
SELECT ptid, date, hour, extraDstHour, $cname
FROM ${market.name.toLowerCase()}_lmp
WHERE date >= '${term.startDate}'
AND date <= '${term.endDate}'
AND ptid in (${ptids.join(", ")})
ORDER BY ptid, date, hour, extraDstHour;
""";
  var data = con.fetchRows(query, (List row) {
    final date = Date.fromJulianDay(row[1]);
    var interval = Hour.beginning(TZDateTime(
        IsoNewEngland.location, date.year, date.month, date.day, row[2]));
    if (row[3]) {
      interval = interval.next;
    }
    return (row[0] as int, IntervalTuple<num>(interval, row[4].toDouble()));
  });
  con.close();

  var res = <int, TimeSeries<num>>{};
  var groups = groupBy(data, (e) => e.$1);
  for (var ptid in groups.keys) {
    res[ptid] = TimeSeries.fromIterable(groups[ptid]!.map((e) => e.$2));
  }
  return res;
}

/// Only selected ptids are stored.  And limited history starting Jan23 for Hub.
/// 
Map<Ptid, TimeSeries<num>> get5MinRtLmpIsone({
  required List<Ptid> ptids,
  required LmpComponent component,
  required Term term,
  required ReportType reportType,
}) {
  assert(term.location == IsoNewEngland.location);
  final m5 = Duration(minutes: 5);
  final con = Connection(
      '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/rt_lmp5min.duckdb',
      Config(accessMode: AccessMode.readOnly));
  var cname = switch (component.name) {
    'lmp' => 'lmp',
    'congestion' => 'mcc',
    'loss' => 'mlc',
    _ => throw StateError('Invalid component $component'),
  };
  final query = """
SELECT ptid, date, minuteOfDay, $cname
FROM rt_lmp5min
WHERE report = '${reportType.toString()}'
AND date >= '${term.startDate}'
AND date <= '${term.endDate}'
AND ptid in (${ptids.join(", ")})
ORDER BY ptid, date, minuteOfDay;
""";
  var data = con.fetchRows(query, (List row) {
    final date = Date.fromJulianDay(row[1], location: IsoNewEngland.location);
    final start = date.start.add(Duration(minutes: row[2]));
    var interval = Interval.beginning(start, m5);
    return (row[0] as int, IntervalTuple<num>(interval, row[3].toDouble()));
  });
  con.close();

  var res = <int, TimeSeries<num>>{};
  var groups = groupBy(data, (e) => e.$1);
  for (var ptid in groups.keys) {
    res[ptid] = TimeSeries.fromIterable(groups[ptid]!.map((e) => e.$2));
  }
  return res;
}
