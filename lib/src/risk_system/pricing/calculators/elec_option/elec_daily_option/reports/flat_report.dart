library risk_system.pricing.calculators.elec_option.elec_daily_option.reports.flat_report;

import 'package:elec/calculators/elec_daily_option.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:table/table_base.dart';

class FlatReportElecDailyOption implements Report {
  ElecDailyOption calculator;

  static final _fmtCurrency2 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _fmt0 = NumberFormat()..maximumIntegerDigits = 0;

  /// a json output
  Map<String, dynamic> _json;

  FlatReportElecDailyOption(this.calculator);

  @override
  String toString() {
    _json ??= toJson();
    var tbl = _json['table'] as List;
    for (var row in tbl) {
      row['forwardPrice'] = (row['forwardPrice'] as num).toStringAsFixed(2);
      if (row['optionPrice'] is num) {
        row['optionPrice'] = row['optionPrice'].toStringAsFixed(2);
      }
      row['nominalQuantity'] = _fmt0.format(row['nominalQuantity'] as num);
      row['value'] = _fmtCurrency2.format(row['value'] as num);
    }

    // rearrange the leaves, start with the USD leaves first
    var cashRows = tbl.where((e) => e['curveId'] == 'USD').toList();
    var _tbl = Table.from([
      ...cashRows,
      ...tbl.where((e) => e['curveId'] != 'USD'),
    ], options: {
      'columnSeparation': '  '
    });

    // add spacing between fixed and floating commodities
    var aux = _tbl.toString().split('\n');
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
    if (_json == null) {
      var table = <Map<String, dynamic>>[];
      for (var leg in calculator.legs) {
        for (var leaf in leg.leaves) {
          // cash lines first
          table.add({
            'term': leaf.month.toString(),
            'curveId': 'USD',
            'bucket': '',
            'expiration': leaf.month.endDate,
            'strike': '',
            'type': '',
            'nominalQuantity':
                -calculator.buySell.sign * leaf.quantityTerm * leaf.fixPrice,
            'forwardPrice': 1,
            'optionPrice': '',
            'value':
                -calculator.buySell.sign * leaf.quantityTerm * leaf.fixPrice,
          });
          // commodity lines
          table.add({
            'term': leaf.month.toString(),
            'curveId': leg.curveId,
            'bucket': leg.bucket.toString(),
            'expiration': leaf.expirationDate,
            'strike': leaf.strike,
            'type': leaf.callPut,
            'nominalQuantity': calculator.buySell.sign * leaf.quantityTerm,
            'forwardPrice': leaf.underlyingPrice,
            'optionPrice': leaf.price(),
            'value': calculator.buySell.sign * leaf.quantityTerm * leaf.price()
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
