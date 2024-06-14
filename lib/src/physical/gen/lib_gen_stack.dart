library physical.gen.lib_gen_stack;

import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:more/collection.dart';

/// Get the Stack for a particular [hour] from DuckDb.
/// For ISONE for now
///
Stack getStack(Connection con, Hour hour) {
  var aux = con.fetch('''
SELECT maskedAssetId, segment, price, quantity FROM da_offers 
WHERE HourBeginning = make_timestamp(${hour.start.microsecondsSinceEpoch})
AND UnitStatus != 'UNAVAILABLE'
ORDER BY price;
''');
  return Stack(
      hour: hour,
      maskedAssetId: aux['MaskedAssetId']!.cast<int>(),
      segment: aux['Segment']!.cast<int>(),
      quantity: aux['Quantity']!.cast<num>(),
      price: aux['Price']!.cast<num>());
}

class Stack {
  Stack({
    required this.hour,
    required this.maskedAssetId,
    required this.segment,
    required this.quantity,
    required this.price,
  }) {
    cumQuantity = quantity.cumSum().toList();
  }

  final Hour hour;
  final List<int> maskedAssetId;
  final List<int> segment;

  /// prices are sorted ascendingly
  final List<num> price;
  final List<num> quantity;
  late final List<num> cumQuantity;

  /// Calculate the clearing price for this [loadLevel]
  num clearingPrice(num loadLevel) {
    assert(loadLevel > 0);
    if (loadLevel > cumQuantity.last) return price.last;
    final idx = lowerBound(cumQuantity, loadLevel);
    return price[idx];
  }

  /// Create a new stack by removing a list of units
  Stack removeUnits(Set<int> maskedAssetIds) {
    var newAssetId = <int>[];
    var newSegment = <int>[];
    var newQuantity = <num>[];
    var newPrice = <num>[];
    for (var i = 0; i < maskedAssetId.length; i++) {
      if (maskedAssetIds.contains(maskedAssetId[i])) continue;
      newAssetId.add(maskedAssetId[i]);
      newSegment.add(segment[i]);
      newQuantity.add(quantity[i]);
      newPrice.add(price[i]);
    }
    return Stack(
        hour: hour,
        maskedAssetId: newAssetId,
        segment: newSegment,
        quantity: newQuantity,
        price: newPrice);
  }

  /// Calculate the price effect of removing one unit for a given load level
  /// Units removed are specified by [maskedAssetIds]
  List<num> priceImpactOfUnitsRemoved(
      Set<int> maskedAssetIds, List<num> loadLevels) {
    var newStack = removeUnits(maskedAssetIds);
    var priceDifference = <num>[];
    for (var i = 0; i < loadLevels.length; i++) {
      var change =
          newStack.clearingPrice(loadLevels[i]) - clearingPrice(loadLevels[i]);
      priceDifference.add(change);
    }
    return priceDifference;
  }

  /// Create a Plotly trace
  Map<String, dynamic> toTrace() {
    return {
      'x': quantity.cumSum().toList(),
      'y': price,
      'text': (maskedAssetId, segment)
          .zip()
          .map((e) => 'MaskedAssetId: ${e.$1}, Segment: ${e.$2}')
          .toList(),
    };
  }
}
