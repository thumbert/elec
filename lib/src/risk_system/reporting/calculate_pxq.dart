import 'package:table/table.dart';

/// Calculate PxQ PnL.  Aggregation is done after with a Nest.
List<Map<String, dynamic>> calculatePxQ(
    List<Map<String, dynamic>> p1,
    List<Map<String, dynamic>> q1,
    List<Map<String, dynamic>> p2,
    List<Map<String, dynamic>> q2) {
  /// rename 'value' key to 'p1'
  var _p1 = <Map<String, dynamic>>[];
  for (var e in p1) {
    e['p1'] = e['value'];
    e.remove('value');
    _p1.add(e);
  }

  /// rename 'value' key to 'p2'
  var _p2 = <Map<String, dynamic>>[];
  for (var e in p2) {
    e['p2'] = e['value'];
    e.remove('value');
    _p2.add(e);
  }

  /// merge the prices together
  var _p12 = join(_p1, _p2);

  /// rename 'value' key to 'q1'
  var _q1 = <Map<String, dynamic>>[];
  for (var e in q1) {
    e['q1'] = e['value'];
    e.remove('value');
    _q1.add(e);
  }

  /// rename 'value' key to 'p2'
  var _q2 = <Map<String, dynamic>>[];
  for (var e in q2) {
    e['q2'] = e['value'];
    e.remove('value');
    _q2.add(e);
  }

  /// merge the prices together
  var _q12 = join(_q1, _q2);

  /// merge prices and quantities together
  var data = join(_p12, _q12);
  for (var e in data) {
    e['dP PnL'] = e['q1'] * (e['p2'] - e['p1']);
    e['dQ PnL'] = e['p2'] * (e['q2'] - e['q1']);
    e['PnL'] = e['p2'] * e['q2'] - e['p1'] * e['q1'];
  }

  return data;
}
