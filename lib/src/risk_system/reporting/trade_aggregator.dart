library risk_system.reporting.trade_aggregator;

import 'package:dama/dama.dart';

class SimpleTradeAggregator {

  List<Map<String,dynamic>> trades;

  // the expanded trades (with each multiple month term expanded into individual
  // months and flat bucket trades expanded into a peak and offpeak trade)
  List<Map<String,dynamic>> _tradesX;


  /// A simple trade aggregator to calculate the total position usually
  /// by month and bucket.  For now only electricity trades.
  /// TODO: find a way to generalize this.
  /// <p> Each trade has this format:
  /// <p>
  /// {'buy/sell': 'buy', 'term': 'Jan20-Dec20', 'bucket': 'flat', 'mw': 25, 'price': 39.60}
  ///
  ///
  SimpleTradeAggregator(this.trades) {
    _tradesX = [];
    for (var trade in trades) {

    }

  }

  /// Calculate the aggregate position and aggregate cost by month/bucket.
  /// The 'Flat' bucket trades will be split into a 'Peak' and 'Offpeak' trade
  /// with the same price.
  List<Map<String,dynamic>> aggregatePosition(){

  }



}