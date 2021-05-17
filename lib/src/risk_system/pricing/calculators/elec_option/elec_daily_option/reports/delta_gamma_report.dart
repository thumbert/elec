// library risk_system.pricing.calculators.elec_option.elec_daily_option.reports.delta_gamma_report;
//
// import 'package:dama/dama.dart';
// import 'package:elec/calculators/elec_daily_option.dart';
// import 'package:elec/src/risk_system/pricing/reports/report.dart';
// import 'package:intl/intl.dart';
// import 'package:table/table.dart';
// import 'package:table/table_base.dart';
//
// class DeltaGammaReportElecDailyOption implements Report {
//   ///
//   DeltaGammaReportElecDailyOption(this.calculator, {this.shocks}) {
//     shocks ??= defaultShocks;
//   }
//
//   ElecDailyOption calculator;
//
//   /// List of underlying price shocks as a percent of underlying.  See [defaultShocks].
//   List<num> shocks;
//
//   static final _fmt0 = NumberFormat('#,###');
//   static final _fmtDt = DateFormat.yMMMMd('en_US').add_jm();
//   static final _fmtPct = NumberFormat.decimalPercentPattern(decimalDigits: 0);
//
//   /// json output
//   Map<String, dynamic> _json;
//
//   /// default underlying price shocks as a percent of underlying
//   final List<num> defaultShocks = List.generate(11, (i) => -0.2 + i * 0.04);
//
//   @override
//   String toString() {
//     _json ?? toJson();
//     var out = StringBuffer();
//     out.writeln('DeltaGamma Report');
//     out.writeln('Recalculate option deltas for different underlying prices');
//     out.writeln('As of date: ${_json['asOfDate']}');
//     out.writeln('Printed: ${_fmtDt.format(DateTime.now())}');
//     out.writeln('');
//     var tbl = (_json['table'] as List)
//         .map((e) => Map<String, dynamic>.from(e))
//         .toList();
//
//     /// Aggregate deltas by period, curveId, bucket, shock
//     var nest = Nest()
//       ..key((e) => e['term'])
//       ..key((e) => e['curveId'])
//       ..key((e) => e['bucket'])
//       ..key((e) => e['shock'])
//       ..rollup((List xs) => _fmt0.format(sum(xs.map((e) => e['delta']))));
//     var totals = flattenMap(
//         nest.map(tbl), ['term', 'curveId', 'bucket', 'shock', 'delta']);
//
//     /// format the shock to a percent
//     for (var x in totals) {
//       x['shock'] = _fmtPct.format(x['shock']);
//     }
//
//     /// add the totals by curveId and bucket to the table
//     var aux =
//         reshape(totals, ['term', 'curveId', 'bucket'], ['shock'], 'delta');
//
//     var _tbl = Table.from(aux, options: {'columnSeparation': '  '});
//     out.write(_tbl.toString());
//     return out.toString();
//   }
//
//   /// Output the report in json format.
//   @override
//   Map<String, dynamic> toJson() {
//     if (_json == null) {
//       var table = <Map<String, dynamic>>[];
//       for (var leg in calculator.legs) {
//         for (var leaf in leg.leaves) {
//           for (var shock in shocks) {
//             var newPrice = leaf.underlyingPrice * (1 + shock);
//             var newLeaf = leaf.copyWith(underlyingPrice: newPrice);
//             table.add({
//               'term': leaf.month.toString(),
//               'curveId': leg.curveId,
//               'bucket': leg.bucket.toString(),
//               'underlyingPrice': leaf.underlyingPrice,
//               'shock': shock,
//               'delta': newLeaf.delta() * newLeaf.quantityTerm, // in MWh
//             });
//           }
//         }
//       }
//       var out = <String, dynamic>{
//         'asOfDate': calculator.asOfDate.toString(),
//         'reportDate': DateTime.now().toString(),
//         'table': table,
//       };
//       _json = out;
//     }
//     return _json;
//   }
// }
