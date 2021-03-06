library risk_system.pricing.calculators.elec_calc_cfd.monthly_position_report;

import 'package:dama/dama.dart';
import 'package:elec/calculators/elec_swap.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:table/table.dart';
import 'package:table/table_base.dart';

class MonthlyPositionReportElecCfd implements Report {
  ElecSwapCalculator calculator;

  static final _fmt0 = NumberFormat()..maximumIntegerDigits = 0;
  static final _fmtDt = DateFormat.yMMMMd('en_US').add_jm();

  /// json output
  var _json = <String,dynamic>{};

  MonthlyPositionReportElecCfd(this.calculator);

  @override
  String toString() {
    if (_json.isEmpty) _json = toJson();
    var out = StringBuffer();
    out.writeln('Monthly Position Report');
    out.writeln('As of date: ${_json['asOfDate']}');
    out.writeln('Printed: ${_fmtDt.format(DateTime.now())}');
    out.writeln('');
    var tbl = (_json['table'] as List).cast<Map<String,dynamic>>();
    tbl = tbl.where((e) => e['curveId'] != 'USD').toList();

    /// calculate totals by period
    var nest = Nest()
      ..key((e) => e['term'])
      ..rollup(
          (List xs) => _fmt0.format(sum(xs.map((e) => e['nominalQuantity']))));
    var totalsByTerm = flattenMap(nest.map(tbl), ['term', 'total'])!
      ..add({'term': 'total', 'total': ''});

    /// add the totals by curveId and bucket to the table
    nest = Nest()
      ..key((e) => e['curveId'])
      ..key((e) => e['bucket'])
      ..rollup((List xs) => sum(xs.map((e) => e['nominalQuantity'])));
    var totalCurveId =
        flattenMap(nest.map(tbl), ['curveId', 'bucket', 'nominalQuantity'])!;
    for (var row in totalCurveId) {
      tbl.add(<String, dynamic>{'term': 'total', ...row});
    }

    for (var row in tbl) {
      row['nominalQuantity'] = _fmt0.format(row['nominalQuantity'] as num);
    }
    var aux = reshape(tbl, ['term'], ['curveId', 'bucket'], 'nominalQuantity');

    aux = join(aux, totalsByTerm);
    var _tbl = Table.from(aux, options: {'columnSeparation': '  '});
    out.write(_tbl.toString());
    return out.toString();
  }

  /// Output a monthly position report in json format.
  @override
  Map<String, dynamic> toJson() {
    if (_json.isEmpty) {
      var table = <Map<String, dynamic>>[];
      for (var leg in calculator.legs) {
        for (var leaf in leg.leaves) {
          table.add({
            'term': leaf.interval.toString(),
            'curveId': 'USD',
            'bucket': '',
            'nominalQuantity': -calculator.buySell.sign *
                leaf.quantity *
                leaf.hours *
                leaf.fixPrice,
            'forwardPrice': 1,
            'value': -calculator.buySell.sign *
                leaf.quantity *
                leaf.hours *
                leaf.fixPrice,
          });
          table.add({
            'term': leaf.interval.toString(),
            'curveId': leg.curveId,
            'bucket': leg.bucket.toString(),
            'nominalQuantity':
                calculator.buySell.sign * leaf.quantity * leaf.hours,
            'forwardPrice': leaf.floatingPrice,
            'value': calculator.buySell.sign *
                leaf.quantity *
                leaf.hours *
                leaf.floatingPrice,
          });
        }
      }
      var out = <String, dynamic>{
        'asOfDate': calculator.asOfDate.toString(),
        'reportDate': DateTime.now().toString(),
        'table': table,
        'totalValue': calculator.dollarPrice(),
      };
      _json = out;
    }
    return _json;
  }
}
