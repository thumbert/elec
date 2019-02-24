library src.grpc.lmp.high_low_nodes;

import 'package:date/date.dart';
import 'package:fixnum/fixnum.dart';
import 'package:elec_server/src/generated/timeseries.pbgrpc.dart';
//import 'package:elec/risk_system.dart' as rs;

/// LmpClient is the grpc service
//Future highLowNodes(List<int> ptids, Interval interval, LmpComponent lmpComponent, LmpClient client) async {
//
//  final congestion = LmpComponent()
//    ..component = LmpComponent_Component.CONGESTION;
//
//  var request = HistoricalLmpRequest()
//    ..ptid = 4000
//    ..start = Int64(interval.start.millisecondsSinceEpoch)
//    ..end = Int64(interval.end.millisecondsSinceEpoch)
//    ..component = congestion;
//
//  var response = await client.getLmp(request);
//
//  return response;
//
//}
