import 'dart:collection';

import 'price_quantity_pair.dart';

class OfferCurve extends ListBase<PriceQuantityPair> {
  var _data = <PriceQuantityPair>[];

  OfferCurve() : _data = <PriceQuantityPair>[];

  OfferCurve.fromIterable(Iterable<PriceQuantityPair> xs) {
    for (var x in xs) {
      add(x);
    }
  }

  @override
  void add(PriceQuantityPair element) {
    if (_data.isNotEmpty && element.price <= _data.last.price) {
      throw StateError('Bid prices need to be decreasing');
    }
    assert(element.quantity > 0);
    _data.add(element);
  }

  @override
  int get length => _data.length;

  @override
  set length(int newLength) => _data.length = newLength;

  @override
  PriceQuantityPair operator [](int index) => _data[index];

  @override
  void operator []=(int index, PriceQuantityPair value) => _data[index] = value;
}
