library iso.isone.lib_mis_reports;

import 'dart:io';
import 'package:csv/csv.dart';

/// Read/process MIS reports.
/// Return each row of the [tab] as a List (all rows: C, H, D, T).
List<List> readReport(File file, {int tab: 0}) {
  var converter = new CsvToListConverter();
  var lines = file.readAsLinesSync();
  int nHeaders = 0;
  return lines
      .where((e) {
        if (e[0] == 'H') ++nHeaders;
        if (nHeaders == 2 * tab || nHeaders == (2 * tab + 1))
          return true;
        else
          return false;
      })
      .map((String row) => converter.convert(row).first)
      .toList();
}

/// Read an MIS report and keep only the data rows, each row becoming a map,
/// with keys taken from the header.
/// If there are no data rows (empty report), return an empty List.
List<Map> readReportAsMap(File file, {int tab: 0}) {
  List allData = readReport(file, tab: tab);
  List columnNames = allData.firstWhere((List e) => e[0] == 'H');
  return allData
      .where((List e) => e[0] == 'D')
      .map((List e) => new Map.fromIterables(columnNames, e))
      .toList();
}
