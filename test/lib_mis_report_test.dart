library lib_mis_report_test;

import 'dart:io';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec/src/iso/isone/lib_mis_reports.dart' as mis;
import 'package:elec/src/iso/isone/lib_iso_express.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';


/// prepare data by downloading a few reports
prepareData() async {
  var report = new DaBindingConstraintsReport();
  var days = [
    new Date(2015,2,17),    // empty file
    new Date(2017,12,13)    // plenty of constraints
  ];
  await report.downloadDays(days);
}


/// test isoexpress
isoExpressTest() async {
  test('DA Binding Constraints Report', () async {
    File file = new DaBindingConstraintsReport().getFilename(new Date(2017,12,13));
    var report = new mis.Report(file);
    expect(await report.forDate(), new Date(2017,12,13));
    expect(await report.filename(), 'da_binding_constraints_final_20171213.csv');
    var data = report.readTabAsMap(tab: 0);
    expect(data.length, 38);
    var data2 = data.map((Map row) => converter(row)).toList();
    expect(data2.first['Marginal Value'] is num, true);
  });

  test('DA Binding Constraints Report - empty', () async {
    File file = new DaBindingConstraintsReport().getFilename(new Date(2015,2,17));
    var report = new mis.Report(file);
    var res = report.readTabAsMap(tab: 0);
    expect(res, []);
  });






}




main() async {
  await initializeTimeZone(getLocationTzdb());
  await prepareData();

  await isoExpressTest();

}