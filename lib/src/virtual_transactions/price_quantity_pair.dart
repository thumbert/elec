library virtual_transactions.price_quantity_pair;

import 'package:tuple/tuple.dart';

class PriceQuantityPair {
  num price;
  num quantity;
  Tuple2<num,num> _pq;
  PriceQuantityPair(this.price, this.quantity) {
    _pq = new Tuple2(price, quantity);
  }

  int get hashCode => _pq.hashCode;

  bool operator ==(dynamic other) {
    if (other != PriceQuantityPair) return false;
    PriceQuantityPair pq = other;
    return pq.price == price && pq.quantity == quantity;
  }
}
