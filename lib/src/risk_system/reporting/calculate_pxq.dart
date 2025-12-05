import 'package:table/table.dart';

/// Calculate PxQ PnL.  Aggregation is done after with a Nest.
List<Map<String, dynamic>> calculatePxQ(
    List<Map<String, dynamic>> p1,
    List<Map<String, dynamic>> q1,
    List<Map<String, dynamic>> p2,
    List<Map<String, dynamic>> q2) {
  /// rename 'value' key to 'p1'
  var p1s = <Map<String, dynamic>>[];
  for (var e in p1) {
    e['p1'] = e['value'];
    e.remove('value');
    p1s.add(e);
  }

  /// rename 'value' key to 'p2'
  var p2s = <Map<String, dynamic>>[];
  for (var e in p2) {
    e['p2'] = e['value'];
    e.remove('value');
    p2s.add(e);
  }

  /// merge the prices together
  var p12 = join(p1s, p2s);

  /// rename 'value' key to 'q1'
  var q1s = <Map<String, dynamic>>[];
  for (var e in q1) {
    e['q1'] = e['value'];
    e.remove('value');
    q1s.add(e);
  }

  /// rename 'value' key to 'p2'
  var q2s = <Map<String, dynamic>>[];
  for (var e in q2) {
    e['q2'] = e['value'];
    e.remove('value');
    q2s .add(e);
  }

  /// merge the prices together
  var q12 = join(q1s, q2s);

  /// merge prices and quantities together
  var data = join(p12, q12);
  for (var e in data) {
    e['dP PnL'] = e['q1'] * (e['p2'] - e['p1']);
    e['dQ PnL'] = e['p2'] * (e['q2'] - e['q1']);
    e['PnL'] = e['p2'] * e['q2'] - e['p1'] * e['q1'];
  }

  return data;
}
