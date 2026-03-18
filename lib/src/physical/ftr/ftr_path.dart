import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/client/ftr_clearing_prices.dart';
import 'package:elec_server/client/lmp.dart';
import 'package:http/http.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:more/cache.dart';
import 'ftr_auction.dart';

typedef AuctionName = String;

class FtrPath {
  /// An FTR path
  FtrPath(
      {required this.sourcePtid,
      required this.sinkPtid,
      required this.bucket,
      this.mw = 1,
      required this.iso,
      required Term term,
      required String rootUrl,
      required String rustServer,
      Client? client}) {
    client ??= Client();
    _term ??= term;
    _ftrClearingPricesClient ??=
        FtrClearingPrices(client, iso: iso, rootUrl: rootUrl);
    _rustServer ??= rustServer;
  }

  final int sourcePtid, sinkPtid;
  final num mw;
  final Bucket bucket;
  final Iso iso;

  static Term? _term;
  static String? _rustServer;
  static late String rootUrl;

  static FtrClearingPrices? _ftrClearingPricesClient;

  /// a daily settle price cache
  static final settlePriceCache =
      Cache.lru(loader: ((Iso, Bucket, int, Term) tuple4) {
    switch (tuple4.$1.name) {
      case 'ISONE':
        return IsoNewEngland().getDailyLmp(
            market: Market.da,
            ptid: tuple4.$3,
            component: LmpComponent.congestion,
            bucket: tuple4.$2,
            term: tuple4.$4,
            rustServer: _rustServer!);
      case 'NYISO':
        return NewYorkIso().getDailyLmp(
            market: Market.da,
            ptid: tuple4.$3,
            component: LmpComponent.congestion,
            bucket: tuple4.$2,
            term: tuple4.$4,
            rustServer: _rustServer!);
      default:
        throw UnimplementedError(
            'Settle price cache is only implemented for ISONE and NYISO');
    }
  });

  /// an hourly settle price cache
  static final hourlySettlePriceCache =
      Cache.lru(loader: ((Iso, int, Term) tuple3) {
    switch (tuple3.$1.name) {
      case 'ISONE':
        return IsoNewEngland().getHourlyLmp(
            market: Market.da,
            ptid: tuple3.$2,
            component: LmpComponent.congestion,
            term: tuple3.$3,
            rustServer: _rustServer!);
      case 'NYISO':
        return NewYorkIso().getHourlyLmp(
            market: Market.da,
            ptid: tuple3.$2,
            component: LmpComponent.congestion,
            term: tuple3.$3,
            rustServer: _rustServer!);
      default:
        throw UnimplementedError(
            'Hourly settle price cache is only implemented for ISONE and NYISO');
    }
  });

  /// A clearing price cache
  /// (Iso, ptid) -> {Bucket: {AuctionName: num}}
  static final clearingPriceCache =
      Cache.lru(loader: ((Iso, int) tuple2) async {
    var xs =
        await _ftrClearingPricesClient!.getClearingPricesForPtid(tuple2.$2);
    var groups = groupBy(xs, (Map x) => x['bucket'] as String);
    return groups.map((key, values) {
      var out = {
        for (var value in values)
          value['auctionName'] as AuctionName: value['clearingPriceHour'] as num
      };
      return MapEntry(Bucket.parse(key), out);
    });
  });

