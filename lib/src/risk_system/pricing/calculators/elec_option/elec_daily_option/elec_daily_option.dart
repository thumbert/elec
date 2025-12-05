import 'package:date/date.dart';
import 'package:elec/calculators.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/calculator_base.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/elec_daily_option/commodity_leg.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/elec_daily_option/reports/delta_gamma_report.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/elec_daily_option/reports/flat_report.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_option/elec_daily_option/reports/monthly_position_report.dart';
import 'package:elec/time.dart';
import 'package:intl/intl.dart';
import 'package:table/table_base.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

import '../cache_provider.dart';


class ElecDailyOption extends CalculatorBase<CommodityLeg, CacheProvider> {
  ElecDailyOption(
      {required Date asOfDate,
      required Term term,
      required BuySell buySell,
      required List<CommodityLeg> legs,
      required CacheProvider cacheProvider}) {
    this.asOfDate = asOfDate;
    this.term = term;
    this.buySell = buySell;
    this.legs = legs;
    // these 3 properties are needed for the legs
    for (var leg in this.legs) {
      leg.asOfDate = asOfDate;
      leg.term = term;
      leg.buySell = buySell;
    }
    this.cacheProvider = cacheProvider;
  }

  /// The recommended way to initialize from a template.  See tests.
  /// Still needs [cacheProvider] to be set.
  ElecDailyOption.fromJson(Map<String, dynamic> x) {
    if (x['calculatorType'] != 'elec_daily_option') {
      throw ArgumentError(
          'Json input needs a key calculatorType = elec_daily_option');
    }
    if (x['term'] == null) {
      throw ArgumentError('Json input is missing the key term');
    }
    term = Term.parse(x['term'], UTC);
    if (x['asOfDate'] == null) {
      // if asOfDate is not specified, it means today
      x['asOfDate'] = Date.today(location: UTC).toString();
    }
    asOfDate = Date.parse(x['asOfDate'], location: UTC);
    if (x['buy/sell'] == null) {
      throw ArgumentError('Json input is missing the key buy/sell');
    }
    buySell = BuySell.parse(x['buy/sell']);
    comments = x['comments'] ?? '';

    if (x['legs'] == null) {
      throw ArgumentError('Json input is missing the key: legs');
    }

    legs = <CommodityLeg>[];
    var aux = x['legs'] as List;
    for (Map<String, dynamic> e in aux) {
      e['asOfDate'] = x['asOfDate'];
      e['term'] = x['term'];
      e['buy/sell'] = x['buy/sell'];
      var leg = CommodityLeg.fromJson(e);
      legs.add(leg);
    }
  }

  Term? _term;

  /// in UTC
  @override
  Term get term => _term!;

  @override
  set term(Term term) {
    if (term != _term) {
      // push the term into the legs
      // all timeseries need to be reset only if the term is different
      for (var leg in legs) {
        leg.term =
            Term.fromInterval(term.interval.withTimeZone(leg.tzLocation));
        var months =
            leg.term.interval.splitLeft((dt) => Month.containing(dt));
        leg.quantity = TimeSeries.fill(months, leg.quantity.values.first);
        leg.strike = TimeSeries.fill(months, leg.strike.values.first);
        leg.fixPrice = TimeSeries.fill(months, 0);
        leg.priceAdjustment = TimeSeries.fill(months, 0);
        leg.volatilityAdjustment = TimeSeries.fill(months, 0);
      }
    }
    _term = term;
  }

  @override
  Future<void> build() async {
    for (var leg in legs) {
      var curveDetails = await cacheProvider.curveDetailsCache.get(leg.curveId);
      leg.tzLocation = getLocation(curveDetails['tzLocation']);
      leg.term = Term.fromInterval(term.interval.withTimeZone(leg.tzLocation));
      leg.volatilityCurveId = curveDetails['volatilityCurveId']['daily'];
      leg.underlyingPrice = await getUnderlyingPrice(leg.bucket, leg.curveId);
      var strikeRatio = leg.strike / leg.underlyingPrice;
      leg.volatility =
          await getVolatility(leg.bucket, leg.volatilityCurveId, strikeRatio);
      leg.interestRate = await getInterestRate();
      leg.makeLeaves();
    }
  }

