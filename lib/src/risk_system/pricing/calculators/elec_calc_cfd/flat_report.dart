library risk_system.pricing.calculators.elec_calc_cfd.flat_report;

import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/elec_calc_cfd.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:table/table_base.dart';

class FlatReportElecCfd implements Report {
  ElecCalculatorCfd calculator;

  static final _fmtCurrency2 = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _fmt0 = NumberFormat()..maximumIntegerDigits = 0;


  /// a json output
  Map<String,dynamic> _json;

  FlatReportElecCfd(this.calculator);

  @override
  String toString() {
    _json ?? toJson();
    var out = StringBuffer();
    out.writeln('Flat Report');
    out.writeln('As of date: ${_json['asOfDate']}');
    out.writeln('Printed: ${DateTime.now().toString()}');
    out.writeln('');
    var tbl = _json['table'] as List;
    for (var row in tbl) {
      row['forwardPrice'] = (row['forwardPrice'] as num).toStringAsFixed(2);
      row['nominalQuantity'] = _fmt0.format(row['nominalQuantity'] as num);
      row['value'] = _fmtCurrency2.format(row['value'] as num);
    }
    
    var cashRows = tbl.where((e) => e['curveId'] == 'USD').toList();
    var _tbl = Table.from([
      ...cashRows, 
      ...tbl.where((e) => e['curveId'] != 'USD'), 
    ], options: {'columnSeparation': '  '});
    var aux = _tbl.toString().split('\n');
    aux.insert(cashRows.length + 1, ' ' * aux.first.length);
    aux.insert(cashRows.length + 2, aux.first);
    out.writeAll(aux, '\n');
    out.writeln('\n\nValue: ${_fmtCurrency2.format(_json['totalValue'])}');
    return out.toString();
  }

  /// Output a flat report in json format.
  @override
  Map<String,dynamic> toJson() {
    if (_json == null) {
      var table = <Map<String,dynamic>>[];
      for (var leg in calculator.legs) {
        for (var leaf in leg.leaves) {
          table.add({
            'term': leaf.interval.toString(),
            'curveId': 'USD',
            'bucket': '',
            'nominalQuantity': -leg.buySell.sign * leaf.quantity * leaf.hours * leaf.fixPrice,
            'forwardPrice': 1,
            'value': -leg.buySell.sign * leaf.quantity * leaf.hours * leaf.fixPrice,
          });
          table.add({
            'term': leaf.interval.toString(),
            'curveId': leg.curveId.name,
            'bucket': leg.bucket.toString(),
            'nominalQuantity': leg.buySell.sign * leaf.quantity * leaf.hours,
            'forwardPrice': leaf.floatingPrice,
            'value': leg.buySell.sign * leaf.quantity * leaf.hours * leaf.floatingPrice,
          });
        }
      }
      var out = <String,dynamic>{
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

