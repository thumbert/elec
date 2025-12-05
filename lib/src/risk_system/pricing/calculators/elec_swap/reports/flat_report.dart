import 'package:elec/src/risk_system/pricing/calculators/elec_swap/elec_swap.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:table/table_base.dart';

class FlatReportElecCfd implements Report {
  ElecSwapCalculator calculator;

  static final _fmtCurrency2 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _fmt0 = NumberFormat()..maximumIntegerDigits = 0;

  /// a json output
  var _json = <String,dynamic>{};

  FlatReportElecCfd(this.calculator);

  @override
  String toString() {
    if (_json.isEmpty) _json = toJson();
    var tbl = _json['table'] as List;
    for (var row in tbl) {
      row['forwardPrice'] = (row['forwardPrice'] as num).toStringAsFixed(2);
      row['nominalQuantity'] = _fmt0.format(row['nominalQuantity'] as num);
      row['value'] = _fmtCurrency2.format(row['value'] as num);
    }

    // rearrange the leaves, start with the USD leaves first
    var cashRows = tbl.where((e) => e['curveId'] == 'USD').toList();
    var tbl0 = Table.from([
      ...cashRows,
      ...tbl.where((e) => e['curveId'] != 'USD'),
    ], options: {
      'columnSeparation': '  '
    });

    // add spacing between fixed and floating commodities
    var aux = tbl0.toString().split('\n');
    aux.insert(cashRows.length + 1, ''); // an empty row
    aux.insert(
        cashRows.length + 2, aux.first); // colnames for commmodity leaves

    var out = StringBuffer();
    out.writeln('Flat Report');
    out.writeln('As of date: ${_json['asOfDate']}');
    out.writeln('Printed: ${DateTime.now().toString()}');
    out.writeln('');
    out.writeAll(aux, '\n');
    out.writeln('\n\nValue: ${_fmtCurrency2.format(_json['totalValue'])}');
    return out.toString();
  }

  /// Output a flat report in json format.
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
