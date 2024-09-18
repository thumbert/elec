library price.lib_lmp.dart;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

typedef Ptid = int;

Map<Ptid, TimeSeries<num>> getHourlyLmpIsone(
    {required List<Ptid> ptids,
    required Market market,
    required LmpComponent component,
    required Term term}) {
  assert(term.location == IsoNewEngland.location);
  final con = Connection(
      '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/${market.name.toLowerCase()}.duckdb',
      Config(accessMode: AccessMode.readOnly));
  var cname = switch (component.name) {
    'lmp' => 'lmp',
    'congestion' => 'mcc',
    'loss' => 'mlc',
    _ => throw StateError('Invalid component $component')
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