  /// Calculate the delta-gamma report.
  /// Shocks are multipliers to the underlying price, e.g. [-0.1, 0.1] are
  /// -10%, +10% shock in the underlying, respectively.
  Report deltaGammaReport({List<num>? shocks}) =>
      DeltaGammaReportElecDailyOption(this, shocks: shocks);
  Report flatReport() => FlatReportElecDailyOption(this);
  Report monthlyPositionReport() => MonthlyPositionReportElecDailyOption(this);

  @override
  String showDetails() {
    var table = <Map<String, dynamic>>[];
    for (var leg in legs) {
      for (var leaf in leg.leaves) {
        table.add({
          'term': leaf.month.toString(),
          'curveId': leg.curveId,
          'bucket': leg.bucket.toString(),
          'type': leg.callPut.toString(),
          'strike': leaf.strike,
          'quantity': _fmtQty.format(buySell.sign * leaf.quantityTerm),
          'fwdPrice': _fmtCurrency4.format(leaf.underlyingPrice),
          'implVol': _fmt2.format(leaf.volatility * 100),
          'optionPrice': _fmtCurrency4.format(leaf.price()),
          'delta': _fmt2
              .format(leaf.delta() * buySell.sign * leaf.quantityTerm.sign),
          'value': _fmtCurrency0
              .format(buySell.sign * leaf.quantityTerm * leaf.price()),
        });
      }
    }
    var tbl = Table.from(table, options: {
      'columnSeparation': '  ',
    });
    return tbl.toString();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'calculatorType': 'elec_daily_option',
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [for (var leg in legs) leg.toJson()],
    };
  }

  /// Get the underlying price as of the given [asOfDate].
  /// Needs to be one of the marked buckets.  Return a monthly time-series.
  Future<TimeSeries<num>> getUnderlyingPrice(
      Bucket bucket, String curveId) async {
    var fwdMarks =
        await cacheProvider.forwardMarksCache.get((asOfDate, curveId));
    var location = fwdMarks.first.interval.start.location;
    var term0 = term.interval.withTimeZone(location);
    var x = fwdMarks
        .map((e) => IntervalTuple(e.interval, e.value[bucket]!))
        .toTimeSeries();
    return TimeSeries.fromIterable(x.window(term0));
  }

  /// Get the volatility curve for this strike as of the given [asOfDate].
  /// [strikeRatio] is the value you need the volatility surface interpolated.
  /// Needs to be one of the marked buckets.  Return a monthly time-series.
  Future<TimeSeries<num>> getVolatility(Bucket bucket, String volatilityCurveId,
      TimeSeries<num> strikeRatio) async {
    var vSurface = await cacheProvider.volSurfaceCache
        .get((asOfDate, volatilityCurveId));
    var location = vSurface.terms.first.location;
    var term0 = term.interval.withTimeZone(location);
    var months = term0.splitLeft((dt) => Month.containing(dt));

    var xs = TimeSeries<num>();
    for (var i = 0; i < months.length; i++) {
      var value = vSurface.value(bucket, months[i], strikeRatio[i].value);
      xs.add(IntervalTuple(months[i], value));
    }
    return xs;
  }

  /// Get the interest rate/discount factor as of the given [asOfDate].
  /// Return a monthly time-series.
  Future<TimeSeries<num>> getInterestRate() async {
    var months = term.interval.splitLeft((dt) => Month.containing(dt));
    // TODO:  FIXME
    return TimeSeries.fill(months, 0);
  }

  static final _fmtQty = NumberFormat.currency(symbol: '', decimalDigits: 0);
  static final _fmtCurrency0 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _fmtCurrency4 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 4);
  static final _fmt2 = NumberFormat.currency(symbol: '', decimalDigits: 2);
}
