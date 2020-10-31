library risk_system.reporting.trade_aggregator;

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:table/table.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';

enum AggregationVariable { mw, mwh, mtm }

class SimpleTradeAggregator {
  List<Map<String, dynamic>> trades;
  Interval aggregationTerm;

  // the expanded trades (with each multiple month term expanded into individual
  // months and flat bucket trades expanded into a peak and offpeak trade)
  List<Map<String, dynamic>> _tradesX = [];

  Map<Tuple2<Bucket, Month>, int> _hours = {};

  Nest _nestMw, _nestMwh, _nestMtm;

  final _mustHaveColumns = <String>{'buy/sell', 'term', 'bucket', 'mw', 'price'};

  /// A simple trade aggregator to calculate the total position usually
  /// by month and bucket.  For now only for electricity trades.
  /// TODO: find a way to generalize this.
  /// <p> Each trade has this format:
  /// <p>
  /// {'buy/sell': 'buy', 'term': 'Jan20-Dec20', 'bucket': 'flat', 'mw': 25, 'price': 39.60}
  /// <p>
  /// <p> [aggregationTerm] indicates the range of the aggregation, in case
  /// the trades don't cover it completely.  Allows to fill with zeros.
  /// TODO: Don't limit the split to Peak/Offpeak.  Consider (5x16, 2x16H, 7x8).
  SimpleTradeAggregator(this.trades, this.aggregationTerm) {
    _nestMw = Nest()
      ..key((e) => e['bucket'])
      ..key((e) => e['month'])
      ..rollup((List trades) =>
          sum(trades.map((e) => e['buy/sell'].sign * e['mw'])));

    _nestMwh = Nest()
      ..key((e) => e['bucket'])
      ..key((e) => e['month'])
      ..rollup((List trades) =>
          sum(trades.map((e) => e['buy/sell'].sign * e['mw'] * e['hours'])));

    _nestMtm = Nest()
      ..key((e) => e['bucket'])
      ..key((e) => e['month'])
      ..rollup((List trades) => sum(trades
          .map((e) => e['buy/sell'].sign * e['mw'] * e['hours'] * e['price'])));

    var months = aggregationTerm
        .splitLeft((dt) => Month.fromTZDateTime(dt))
        .cast<Month>();
    // add a zero mw flat trades for each month to get completeness
    trades.insertAll(
        0,
        months.map((month) => {
              'buy/sell': 'buy',
              'term': month.toString(),
              'bucket': 'flat',
              'mw': 0,
              'price': 0
            }));

    var location = aggregationTerm.start.location;
    _tradesX = [];
    for (var trade in trades) {
      var aux = Map.fromIterables(
          trade.keys.map((e) => e.toLowerCase()), trade.values);
      _validate(aux);
      var buySell = BuySell.parse(aux['buy/sell']);
      var term = parseTerm(aux['term'], tzLocation: location);
      var bucket = Bucket.parse(aux['bucket']);
      var buckets = <Bucket>[bucket];
      // break down the Flat bucket into Peak and Offpeak trades.
      if (bucket == IsoNewEngland.bucket7x24) {
        buckets = <Bucket>[
          IsoNewEngland.bucketPeak,
          IsoNewEngland.bucketOffpeak
        ];
      }
      for (var bucket in buckets) {
        var mw = aux['mw'];
        var price = aux['price'];
        var _months =
            term.splitLeft((dt) => Month.fromTZDateTime(dt)).cast<Month>();
        for (var month in _months) {
          if (!_hours.containsKey(Tuple2(bucket, month))) {
            _hours[Tuple2(bucket, month)] = _calculateHours(bucket, month);
          }
          _tradesX.add(<String, dynamic>{
            'buy/sell': buySell,
            'month': month,
            'bucket': bucket,
            'mw': mw,
            'price': price,
            'hours': _hours[Tuple2(bucket, month)],
          });
        }
      }
    }
  }

  /// Calculate the aggregate position and aggregate cost by month/bucket.
  /// The 'Flat' bucket trades will be split into a 'Peak' and 'Offpeak' trade
  /// with the same price.
  /// TODO: this should return a MonthlyBucketCurve object
  List<Map<String, dynamic>> aggregate(
      AggregationVariable aggregationVariable) {
    var out;
    if (aggregationVariable == AggregationVariable.mw) {
      var res = _nestMw.map(_tradesX);
      out = flattenMap(res, ['bucket', 'month', 'mw']);

    } else if (aggregationVariable == AggregationVariable.mwh) {
      var res = _nestMwh.map(_tradesX);
      out = flattenMap(res, ['bucket', 'month', 'mwh']);

    } else if (aggregationVariable == AggregationVariable.mtm) {
      var res = _nestMtm.map(_tradesX);
      out = flattenMap(res, ['bucket', 'month', 'mtm']);

    }
    return out;
  }

  int _calculateHours(Bucket bucket, Month month) {
    return month
        .splitLeft((dt) => Hour.beginning(dt))
        .where((hour) => bucket.containsHour(hour))
        .length;
  }

  /// Check inputs
  void _validate(Map<String, dynamic> trade) {
    if (!trade.keys.toSet().containsAll(_mustHaveColumns)) {
      throw ArgumentError('Trade $trade does not have all must have columns');
    }

    /// No negative mw values are allowed.  A flat trade with 0 mw value may
    /// be used to set the monthly ranges for the aggregation.
    if (trade['mw'] < 0) {
      throw ArgumentError('Trade quantity needs to be positive. $trade');
    }
  }
}
