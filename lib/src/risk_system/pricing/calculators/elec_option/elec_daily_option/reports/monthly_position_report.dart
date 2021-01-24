library risk_system.pricing.calculators.elec_option.elec_daily_option.reports.monthly_position_report;

import 'package:dama/dama.dart';
import 'package:elec/calculators/elec_daily_option.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:table/table.dart';
import 'package:table/table_base.dart';

class MonthlyPositionReportElecDailyOption implements Report {
  ElecDailyOption calculator;

  static final _fmt0 = NumberFormat('#,###');
  static final _fmtDt = DateFormat.yMMMMd('en_US').add_jm();

  /// json output
  Map<String, dynamic> _json;

  MonthlyPositionReportElecDailyOption(this.calculator);

  @override
  String toString() {
    _json ?? toJson();
    var out = StringBuffer();
    out.writeln('Monthly Position Report');
    out.writeln('As of date: ${_json['asOfDate']}');
    out.writeln('Printed: ${_fmtDt.format(DateTime.now())}');
    out.writeln('');
    var tbl = (_json['table'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// calculate totals by period
    var nest = Nest()
      ..key((e) => e['term'])
      ..rollup((List xs) => _fmt0.format(sum(xs.map((e) => e['value']))));
    var totalsByTerm = flattenMap(nest.map(tbl), ['term', 'total'])
      ..add({'term': 'total', 'total': ''});

    /// add the totals by curveId and bucket to the table
    nest = Nest()
      ..key((e) => e['curveId'])
      ..key((e) => e['bucket'])
      ..rollup((List xs) => sum(xs.map((e) => e['value'])));
    var totalCurveId =
        flattenMap(nest.map(tbl), ['curveId', 'bucket', 'value']);
    for (var row in totalCurveId) {
      tbl.add(<String, dynamic>{'term': 'total', ...row});
    }

    for (var row in tbl) {
      if (row['value'] is num) {
        row['value'] = _fmt0.format(row['value'] as num);
      }
    }
    var aux = reshape(tbl, ['term'], ['curveId', 'bucket'], 'value');

    aux = join(aux, totalsByTerm);
    var _tbl = Table.from(aux, options: {'columnSeparation': '  '});
    out.write(_tbl.toString());
    return out.toString();
  }

  /// Output a monthly position report in json format.
  @override
  Map<String, dynamic> toJson() {
    if (_json == null) {
      var table = <Map<String, dynamic>>[];
      for (var leg in calculator.legs) {
        for (var leaf in leg.leaves) {
          table.add({
            'term': leaf.month.toString(),
            'curveId': leg.curveId,
            'bucket': leg.bucket.toString(),
            'value': calculator.buySell.sign * leaf.quantityTerm * leaf.delta()
          });
        }
      }
      var out = <String, dynamic>{
        'asOfDate': calculator.asOfDate.toString(),
        'reportDate': DateTime.now().toString(),
        'table': table,
      };
      _json = out;
    }
    return _json;
  }
}
