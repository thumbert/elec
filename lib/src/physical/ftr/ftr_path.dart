library physical.ftr.ftr_path;

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/client/dalmp.dart';
import 'package:elec_server/client/ftr_clearing_prices.dart';
import 'package:http/http.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:more/cache.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tuple/tuple.dart';
import 'ftr_auction.dart';

/// The term used for historical settled prices
Term? _term;

typedef AuctionName = String;

class FtrPath {
  /// An FTR path
  FtrPath(
      {required this.sourcePtid,
      required this.sinkPtid,
      required this.bucket,
      this.mw = 1,
      required this.iso,
      String rootUrl = 'http://127.0.0.1:8080',
      Client? client}) {
    client ??= Client();

    _daLmpClient = DaLmp(client, rootUrl: rootUrl, iso: iso);
    _ftrClearingPricesClient =
        FtrClearingPrices(client, iso: iso, rootUrl: rootUrl);

    if (_term == null) {
      // set the default _term to the past 5 years
      var now = tz.TZDateTime.now(iso.preferredTimeZoneLocation);
      var end = tz.TZDateTime(
              iso.preferredTimeZoneLocation, now.year, now.month, now.day)
          .add(Duration(days: 1));
      _term = Term.fromInterval(Interval(
          tz.TZDateTime(iso.preferredTimeZoneLocation, now.year - 5), end));
    }
  }

  final int sourcePtid, sinkPtid;
  final num mw;
  final Bucket bucket;
  final Iso iso;

  static late DaLmp _daLmpClient;
  static late FtrClearingPrices _ftrClearingPricesClient;

  /// a daily settle price cache
  static final settlePriceCache =
      Cache.lru(loader: (Tuple3<Iso, Bucket, int> tuple3) {
    return _daLmpClient.getDailyLmpBucket(
        tuple3.item3, // ptid
        LmpComponent.congestion,
        tuple3.item2, // bucket
        _term!.startDate,
        _term!.endDate);
  });

  /// an hourly settle price cache
  static final hourlySettlePriceCache =
      Cache.lru(loader: (Tuple2<Iso, int> tuple2) {
    return _daLmpClient.getHourlyLmp(tuple2.item2, LmpComponent.congestion,
        _term!.startDate, _term!.endDate);
    ;
  });

  /// A clearing price cache
  static final clearingPriceCache =
      Cache.lru(loader: (Tuple2<Iso, int> tuple2) async {
    var xs =
        await _ftrClearingPricesClient.getClearingPricesForPtid(tuple2.item2);
    var groups = groupBy(xs, (Map x) => x['bucket'] as String);
    return groups.map((key, values) {
      var out = {
        for (var value in values)
          value['auctionName'] as AuctionName: value['clearingPriceHour'] as num
      };
      return MapEntry(Bucket.parse(key), out);
    });
  });

  /// Get all auction clearing prices from the database
  Future<Map<FtrAuction, num>> getClearingPrices(
      {List<FtrAuction>? auctions}) async {
    var cpSource = await clearingPriceCache.get(Tuple2(iso, sourcePtid));
    var cpSink = await clearingPriceCache.get(Tuple2(iso, sinkPtid));

    auctions ??= cpSource[bucket]!
        .keys
        .map((e) => FtrAuction.parse(e, iso: iso))
        .toList();

    var out = <FtrAuction, num>{};
    for (var auction in auctions) {
      var auctionName = auction.name;
      var _cpSink = cpSink[bucket]![auctionName];
      var _cpSource = cpSource[bucket]![auctionName];
      if (_cpSource != null && _cpSink != null) {
        // only if both nodes exist
        out[auction] = _cpSink - _cpSource;
      }
    }

    return out;
  }

  /// Set the interval for cache of historical settle prices
  static Future<void> setTermHistoricalSettlePrice(Term term) async {
    _term = term;
    await settlePriceCache.invalidateAll();
  }