  /// Get all auction clearing prices from the database.
  /// Return an empty Map if one of the nodes is not allowed in the
  /// FTR/TCC auction or if there are no auctions this path cleared.
  Future<Map<FtrAuction, num>> getClearingPrices(
      {List<FtrAuction>? auctions}) async {
    var cpSource = await clearingPriceCache.get((iso, sourcePtid));
    var cpSink = await clearingPriceCache.get((iso, sinkPtid));

    var out = <FtrAuction, num>{};
    if (cpSource.isEmpty || cpSink.isEmpty) {
      /// at least one of the nodes has not cleared anything, ever
      return out;
    }

    auctions ??= cpSource[bucket]!
        .keys
        .map((e) => FtrAuction.parse(e, iso: iso))
        .toList();

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
  Future<TimeSeries<num>> getDailySettlePrices({required Term term}) async {
    var sourcePrices =
        await settlePriceCache.get((iso, bucket, sourcePtid, term));
    var sinkPrices = await settlePriceCache.get((iso, bucket, sinkPtid, term));
    late TimeSeries<num> spread;
    if (iso == Iso.newYork) {
      spread = sourcePrices - sinkPrices;
    } else {
      spread = sinkPrices - sourcePrices;
    }

    return TimeSeries.fromIterable(spread.window(term.interval));
  }

  /// Get the hourly settle prices for this path.
  /// If you don't specify the [term], return values from cache
  /// (the last 5 years by default.)
  Future<TimeSeries<num>> getHourlySettlePrices({required Term term}) async {
    var sourcePrices =
        await hourlySettlePriceCache.get((iso, sourcePtid, term));
    var sinkPrices = await hourlySettlePriceCache.get((iso, sinkPtid, term));
    late TimeSeries<num> spread;
    if (iso == Iso.newYork) {
      spread = sourcePrices - sinkPrices;
    } else {
      spread = sinkPrices - sourcePrices;
    }

    return TimeSeries.fromIterable(spread.window(term.interval));
  }

  /// Get the settle price for an auction
  /// If the auction is in the future, return [null]
  ///
  Future<num?> getSettlePriceForAuction(FtrAuction auction) async {
    if (auction.start
        .isAfter(Date.today(location: iso.preferredTimeZoneLocation))) {
      return null;
    }
    Iterable<IntervalTuple<num>> aux =
        await getHourlySettlePrices(term: Term.fromInterval(auction.interval));
    aux = aux.where((e) => bucket.containsHour(e.interval as Hour));
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
  Future<List<({FtrAuction auction, num clearingPrice, num? settlePrice})>>
      makeTableCpSp({required Date fromDate}) async {
    var auctions =
        await _ftrClearingPricesClient!.getAuctions(startDate: fromDate);

    var out = <({FtrAuction auction, num clearingPrice, num? settlePrice})>[];
    var clearingPrices = await getClearingPrices(auctions: auctions);
    for (var auction in clearingPrices.keys) {
      var sp = await getSettlePriceForAuction(auction);
      out.add((
        auction: auction,
        clearingPrice: clearingPrices[auction]!,
        settlePrice: sp
      ));
    }

    return out;
  }

  /// Show the (relevant) constraints that influence this path for this [term].
  /// [bindingConstraints] are the historical hourly binding constraints
  /// in the pool for this term or a longer term.  Only some of these
  /// constraints have direct influence on the path.
  ///
  /// Return a list of elements
  /// ```
  /// {
  ///   'constraintName': 'CENTRAL EAST - VC',
  ///   'hours': 131,
  ///   'Mean Spread': 8.55,
  ///   'Cumulative Spread': 166.78,
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> bindingConstraintEffect(Term term,
      {required Map<String, TimeSeries<num>> bindingConstraints,
      num meanSpreadThreshold = 1.0}) async {
    var out = <Map<String, dynamic>>[];

    var hourlySettlePrice = await getHourlySettlePrices(term: term);
    var settlePrice = TimeSeries.fromIterable(hourlySettlePrice
        .window(term.interval)
        .where((e) => bucket.containsHour(e.interval as Hour)));
    for (var constraint in bindingConstraints.keys) {
      var bc = bindingConstraints[constraint]!.window(term.interval);
      if (bc.isNotEmpty) {
        var join = settlePrice.merge(TimeSeries.fromIterable(bc),
            f: (x, y) => [x, y], joinType: JoinType.Inner);

        /// need to eliminate the false positives, when the constraint binds
        /// but the spread == 0.  Make an exception in case by pure chance, the
        /// spread is zero when the constraint binds in very few hours^*.
        var lr = join.partition((e) => e.value![0] == 0);
        if (lr.item2.isNotEmpty) {
          var effect = mean(lr.item2.map(((e) => e.value[0] as num)));
          if (effect.abs() >= meanSpreadThreshold &&
              lr.item1.length / lr.item2.length < 0.005) {
            out.add({
              'name': constraint,
              'hours': lr.item2.length,
              'Mean Spread': effect,
              'Cumulative Spread': effect * lr.item2.length,
            });
          }
        }
      }
    }
    return out;
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
