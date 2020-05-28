library risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cdf;

import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

class ElecCalculatorCfd {
  Term term;
  Date asOfDate;
  BuySell buySell;
  String comments;
  List<CommodityLeg> legs;

  num dollarPrice;

  /// The recommended way to initialize.
  ElecCalculatorCfd.fromJson(Map<String, dynamic> x) {
    if (x['term'] == null) {
      throw ArgumentError('Input needs to have key term');
    }
    term = Term.parse(x['term'], UTC);
    if (x['asOfDate'] == null) {
      throw ArgumentError('Input needs to have key asOfDate');
    }
    asOfDate = Date.parse(x['asOfDate'], location: UTC);
    if (x['buy/sell'] == null) {
      throw ArgumentError('Input needs to have key buy/sell');
    }
    buySell = BuySell.parse(x['buy/sell']);
    comments = x['comments'] ?? '';

    if (x['legs'] == null) {
      throw ArgumentError('Input needs to have key legs');
    }
    legs = <CommodityLeg>[];
    var _aux = x['legs'] as List;
    for (Map<String,dynamic> e in _aux) {
      legs.add(CommodityLeg.fromJson(e));
    }
  }
}

class CommodityLeg {
  String region;
  String serviceType;
  String deliveryPoint;
  Market market;
  String cashOrPhys;
  Bucket bucket;
  TimeSeries<num> quantity;
  TimeSeries<num> fixPrice;

  /// need to support both daily and monthly quantities/fixPrices
  CommodityLeg.fromJson(Map<String,dynamic> x) {
    if (x['region'] == null) {
      throw ArgumentError('Input needs to have key region');
    }
    region = x['region'];
    if (x['serviceType'] == null) {
      throw ArgumentError('Input needs to have key serviceType');
    }
    serviceType = x['serviceType'];
    if (x['location'] == null) {
      throw ArgumentError('Input needs to have key location');
    }
    deliveryPoint = x['location'];
    if (x['market'] == null) {
      throw ArgumentError('Input needs to have key market');
    }
    market = Market.parse(x['market']);
    if (x['cash/physical'] == null) {
      throw ArgumentError('Input needs to have key cash/physical');
    }
    cashOrPhys = x['cash/physical'];
    if (x['bucket'] == null) {
      throw ArgumentError('Input needs to have key bucket');
    }
//    try {
//      var iso = Iso.parse(region);
//      bucket = iso.
//    } catch (e) {
//
//    }
    // TODO: make it work with different ISOs.  Now only ISONE works correctly
    bucket = Bucket.parse(x['bucket']);

    /// quantities are specified as a List of {'month': '2020-01', 'value': 40.0}
    quantity = _parseMonthlySeries(x['quantity'], bucket.location);
    /// prices are specified as a List of {'month': '2020-01', 'value': 40.0}
    fixPrice = _parseMonthlySeries(x['fixPrice'], bucket.location);
  }

  ///
  Map<String,dynamic> toJson() {
    return <String,dynamic>{
      'region': region,
      'serviceType': serviceType,
      'deliveryPoint': deliveryPoint,
      'market': market.toString(),
      'cash/physical': cashOrPhys,
      'bucket': bucket.toString(),
      'quantity': [
        for (var e in quantity) {
          'month': (e.interval as Month).toIso8601String(),
          'value': e.value,
        }
      ],
      'fixPrice': [
        for (var e in quantity) {
          'month': (e.interval as Month).toIso8601String(),
          'value': e.value,
        }
      ],
    };
  }
  
}


final DateFormat _isoFmt = DateFormat('yyyy-MM');

TimeSeries<num> _parseMonthlySeries(Iterable<Map<String,dynamic>> xs, Location location) {
  var ts = TimeSeries<num>();
  for (var e in xs) {
    var month = Month.parse(e['month'], location: location, fmt: _isoFmt);
    ts.add(IntervalTuple(month, e['value'] as num));
  }
  return ts;
}