  /// Get the daily settle prices for this path.
  /// If you don't specify the [term], return values from cache
  /// (the last 5 years by default.)
  Future<TimeSeries<num>> getDailySettlePrices({Term? term}) async {
    var sourcePrices =
        await settlePriceCache.get(Tuple3(iso, bucket, sourcePtid));
    var sinkPrices = await settlePriceCache.get(Tuple3(iso, bucket, sinkPtid));
    late TimeSeries<num> spread;
    if (iso == Iso.newYork) {
      spread = sourcePrices - sinkPrices;
    } else {
      spread = sinkPrices - sourcePrices;
    }

    if (term == null) {
      // return everything you have in cache
      return spread;
    } else {
      return TimeSeries.fromIterable(spread.window(term.interval));
    }
  }

  /// Get the hourly settle prices for this path.
  /// If you don't specify the [term], return values from cache
  /// (the last 5 years by default.)
  Future<TimeSeries<num>> getHourlySettlePrices({Term? term}) async {
    var sourcePrices =
        await hourlySettlePriceCache.get(Tuple2(iso, sourcePtid));
    var sinkPrices = await hourlySettlePriceCache.get(Tuple2(iso, sinkPtid));
    late TimeSeries<num> spread;
    if (iso == Iso.newYork) {
      spread = sourcePrices - sinkPrices;
    } else {
      spread = sinkPrices - sourcePrices;
    }

    if (term == null) {
      // return everything you have in cache
      return spread;
    } else {
      return TimeSeries.fromIterable(spread.window(term.interval));
    }
  }

  /// Get the settle price for an auction
  Future<num> getSettlePriceForAuction(FtrAuction auction) async {
    var aux =
        await getDailySettlePrices(term: Term.fromInterval(auction.interval));
    if (aux.isEmpty) return double.nan;
    return mean(aux.map((e) => e.value));
  }

  /// Make the table comparing the clearing prices vs. settlement prices for
  /// all the auctions that are in the database after [fromDate].
  /// ```
  /// {
  ///   'auction': FtrAuction,
  ///   'clearingPrice': ...,
  ///   'settlePrice': ...,
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> makeTableCpSp(
      {required Date fromDate}) async {
    var auctions =
        await _ftrClearingPricesClient.getAuctions(startDate: fromDate);

    var out = <Map<String, dynamic>>[];
    var clearingPrices = await getClearingPrices(auctions: auctions);
    for (var auction in clearingPrices.keys) {
      var sp = await getSettlePriceForAuction(auction);
      out.add({
        'auction': auction,
        'clearingPrice': clearingPrices[auction],
        'settlePrice': sp,
      });
    }

    return out;
  }

  /// Get the (relevant) constraints that influence this path.
  /// [bindingConstraints] are the historical hourly binding constraints
  /// in the pool for this term.  Only some of these constraints have direct
  /// influence on the path.
  ///
  Future<List<String>> getRelevantConstraints(Term term, 
      {required Map<String, TimeSeries<num>> bindingConstraints}) async {
    var relevantConstraints = <String>[];

    var hourlySettlePrice = await getHourlySettlePrices();
    var _nonZeroSettlePrice =
        TimeSeries.fromIterable(hourlySettlePrice
            .window(term.interval)
            .where((e) => e.value != 0)
            .where((e) => bucket.containsHour(e.interval as Hour)));
    for (var constraint in bindingConstraints.keys) {
      var bc = bindingConstraints[constraint]!.window(term.interval);
      if (bc.isNotEmpty) {
        var join = _nonZeroSettlePrice.merge(TimeSeries.fromIterable(bc),
            f: (x, y) => 1, joinType: JoinType.Inner);
        if (join.length == bc.length) {
          /// this guarantees that on all the hours the constraint bind, the
          /// spread was non-zero.
          relevantConstraints.add(constraint);
        }
      }
    }
    return relevantConstraints;
  }

  @override
  String toString() {
    var base = '${iso.name} $sourcePtid -> $sinkPtid';
    if (mw != 1) {
      base += ' ${mw}MW';
    }
    if (iso.name == 'NYISO') {
      return base;
    } else {
      return '$base $bucket';
    }
  }
}
