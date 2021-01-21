library risk_system.pricing.calculators.elec_option.elec_daily_option.reports.delta_gamma_report;

import 'package:dama/dama.dart';
import 'package:elec/calculators/elec_daily_option.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:table/table.dart';
import 'package:table/table_base.dart';

class DeltaGammaReportElecDailyOption implements Report {
  ///
  DeltaGammaReportElecDailyOption(this.calculator, {this.shocks}) {
    shocks ??= defaultShocks;
  }

  ElecDailyOption calculator;

  /// List of underlying price shocks as a percent of underlying.  See [defaultShocks].
  List<num> shocks;

  static final _fmt0 = NumberFormat()..maximumIntegerDigits = 0;
  static final _fmtDt = DateFormat.yMMMMd('en_US').add_jm();

  /// json output
  Map<String, dynamic> _json;

  /// default underlying price shocks as a percent of underlying
  final List<num> defaultShocks = List.generate(11, (i) => -0.2 + i * 0.04);

  @override
  String toString() {
    _json ?? toJson();
    var out = StringBuffer();
    out.writeln('DeltaGamma Report');
    out.writeln(
        'Recalculate the option deltas for different underlying prices.');
    out.writeln('As of date: ${_json['asOfDate']}');
    out.writeln('Printed: ${_fmtDt.format(DateTime.now())}');
    out.writeln('');
    var tbl = _json['table'] as List;
    tbl = tbl.where((e) => e['curveId'] != 'USD').toList();

    /// calculate totals by period
    var nest = Nest()
      ..key((e) => e['term'])
      ..rollup(
          (List xs) => _fmt0.format(sum(xs.map((e) => e['nominalQuantity']))));
    var totalsByTerm = flattenMap(nest.map(tbl), ['term', 'total'])
      ..add({'term': 'total', 'total': ''});

    /// add the totals by curveId and bucket to the table
    nest = Nest()
      ..key((e) => e['curveId'])
      ..key((e) => e['bucket'])
      ..rollup((List xs) => sum(xs.map((e) => e['nominalQuantity'])));
    var totalCurveId =
        flattenMap(nest.map(tbl), ['curveId', 'bucket', 'nominalQuantity']);
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

  /// Output the report in json format.
  @override
  Map<String, dynamic> toJson() {
    if (_json == null) {
      var table = <Map<String, dynamic>>[];
      for (var leg in calculator.legs) {
        for (var leaf in leg.leaves) {
          for (var shock in shocks) {
            table.add({
              'term': leaf.month.toString(),
              'curveId': leg.curveId,
              'bucket': leg.bucket.toString(),
              'underlyingPrice': leaf.underlyingPrice,
            });
          }
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
