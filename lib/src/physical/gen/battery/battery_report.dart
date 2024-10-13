library src.physical.gen.battery_report;

import 'dart:io';

import 'package:dama/stat/descriptive/summary.dart';
import 'package:date/date.dart';
import 'package:elec/src/physical/gen/battery/battery_optimization.dart';
import 'package:timeseries/timeseries.dart';

class BatteryReport {
  BatteryReport({required this.opt});

  final BatteryOptimizationSimple opt;

  List<Map<String, dynamic>> makeTracesDispatchHourly() {
    var domain = Interval(
        opt.daPrice.first.interval.start, opt.daPrice.last.interval.end);
    var traces = <Map<String, dynamic>>[];
    traces.add({
      'x': [domain.start.toIso8601String(), domain.end.toIso8601String()],
      'y': [opt.battery.totalCapacityMWh, opt.battery.totalCapacityMWh],
      'name': 'Max Capacity',
      'color': 'black',
    });
    traces.add({
      'x': opt.dispatchRt.intervals
          .map((e) => e.start.toIso8601String())
          .toList(),
      'y':
          opt.dispatchRt.values.map((e) => e.endState.batteryLevelMwh).toList(),
      'name': 'Battery level',
    });
    return traces;
  }

  List<Map<String, dynamic>> makeTracesPnlHourly() {
    var traces = <Map<String, dynamic>>[];
    var total = opt.pnlDa + opt.pnlRt;

    traces.add({
      'x': opt.pnlDa.intervals.map((e) => e.start.toIso8601String()).toList(),
      'y': opt.pnlDa.values,
      'name': 'DA',
    });
    traces.add({
      'x': opt.pnlRt.intervals.map((e) => e.start.toIso8601String()).toList(),
      'y': opt.pnlRt.values,
      'name': 'RT',
    });
    traces.add({
      'x': total.intervals.map((e) => e.start.toIso8601String()).toList(),
      'y': total.values,
      'name': 'DA+RT',
    });
    return traces;
  }

  List<Map<String, dynamic>> makeTracesPnlDaily() {
    var traces = <Map<String, dynamic>>[];
    var dailyPnlDa = opt.pnlDa.toDaily(sum);
    var dailyPnlRt = opt.pnlRt.toDaily(sum);
    var total = dailyPnlDa + dailyPnlRt;

    traces.add({
      'x': dailyPnlDa.intervals
          .map((e) => e.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': dailyPnlDa.values,
      'name': 'DA',
    });
    traces.add({
      'x': dailyPnlRt.intervals
          .map((e) => e.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': dailyPnlRt.values,
      'name': 'RT',
    });
    traces.add({
      'x': total.intervals
          .map((e) => e.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': total.values,
      'name': 'DA+RT',
    });
    return traces;
  }

  void dailyOperationsChartDa({required Directory directory}) {}
}
