library risk_system.pricing.calculators.elec_calc_cdf.elec_calc_cfd;

import 'package:elec/src/risk_system/data_provider/data_provider.dart';
import 'package:elec/src/risk_system/locations/curve_id.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/flat_report.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/monthly_position_report.dart';
import 'package:elec/src/risk_system/pricing/reports/report.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

enum TimePeriod {month, day, hour}

class _BaseCfd {
  DataProvider _dataProvider;
  Date asOfDate;
  BuySell buySell;
  Term term;
  TimePeriod timePeriod;
}

class ElecCalculatorCfd extends _BaseCfd {
  String comments;
  List<CommodityLeg> legs;

  ElecCalculatorCfd();

  /// Needs to have a functioning [DataProvider] for the calculator to price.
  set dataProvider(DataProvider provider) {
    _dataProvider = provider;
    for (var leg in legs) {
      leg._dataProvider = provider;
    }
  }

  /// Get the total dollar value of this calculator.
  num dollarPrice() {
    var value = 0.0;
    for (var leg in legs) {
      for (var leaf in leg.leaves) {
        value += leaf.dollarPrice();
      }
    }
    return value;
  }

  Report flatReport() => FlatReportElecCfd(this);

  Report monthlyPositionReport() => MonthlyPositionReportElecCfd(this);

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
      var leg = CommodityLeg.fromJson(e)
        ..asOfDate = asOfDate
        ..buySell = buySell
        ..term = term;
      if (e.containsKey('floatingPrice')) {
        /// if you pass the floatingPrice to the commodity leg directly
        leg.floatingPrice = _parseSeries(e['floatingPrice'],
            leg.curveId.tzLocation);
        leg.makeLeaves();
      } /// else you have to give the calculator a [dataProvider]
      legs.add(leg);
    }
  }

  /// Serialize it.  Don't serialize 'asOfDate' or 'floatingPrice' info.
  Map<String,dynamic> toJson() {
    return <String,dynamic>{
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [ for (var leg in legs) leg.toJson() ],
    };
  }

}

class CommodityLeg extends _BaseCfd {
  CurveId curveId;
  String cashOrPhys;
  Bucket bucket;

  /// Can be monthly, daily or hourly time series
  TimeSeries<num> quantity;
  TimeSeries<num> fixPrice;
  TimeSeries<num> floatingPrice;

  /// Leg leaves
  List<Leaf> leaves;

  /// Fair value for this commodity leg
  num _price;


  /// Get the quantity weighted floating price for this leg.
  /// Needs [leaves] to be populated.
  num get price {
    if (_price == null) {
      num hpq = 0; // hours * quantity * floatingPrice
      num hq = 0;  // hours * quantity
      for (var leaf in leaves) {
        hpq += leaf.hours * leaf.quantity * leaf.floatingPrice;
        hq += leaf.hours * leaf.quantity;
      }
      _price = hpq/hq;
    }
    return _price;
  }

  /// Get the [floatingPrice] from a provider if not passed in during
  /// construction.
  Future<TimeSeries<num>> getFloatingPrice() async {
    if (floatingPrice == null) {
      var aux = await _dataProvider.getForwardCurveForBucket(curveId, bucket, asOfDate);
      floatingPrice = TimeSeries.fromIterable(aux.timeseries.window(term.interval));
    }
    return floatingPrice;
  }

  /// Make the leaves for this leg.  Needs [floatingPrice].
  /// One leaf per period.
  void makeLeaves() {
    leaves = <Leaf>[];
    if (timePeriod == TimePeriod.month) {
      for (var qty in quantity) {
        Month month = qty.interval;
        var _fixPrice = fixPrice.observationAt(month).value;
        var _floatPrice = floatingPrice.observationAt(month).value;
        var hours = bucket.countHours(month);
        leaves.add(Leaf(buySell, qty.interval, qty.value, _fixPrice,
            _floatPrice, hours));
      }
    } else {
      /// TODO: continue me
      throw UnimplementedError('Not implemented $timePeriod');
    }
  }


  /// need to support hourly, daily and monthly quantities/fixPrices
  CommodityLeg.fromJson(Map<String,dynamic> x) {
    if (x['curveId'] == null) {
      throw ArgumentError('Input needs to have key curveId');
    }
    curveId = CurveId(x['curveId'] as String);
    cashOrPhys = x['cash/physical'];
    if (x['bucket'] == null) {
      throw ArgumentError('Input needs to have key bucket');
    }
    bucket = Bucket.parse(x['bucket']);
    /// quantities are specified as a List of {'month': '2020-01', 'value': 40.0}
    quantity = _parseSeries(x['quantity'], bucket.location);
    /// prices are specified as a List of {'month': '2020-01', 'value': 40.0}
    fixPrice = _parseSeries(x['fixPrice'], bucket.location);

    /// establish the time period for the series
    var _keys = ((x['quantity'] as List).first as Map).keys;
    if (_keys.contains('month')) {
      timePeriod = TimePeriod.month;
    } else if (_keys.contains('date')) {
      timePeriod = TimePeriod.day;
    } else if (_keys.contains('hourBeginning')) {
      timePeriod = TimePeriod.hour;
    } else {
      throw ArgumentError('Leg quantity does\'t contain one of accepted time'
          'periods: month, date, hourBeginning');
    }
  }

  /// serialize it
  Map<String,dynamic> toJson() {
    return <String,dynamic>{
      'curveId': curveId.name,
      'cash/physical': cashOrPhys,
      'bucket': bucket.toString(),
      'quantity': _serializeSeries(quantity),
      'fixPrice': _serializeSeries(fixPrice),
    };
  }
  
}

/// One leaf per period.
class Leaf {
  BuySell buySell;
  Interval interval;
  num quantity;
  num fixPrice;
  num floatingPrice;
  /// number of hours in this period
  int hours;

  Leaf(this.buySell, this.interval, this.quantity, this.fixPrice,
      this.floatingPrice, this.hours);

  num dollarPrice() {
    return buySell.sign * hours * quantity * (floatingPrice - fixPrice);
  }
}

final DateFormat _isoFmt = DateFormat('yyyy-MM');

/// Input [xs] can be a hourly, daily, or monthly series.  Only ISO formats are
/// supported.
TimeSeries<num> _parseSeries(Iterable<Map<String,dynamic>> xs, Location location) {
  var ts = TimeSeries<num>();
  Interval Function(Map<String,dynamic>) parser;
  if (xs.first.keys.contains('month')) {
    parser = (e) => Month.parse(e['month'], location: location, fmt: _isoFmt);
  } else if (xs.first.keys.contains('date')) {
    parser = (e) => Date.parse(e['date'], location: location);
  } else if (xs.first.keys.contains('hourBeginning')) {
    parser = (e) => Hour.beginning(TZDateTime.parse(location, e['hourBeginning']));
  }
  for (var e in xs) {
    ts.add(IntervalTuple(parser(e), e['value'] as num));
  }
  return ts;
}

List<Map<String,dynamic>> _serializeSeries(TimeSeries<num> xs) {
  Map<String,dynamic> Function(IntervalTuple) fun;
  if (xs.first.interval is Month) {
    fun = (e) => {'month': (e.interval as Month).toIso8601String(), 'value': e.value};
  } else if (xs.first.interval is Date) {
    fun = (e) => {'date': (e.interval as Date).toString(), 'value': e.value};
  } else if (xs.first.interval is Hour) {
    fun = (e) => {'hourBeginning': (e.interval as Hour).start.toIso8601String(), 'value': e.value};
  }
  return [ for (var x in xs) fun(x) ];
}
