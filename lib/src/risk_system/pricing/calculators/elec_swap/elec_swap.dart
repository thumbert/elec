import 'package:date/date.dart';
import 'package:elec/calculators.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/calculator_base.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/cache_provider.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/commodity_leg.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/reports/flat_report.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_swap/reports/monthly_position_report.dart';
import 'package:elec/time.dart';
import 'package:intl/intl.dart';
import 'package:table/table_base.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';



class ElecSwapCalculator extends CalculatorBase<CommodityLeg, CacheProvider> {
  ElecSwapCalculator(
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
  ElecSwapCalculator.fromJson(Map<String, dynamic> x) {
    if (x['calculatorType'] != 'elec_swap') {
      throw ArgumentError('Json input needs a key calculatorType = elec_swap');
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

  /// After you make a change to the calculator that affects the floating price,
  /// you need to rebuild it before repricing it.
  ///
  /// If you change the term, the pricing date, any of the leg buckets, etc.
  /// It is a brittle design, because people may forget to call it.
  @override
  Future<void> build() async {
    for (var leg in legs) {
      var curveDetails = await cacheProvider.curveDetailsCache.get(leg.curveId);
      leg.tzLocation = getLocation(curveDetails['tzLocation']);
      leg.hourlyFloatingPrice = await getFloatingPrice(leg.bucket, leg.curveId);
      leg.makeLeaves();
    }
  }

  Report flatReport() => FlatReportElecCfd(this);

  Report monthlyPositionReport() => MonthlyPositionReportElecCfd(this);

  @override
  String showDetails() {
    var table = <Map<String, dynamic>>[];
    for (var leg in legs) {
      for (var leaf in leg.leaves) {
        table.add({
          'term': leaf.interval.toString(),
          'curveId': leg.curveId,
          'bucket': leg.bucket.toString(),
          'nominalQuantity':
              _fmtQty.format(buySell.sign * leaf.quantity * leaf.hours),
          'forwardPrice': _fmtCurrency4.format(leaf.floatingPrice),
          'value': _fmtCurrency0.format(
              buySell.sign * leaf.quantity * leaf.hours * leaf.floatingPrice),
        });
      }
    }
    var tbl0 = Table.from(table, options: {
      'columnSeparation': '  ',
    });
    return tbl0.toString();
  }

  /// Serialize it.  Don't serialize 'asOfDate' or 'floatingPrice' info.
  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'calculatorType': 'elec_swap',
      'term': term.toString(),
      'buy/sell': buySell.toString(),
      'comments': comments,
      'legs': [for (var leg in legs) leg.toJson()],
    };
  }

  /// Get daily and monthly marks for a given curveId and bucket.
  /// LMP curves will also use an hourly shape curve to support non-standard
  /// buckets.
  ///
  /// Return a timeseries of hourly prices, for only the hours of interest.
  Future<TimeSeries<num>> getFloatingPrice(
      Bucket bucket, String curveId) async {
    var curveDetails = await cacheProvider.curveDetailsCache.get(curveId);
    var fwdMarks =
        await cacheProvider.forwardMarksCache.get((asOfDate, curveId));

    var location = fwdMarks.first.interval.start.location;
    var term0 = term.interval.withTimeZone(location);
    var res = TimeSeries.fromIterable(fwdMarks
        .window(term0)
        .where((obs) => bucket.containsHour(obs.interval as Hour)));

    error = res.isEmpty
        ? 'No prices found in the Db for curve $curveId and bucket $bucket'
        : '';

    if (curveDetails.containsKey('hourlyShapeCurveId')) {
      /// get the hourly shaping curve if needed
      var hSchedule = await cacheProvider.hourlyShapeCache
          .get((asOfDate, curveDetails['hourlyShapeCurveId']));
      var hShapeMultiplier = TimeSeries.fromIterable(
          hSchedule.window(term.interval.withTimeZone(location)));

      /// multiply each hour by the shape factor
      res = res * hShapeMultiplier;
    }

    /// Check if you need to add settlement prices
    var startDate = Date.containing(fwdMarks.first.interval.start);
    if (term.startDate.isBefore(startDate)) {
      /// need to get settlement data, return all hours of the term
      var settlementData =
          await cacheProvider.settlementPricesCache.get((term, curveId));
      if (term.interval.start.isBefore(settlementData.first.interval.start)) {
        // Clear the settlement cache if term start is earlier than existing
        // term.  This only gets executed once, for the first leg.
        await cacheProvider.settlementPricesCache.invalidateAll();
        settlementData = await cacheProvider.settlementPricesCache
            .get((term, curveId));
      }

      /// select only the bucket you need
      var sData = settlementData.where((e) => bucket.containsHour(e.interval as Hour));

      /// put it together
      res = TimeSeries<num>()
        ..addAll([
          ...sData,
          ...res.window(Interval(sData.last.interval.end, term0.end)),
        ]);
    }

    return res;
  }

  static final _fmtQty = NumberFormat.currency(symbol: '', decimalDigits: 0);
  static final _fmtCurrency0 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _fmtCurrency4 =
      NumberFormat.currency(symbol: '\$', decimalDigits: 4);
}
