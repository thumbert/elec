library iso.isone.lib_mis_reports;

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:date/date.dart';

/// Read/process MIS reports.
/// Return each row of the [tab] as a List (all rows: C, H, D, T).
List<List> _readReport(File file, {int tab: 0}) {
  var converter = new CsvToListConverter();
  var lines = file.readAsLinesSync();
  if (!lines.last.startsWith('"T"'))
    throw 'Report is incomplete.  Aborting.';
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

/// How to convert different columns.  CSV converter is pretty good with the
/// numerical values.  I want to convert the dates, etc.
Map conversions = {
  /// ISO usually keeps the dates in mm/dd/yyyy format.
  'Date': (String x) {
    int year = int.parse(x.substring(6,10));
    int month = int.parse(x.substring(0,2));
    int day = int.parse(x.substring(3,5));
    return new Date(year, month, day);
  }
};

/// Read an MIS report and keep only the data rows, each row becoming a map,
/// with keys taken from the header.
/// If there are no data rows (empty report), return an empty List.
///
List<Map> readReportAsMap(File file, {int tab: 0}) {
  List allData = _readReport(file, tab: tab);
  List columnNames = allData.firstWhere((List e) => e[0] == 'H');
  return allData
      .where((List e) => e[0] == 'D')
      .map((List e) => new Map.fromIterables(columnNames, e))
      .toList();
}

