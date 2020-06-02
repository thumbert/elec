library risk_system.data_provider.data_provider;

import 'dart:convert';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/risk_system/locations/curve_id.dart';
import 'package:elec/src/risk_system/marks/monthly_curve.dart';
import 'package:http/http.dart' as http;
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:intl/intl.dart';
import 'package:timeseries/timeseries.dart';

class DataProvider {
  String rootUrl;
  http.Client client;

  final _fwdMarksPath = '/forward_marks/v1/';
  static final DateFormat _isoFmt = DateFormat('yyyy-MM');


  DataProvider({this.client, this.rootUrl = 'http://localhost:8080'});

  ///
  Future<MonthlyCurve> getForwardCurveForBucket(CurveId curveId,
      Bucket bucket, Date asOfDate) async {
    var _url = rootUrl + _fwdMarksPath +
        'curveId/' +
        commons.Escaper.ecapeVariable('${curveId.name}') +
        '/bucket/' + bucket.toString() +
        '/asOfDate/${asOfDate.toString()}';

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var aux = json.decode(data['result']);
    var out = TimeSeries<num>();
    for (var e in aux.entries) {
      out.add(IntervalTuple(Month.parse(e.key, location: curveId.tzLocation, fmt: _isoFmt), e.value));
    }
    return MonthlyCurve(bucket, out);
  }


}