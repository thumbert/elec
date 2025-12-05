enum BidAsk {
  bid,
  ask;

  BidAsk parse(String x) {
    if (x.toLowerCase() == 'bid') {
      return bid;
    } else if (x.toLowerCase() == 'ask') {
      return ask;
    } else {
      throw ArgumentError('Unsupported input $x');
    }
  }
}
