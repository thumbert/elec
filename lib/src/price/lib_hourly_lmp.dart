library price.lib_hourly_lmp.dart;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:decimal/decimal.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:more/more.dart' hide IndexedIterableExtension;
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

typedef Ptid = int;

class HourlyStats {
  HourlyStats(this.ts);

  final TimeSeries<num> ts;

  /// Calculate the minimum/maximum price for a consecutive block of [n] hours
  /// by day.
  ///
  /// When selecting the chunk with the lowest/highest price, make sure that
  /// the blocks are not overlapping!
  ///
  /// [n] is the number of consecutive hours
  ///
  TimeSeries<({int minIndex, num minPrice, int maxIndex, num maxPrice})>
      minMaxDailyPriceForBlock(int n) {
    var dailyTs = ts.groupByIndex((e) => Date.containing(e.start));
    return TimeSeries<
        ({
          int minIndex,
          num minPrice,
          int maxIndex,
          num maxPrice
        })>.fromIterable(dailyTs.map((obs) {
      var chunks = obs.value
          .chunked(n)
          .mapIndexed((i, es) => (index: i, price: es.mean()))
          .toList();
      // when selecting the chunk with the lowest/highest price, need to make sure the
      // blocks are not overlapping!
      chunks.sort((a, b) => a.price.compareTo(b.price));
      var minCandidate = chunks.first;
      var maxCandidate = chunks.last;
      if (minCandidate.index + n <= maxCandidate.index ||
          maxCandidate.index + n <= minCandidate.index) {
        // the min block comes before the max bloc,
        // OR the max block comes before the min bloc
        return IntervalTuple<
            ({
              int minIndex,
              num minPrice,
              int maxIndex,
              num maxPrice
            })>(obs.interval, (
          minIndex: minCandidate.index,
          minPrice: minCandidate.price,
          maxIndex: maxCandidate.index,
          maxPrice: maxCandidate.price
        ));
      } else {
        print('min block overlaps with max block!');
        // need to pick other candidates
        throw StateError('Deal with it!');
      }
    }));
  }
}

Map<Ptid, TimeSeries<num>> getHourlyLmpIsone(
    {required List<Ptid> ptids,
    required Market market,
    required LmpComponent component,
    required Term term}) {
  assert(term.location == IsoNewEngland.location);
  final con = Connection(
      '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/da_lmp.duckdb',
      Config(accessMode: AccessMode.readOnly));
  var cname = switch (component.name) {
    'lmp' => 'lmp',
    'congestion' => 'mcc',
    'loss' => 'mlc',
    _ => throw StateError('Invalid component $component'),
  };
  final query = """
SELECT ptid, date, hour, extraDstHour, $cname
FROM da_lmp
WHERE date >= '${term.startDate}'
AND date <= '${term.endDate}'
AND ptid in (${ptids.join(", ")})
ORDER BY ptid, date, hour, extraDstHour;
""";
  // print(query);
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
