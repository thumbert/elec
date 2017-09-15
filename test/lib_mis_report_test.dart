library lib_mis_report_test;

import 'dart:io';

import 'package:elec/src/iso/isone/lib_mis_reports.dart';

/// test one tab
readDaBindingConstraintsTest() {
  Map env = Platform.environment;
  File file = new File(env['HOME'] +
      '/Downloads/Archive/DA_BindingConstraints/Raw/' +
      'da_binding_constraints_final_20150217.csv');

//  var res = readReport(file);
//  res.forEach(print);

  var res2 = readReportAsMap(file);
  res2.forEach(print);
  print(res2.length);
  print(res2.isEmpty);
  print(res2 is List);
//  print(res2[0]['Hour Ending'] is String);
//  print(res2[2]['Hour Ending'] is String);
//  print(res2[2]['Marginal Value'] is String);  // false

}

main() {
  readDaBindingConstraintsTest();
}