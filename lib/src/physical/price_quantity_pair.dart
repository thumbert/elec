library physical.price_quantity_pair;

import 'package:quiver/core.dart';

class PriceQuantityPair {
  final num price;
  final num quantity;

  PriceQuantityPair(this.price, this.quantity) {
    if (price == null || !price.isFinite)
      throw ArgumentError('Invalid price input $price');
    if (quantity == null || !quantity.isFinite)
      throw ArgumentError('Invalid quantity input $quantity');
  }

  int get hashCode => hash2(price, quantity);

  bool operator ==(dynamic other) {
    if (other != PriceQuantityPair) return false;
    PriceQuantityPair pq = other;
    return pq.price == price && pq.quantity == quantity;
  }
}
