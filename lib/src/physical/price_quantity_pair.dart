library physical.price_quantity_pair;

class PriceQuantityPair {
  final num price;
  final num quantity;

  PriceQuantityPair(this.price, this.quantity) {
    if (!price.isFinite) {
      throw ArgumentError('Invalid price input $price');
    }
    if (!quantity.isFinite) {
      throw ArgumentError('Invalid quantity input $quantity');
    }
  }

  @override
  int get hashCode => Object.hash(price, quantity);

  @override
  bool operator ==(Object other) {
    if (other is! PriceQuantityPair) return false;
    PriceQuantityPair pq = other;
    return pq.price == price && pq.quantity == quantity;
  }

  @override
  String toString() {
    return '(p: $price, q: $quantity)';
  }
}
