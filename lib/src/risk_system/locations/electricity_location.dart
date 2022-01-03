library risk_system.electricity_location;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart' as tz;
import 'location.dart';
import 'package:http/http.dart';

part 'electricity_location_isone.dart';

abstract class ElectricityLocation extends Object with Location {
  late String name;
  late int ptid;
  final client = Client();
  late Market market;
  //late Iso iso;
  late tz.Location location;

  /// keep a cache of (asOfDate -> PriceCurve)
  final _futCurveCache = <Date, PriceCurve>{};

  @override
  String toString() => '$name, ptid: $ptid, market: $market';

  /// Historical daily price by bucket
  Future<TimeSeries<num>> getHistoricalDailyBucketPrice(
      Interval interval, Bucket bucket, LmpComponent component) async {
    return TimeSeries<num>();
    // return lmp.getDailyLmpPrices(
    //     bucket, ptid, interval, market, component, iso.name);
  }

  /// Historical monthly price by bucket
  Future<TimeSeries<num>> getHistoricalMonthlyBucketPrice(
      Interval interval, Bucket bucket, LmpComponent component) async {
    return TimeSeries<num>();
    // return lmp.getMonthlyLmpPrices(
    //     bucket, ptid, interval, market, component, iso.name);
  }

  /// Get the daily/monthly futures curve as of a given [asOfDate] for a given bucket.
  Future<TimeSeries<num>> getFuturesCurve(Interval interval, Bucket bucket,
      {Date? asOfDate}) async {
    asOfDate ??= Date.today(location: location);
    if (!_futCurveCache.containsKey(asOfDate)) {
      /// populate the cache with a PriceCurve
      await _populateCache(asOfDate);
    }
    var aux = _futCurveCache[asOfDate]!;
    return aux.points(bucket, interval: interval);
  }

  Future<PriceCurve> getFuturesPriceCurve(
      Interval interval, Date asOfDate) async {
    if (!_futCurveCache.containsKey(asOfDate)) {
      /// populate the cache with a PriceCurve
      await _populateCache(asOfDate);
    }
    return PriceCurve.fromIterable(_futCurveCache[asOfDate]!.window(interval));
  }

  Future<void> _populateCache(Date asOfDate) async {
    /// get it from Mongo
    // _futCurveCache[asOfDate] = PriceCurve.fromBuckets(Map.fromIterables(_buckets, aux));
  }
}
