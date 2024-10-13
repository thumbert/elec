import 'dart:io';

import 'package:dama/basic/count.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/battery.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/offer_curve.dart';
import 'package:elec/src/price/lib_hourly_lmp.dart';
import 'package:elec_server/utils.dart';
import 'package:intl/intl.dart';
import 'package:table/table.dart';
import 'package:table/table_base.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';

class ReportDriver {
  ReportDriver({
    required this.battery,
    required this.initialState,
    required this.daPrices,
    required this.rtPrices,
  });

  final Battery battery;
  final BatteryState initialState;
  final TimeSeries<num> daPrices;
  final TimeSeries<num> rtPrices;
  
  static late Directory outDir;
  static final fmt = NumberFormat('###,###');
  static final fmt2 = NumberFormat('###,###.00');

  /// Run the whole thing to generate the mdbook assets
  void run(Term term) {
    // oneDayAnalysis(
    //     day: Date(2024, 1, 1, location: IsoNewEngland.location), report: this);
    dailyPnlPlot(Term.parse('Jan21-Dec21', IsoNewEngland.location));
    dailyPnlPlot(Term.parse('Jan22-Dec22', IsoNewEngland.location));
    dailyPnlPlot(Term.parse('Jan23-Dec23', IsoNewEngland.location));
    dailyPnlPlot(Term.parse('Jan24-Aug24', IsoNewEngland.location));
    monthlyPnl(term);
  }

  ///
  void dailyPnlPlot(Term term) {
    assert(term.isMonthRange() || term.isOneMonth());
    var daPrice = daPrices.window(term.interval).toTimeSeries();
    var rtPrice = rtPrices.window(term.interval).toTimeSeries();
    var months = term.interval.splitLeft((dt) => Month.containing(dt));

    /// Run the DA schedule
    var daBidsOffers = TimeSeries<({BidCurve bids, OfferCurve offers})>();
    for (var month in months) {
      daBidsOffers.addAll(makeBidsOffers(
        term: Term.fromInterval(month),
        chargeHours: getChargeHours(month, 0),
        dischargeHours: getDischargeHours(month, 0),
        chargingBids: [PriceQuantityPair(800, battery.maxLoadMw)],
        nonChargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        dischargingOffers: [PriceQuantityPair(0, battery.ecoMaxMw)],
        nonDischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
      ));
    }
    var opt = BatteryOptimizationSimple(
      battery: battery,
      initialBatteryState: initialState,
      daPrice: daPrice,
      rtPrice: rtPrice,
      daBidsOffers: daBidsOffers,
      rtBidsOffers: daBidsOffers,
    );
    opt.run();
    var dailyPnl1 = opt.pnlDa.toDaily(sum);

    /// Run in the RT only, no DA dispatch
    daBidsOffers = TimeSeries<({BidCurve bids, OfferCurve offers})>();
    var rtBidsOffers = TimeSeries<({BidCurve bids, OfferCurve offers})>();
    for (var month in months) {
      daBidsOffers.addAll(makeBidsOffers(
        term: Term.fromInterval(month),
        chargeHours: getChargeHours(month, 0),
        dischargeHours: getDischargeHours(month, 0),
        chargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        nonChargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        dischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
        nonDischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
      ));
      rtBidsOffers.addAll(makeBidsOffers(
        term: Term.fromInterval(month),
        chargeHours: getChargeHours(month, 0),
        dischargeHours: getDischargeHours(month, 0),
        chargingBids: [PriceQuantityPair(800, battery.maxLoadMw)],
        nonChargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        dischargingOffers: [PriceQuantityPair(0, battery.ecoMaxMw)],
        nonDischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
      ));
    }
    opt = BatteryOptimizationSimple(
      battery: battery,
      initialBatteryState: initialState,
      daPrice: daPrice,
      rtPrice: rtPrice,
      daBidsOffers: daBidsOffers,
      rtBidsOffers: rtBidsOffers,
    );
    opt.run();
    var dailyPnlDa2 = opt.pnlDa.toDaily(sum);
    var dailyPnlRt2 = opt.pnlRt.toDaily(sum);
    var dailyPnl2 = dailyPnlDa2 + dailyPnlRt2;


    ///
    /// Run ISO optimal DA schedule
    ///
    var opt3 = BatteryOptimizationIso(
      battery: battery,
      initialBatteryState: initialState,
      daPrice: daPrice,
      endChargingBeforeHour: 15,
    );
    opt3.run();
    var pnlDa3 = opt3.pnlDa.toDaily(sum);
    var pnlRt3 = opt3.pnlRt.toDaily(sum);
    var dailyPnl3 = pnlDa3 + pnlRt3;


    /// make plot with dispatch & prices
    var traces = <Map<String, dynamic>>[];
    traces.add({
      'x': dailyPnl1.intervals
          .map((e) => e.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': dailyPnl1.values.toList(),
      'name': 'DA fixed',
      'line': {
        'color': '#2ca02c',
        // 'color': '#9494b8',
      }
    });
    traces.add({
      'x': dailyPnl2.intervals
          .map((e) => e.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': dailyPnl2.values.toList(),
      'name': 'RT fixed',
      'line': {
        'color': '#d62728',
      }
    });
    traces.add({
      'x': dailyPnl3.intervals
          .map((e) => e.start.toIso8601String().substring(0, 10))
          .toList(),
      'y': dailyPnl3.values.toList(),
      'name': 'ISO DA optim',
      'line': {
        'color': '#9467bd',
      }
    });
    var layout = <String, dynamic>{
      'title': '$term',
      'width': 800,
      'height': 650,
      'yaxis': {
        'title': 'Daily PnL, \$',
      },
    };
    var label =
        term.toString().replaceAll('-', '').replaceAll(' ', '').toLowerCase();
    final file = File('${ReportDriver.outDir.path}/daily_pnl_$label.html');
    Plotly.now(traces, layout, file: file);
  }

  ///  Calculate monthly profitability of a battery using various strategies.
  ///
  void monthlyPnl(Term term) {
    assert(term.isMonthRange() || term.isOneMonth());
    var daPrice = daPrices.window(term.interval).toTimeSeries();
    var rtPrice = rtPrices.window(term.interval).toTimeSeries();
    var months = term.interval.splitLeft((dt) => Month.containing(dt));

    ///
    /// Run a fixed DA schedule
    ///
    var daBidsOffers = TimeSeries<({BidCurve bids, OfferCurve offers})>();
    for (var month in months) {
      daBidsOffers.addAll(makeBidsOffers(
        term: Term.fromInterval(month),
        chargeHours: getChargeHours(month, 0),
        dischargeHours: getDischargeHours(month, 0),
        chargingBids: [PriceQuantityPair(800, battery.maxLoadMw)],
        nonChargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        dischargingOffers: [PriceQuantityPair(0, battery.ecoMaxMw)],
        nonDischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
      ));
    }
    var opt = BatteryOptimizationSimple(
      battery: battery,
      initialBatteryState: initialState,
      daPrice: daPrice,
      rtPrice: rtPrice,
      daBidsOffers: daBidsOffers,
      rtBidsOffers: daBidsOffers,
    );
    opt.run();
    var pnl1 = opt.pnlDa.toMonthly(sum);
    print(toYearly(pnl1, sum));

    ///
    /// Run a fixed RT schedule, no DA dispatch
    ///
    daBidsOffers = TimeSeries<({BidCurve bids, OfferCurve offers})>();
    var rtBidsOffers = TimeSeries<({BidCurve bids, OfferCurve offers})>();
    for (var month in months) {
      daBidsOffers.addAll(makeBidsOffers(
        term: Term.fromInterval(month),
        chargeHours: getChargeHours(month, 0),
        dischargeHours: getDischargeHours(month, 0),
        chargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        nonChargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        dischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
        nonDischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
      ));
      rtBidsOffers.addAll(makeBidsOffers(
        term: Term.fromInterval(month),
        chargeHours: getChargeHours(month, 0),
        dischargeHours: getDischargeHours(month, 0),
        chargingBids: [PriceQuantityPair(800, battery.maxLoadMw)],
        nonChargingBids: [PriceQuantityPair(0, battery.maxLoadMw)],
        dischargingOffers: [PriceQuantityPair(0, battery.ecoMaxMw)],
        nonDischargingOffers: [PriceQuantityPair(800, battery.ecoMaxMw)],
      ));
    }
    opt = BatteryOptimizationSimple(
      battery: battery,
      initialBatteryState: initialState,
      daPrice: daPrice,
      rtPrice: rtPrice,
      daBidsOffers: daBidsOffers,
      rtBidsOffers: rtBidsOffers,
    );
    opt.run();
    var pnlDa2 = opt.pnlDa.toMonthly(sum);
    var pnlRt2 = opt.pnlRt.toMonthly(sum);
    var pnl2 = pnlDa2 + pnlRt2;

    ///
    /// Run ISO optimal DA schedule
    ///
    var opt3 = BatteryOptimizationIso(
      battery: battery,
      initialBatteryState: initialState,
      daPrice: daPrice,
      endChargingBeforeHour: 15,
    );
    opt3.run();
    var pnlDa3 = opt3.pnlDa.toMonthly(sum);
    var pnlRt3 = opt3.pnlRt.toMonthly(sum);
    var pnl3 = pnlDa3 + pnlRt3;

    ///
    /// Run ISO optimal DA schedule
    ///
    var opt4 = BatteryOptimizationFlex(
      battery: battery,
      initialBatteryState: initialState,
      daPrice: daPrice,
      rtPrice: rtPrice,
      dischargeMultiplier: 1.3,
      chargeDiscount: 0.8,
      endChargingBeforeHour: 15,
    );
    opt4.run();
    var pnlDa4 = opt4.pnlDa.toMonthly(sum);
    var pnlRt4 = opt4.pnlRt.toMonthly(sum);
    var pnl4 = pnlDa4 + pnlRt4;

    /// Calculate yearly value in $/kW-month
    var byYear = [
      ...toYearly(pnl1, (xs) => mean(xs) / battery.ecoMaxMw / 1000).map((e) => {
            'Strategy': 'DA fixed',
            'Year': e.interval.start.year,
            'Value': e.value,
          }),
      ...toYearly(pnl2, (xs) => mean(xs) / battery.ecoMaxMw / 1000).map((e) => {
            'Strategy': 'RT fixed',
            'Year': e.interval.start.year,
            'Value': e.value,
          }),
      ...toYearly(pnl3, (xs) => mean(xs) / battery.ecoMaxMw / 1000).map((e) => {
            'Strategy': 'ISO DA optim',
            'Year': e.interval.start.year,
            'Value': e.value,
          }),
      ...toYearly(pnl4, (xs) => mean(xs) / battery.ecoMaxMw / 1000).map((e) => {
            'Strategy': 'Flex',
            'Year': e.interval.start.year,
            'Value': e.value,
          }),
    ];
    var tbl = Table.from(
        reshape(byYear, ['Year'], ['Strategy'], 'Value', fill: 'N/A'),
        options: {
          'format': {
            'DA fixed': (e) => fmt2.format(e as num),
            'RT fixed': (e) => fmt2.format(e as num),
            'ISO DA optim': (e) => fmt2.format(e as num),
            'Flex': (e) => fmt2.format(e as num),
          }
        });
    print(tbl);
    File('${ReportDriver.outDir.path}/annual_value.html').writeAsStringSync(
        tbl.toHtml(
            caption:
                '<b>Table</b>:  Profitablity of the battery by year, in \$/kW-month.'));

    /// Make plot with dispatch & prices in $/kW-month
    () {
      var traces = <Map<String, dynamic>>[];
      traces.add({
        'x': pnl1.intervals
            .map((e) => e.start.toIso8601String().substring(0, 10))
            .toList(),
        'y': pnl1.values.map((e) => e / 1000 / battery.ecoMaxMw).toList(),
        'name': 'DA fixed',
        'line': {
          'color': '#2ca02c', // cooked asparagus
        }
      });
      traces.add({
        'x': pnl2.intervals
            .map((e) => e.start.toIso8601String().substring(0, 10))
            .toList(),
        'y': pnl2.values.map((e) => e / 1000 / battery.ecoMaxMw).toList(),
        'name': 'RT fixed',
        'line': {
          'color': '#d62728', // brick red
        }
      });
      traces.add({
        'x': pnl3.intervals
            .map((e) => e.start.toIso8601String().substring(0, 10))
            .toList(),
        'y': pnl3.values.map((e) => e / 1000 / battery.ecoMaxMw).toList(),
        'name': 'ISO DA optim',
        'line': {
          'color': '#9467bd', // muted purple
        }
      });
      // traces.add({
      //   'x': pnl4.intervals
      //       .map((e) => e.start.toIso8601String().substring(0, 10))
      //       .toList(),
      //   'y': pnl4.values.map((e) => e / 1000 / battery.ecoMaxMw).toList(),
      //   'name': 'Flex',
      //   'line': {
      //     'color': '#e377c2', // raspberry pink
      //   }
      // });


      var layout = <String, dynamic>{
        'title': '$term',
        'width': 800,
        'height': 650,
        'yaxis': {
          'title': 'Monthly PnL, \$/kW-month',
        },
      };
      var label =
          term.toString().replaceAll('-', '').replaceAll(' ', '').toLowerCase();
      final file = File('${ReportDriver.outDir.path}/monthly_pnl_$label.html');
      Plotly.now(traces, layout, file: file);
    }();
  }
}

/// Create a table with the best charging/discharging blocks.
///
void makeHtmlTableBestBlocks(List<Term> terms, TimeSeries<num> hourlyPrices,
    {required int n, required Directory outDir}) {
  // Keep only the topK blocks for each term to simplify the table
  var topK = 3;
  var rows = <Map<String, dynamic>>[];
  for (var term in terms) {
    var ts = hourlyPrices.window(term.interval).toTimeSeries();
    var res = tabulateBestBlocks(hourlyPrices: ts, n: 4);
    // best discharging blocks
    var maxD = count<int>(
        res.expand((e) => List<int>.filled(e['count'], e['maxIndex'])));
    // best charging blocks
    var minD = count<int>(
        res.expand((e) => List<int>.filled(e['count'], e['minIndex'])));
    var tblMin = minD.entries
        .map<Map<String, dynamic>>(
            (e) => {'action': 'charge', 'hourIndex': e.key, 'count': e.value})
        .toList();
    tblMin.sort((a, b) => -a['count'].compareTo(b['count']));
    var tblMax = maxD.entries
        .map<Map<String, dynamic>>((e) =>
            {'action': 'discharge', 'hourIndex': e.key, 'count': e.value})
        .toList();
    tblMax.sort((a, b) => -a['count'].compareTo(b['count']));
    for (var i = 0; i < topK; i++) {
      rows.add({
        'term': term.toString(),
        'hourCharging': tblMin[i]['hourIndex'],
        'countCharging': tblMin[i]['count'],
        'hourDischarging': tblMax[i]['hourIndex'],
        'countDischarging': tblMax[i]['count'],
      });
    }
  }
  var table = Table.from(rows);
  var str = table.toHtml(
      className: 'best-blocks-table',
      caption:
          '''<b>Table</b>: Count the days with the best 4 hour blocks for charging and discharging by term.  
      For each term, the best 3 choices of charging and discharging starts are shown together with the 
      corresponding number of days in term.  'Best' is defined such that the highest price spread is 
      achieved between the charging and discharging hours, with the constraint that charging hours must 
      occur before discharging. ''',
      includeColumnNames: false,
      extraHeaders: [
        '''<tr>
      <th> </th>
      <th colspan="2" style="background-color: #ffb3b3;">Charging</th>
      <th colspan="2" style="background-color: #9fdfbf;">Discharging</th>
    </tr>''',
        '''<tr>
      <th>Term</th>
      <th>Hour</th>
      <th>Count</th>
      <th>Hour</th>
      <th>Count</th>
    </tr>''',
      ]);
  // print(table);
  File('${outDir.path}/table.html').writeAsStringSync(str);
}

void priceStats(TimeSeries<num> daPrice) {
  final terms = [
    Term.parse('Dec20-Feb21', IsoNewEngland.location),
    Term.parse('Mar21-May21', IsoNewEngland.location),
    Term.parse('Jun21-Sep21', IsoNewEngland.location),
    Term.parse('Oct21-Nov21', IsoNewEngland.location),
    //
    Term.parse('Dec21-Feb22', IsoNewEngland.location),
    Term.parse('Mar22-May22', IsoNewEngland.location),
    Term.parse('Jun22-Sep22', IsoNewEngland.location),
    Term.parse('Oct22-Nov22', IsoNewEngland.location),
    //
    Term.parse('Dec22-Feb23', IsoNewEngland.location),
    Term.parse('Mar23-May23', IsoNewEngland.location),
    Term.parse('Jun23-Sep23', IsoNewEngland.location),
    Term.parse('Oct23-Nov23', IsoNewEngland.location),
    //
    Term.parse('Dec23-Feb24', IsoNewEngland.location),
    Term.parse('Mar24-May24', IsoNewEngland.location),
    Term.parse('Jun24-Sep24', IsoNewEngland.location),
    // Term.parse('Oct24-Nov23', IsoNewEngland.location),
  ];

  makeHtmlTableBestBlocks(
    terms,
    daPrice,
    n: 4,
    outDir: ReportDriver.outDir!,
  );
}

///
void oneDayAnalysis({
  required Date day,
  required ReportDriver report,
}) {
  var term = Term(day, day);
  var daPrices = report.daPrices.window(term.interval).toTimeSeries();
  var rtPrices = report.rtPrices.window(term.interval).toTimeSeries();

  final opt = BatteryOptimizationSimple(
    battery: report.battery,
    initialBatteryState: report.initialState,
    daPrice: daPrices,
    rtPrice: rtPrices,
    daBidsOffers: makeBidsOffers(
      term: term,
      chargeHours: getChargeHours(Month.containing(day.start), 0),
      dischargeHours: getDischargeHours(Month.containing(day.start), 0),
      chargingBids: [PriceQuantityPair(100, report.battery.maxLoadMw)],
      nonChargingBids: [PriceQuantityPair(0, report.battery.maxLoadMw)],
      dischargingOffers: [PriceQuantityPair(0, report.battery.ecoMaxMw)],
      nonDischargingOffers: [PriceQuantityPair(100, report.battery.ecoMaxMw)],
    ),
    rtBidsOffers: makeBidsOffers(
      term: term,
      chargeHours: getChargeHours(Month.containing(day.start), 0),
      dischargeHours: getDischargeHours(Month.containing(day.start), 0),
      chargingBids: [PriceQuantityPair(100, report.battery.maxLoadMw)],
      nonChargingBids: [PriceQuantityPair(0, report.battery.maxLoadMw)],
      dischargingOffers: [PriceQuantityPair(0, report.battery.ecoMaxMw)],
      nonDischargingOffers: [PriceQuantityPair(100, report.battery.ecoMaxMw)],
    ),
  );
  opt.run();
  // print(opt.dispatchDa);

  /// make plot with dispatch & prices
  var traces = <Map<String, dynamic>>[];
  traces.add({
    'x': [day.start.toIso8601String(), day.end.toIso8601String()],
    'y': [opt.battery.totalCapacityMWh, opt.battery.totalCapacityMWh],
    'name': 'Max Capacity',
    'line': {
      'color': 'black',
    },
    'mode': 'lines',
    'type': 'scatter',
  });
  traces.add({
    'x':
        opt.dispatchRt.intervals.map((e) => e.start.toIso8601String()).toList(),
    'y': opt.dispatchRt.values.map((e) => e.endState.batteryLevelMwh).toList(),
    'name': 'Battery level',
    'line': {
      'color': '#9494b8',
    }
  });
  traces.add({
    'x': daPrices.map((e) => e.interval.start.toIso8601String()).toList(),
    'y': daPrices.map((e) => e.value).toList(),
    'name': 'DA price',
    'yaxis': 'y2',
  });
  traces.add({
    'x': rtPrices.map((e) => e.interval.start.toIso8601String()).toList(),
    'y': rtPrices.map((e) => e.value).toList(),
    'name': 'RT price',
    'yaxis': 'y2',
  });

  var layout = <String, dynamic>{
    'title': '$day',
    'width': 800,
    'height': 650,
    'yaxis': {
      'title': 'Battery level, MWh',
      'showgrid': false,
    },
    'yaxis2': {
      // 'showgrid': false,
      'title': 'Price, \$/MWh',
      'overlaying': 'y',
      'side': 'right',
    },
  };
  final yyyymmdd =
      day.start.toIso8601String().substring(0, 10).replaceAll('-', '');
  final file = File('${ReportDriver.outDir.path}/one_day_$yyyymmdd.html');
  Plotly.now(traces, layout, file: file);
}

/// Historical ISONE best hours
Set<int> getChargeHours(Month month, int rank) {
  return switch (rank) {
    0 => switch (month.month) {
        6 || 7 || 8 || 9 => {2, 3, 4, 5},
        _ => {1, 2, 3, 4}
      },
    1 => switch (month.month) {
        6 || 7 || 8 || 9 || 10 || 11 => {1, 2, 3, 4},
        12 || 1 || 2 => {0, 1, 2, 3},
        _ => {12, 13, 14, 15},
      },
    _ => throw StateError('Rank $rank not implemented'),
  };
}

/// Historical ISONE best hours
Set<int> getDischargeHours(Month month, int rank) {
  return switch (rank) {
    0 => switch (month.month) {
        1 || 2 || 12 => {16, 17, 18, 19},
        10 || 11 => {17, 18, 19, 20},
        _ => {18, 19, 20, 21},
      },
    _ => throw StateError('Rank $rank not implemented'),
  };
}

void main(List<String> args) {
  initializeTimeZones();
  ReportDriver.outDir = Directory(
      '${Platform.environment['HOME']}/Documents/repos/git/thumbert/rascal/html/docs/projects/battery_valuation/assets/isone');
  final historicalTerm = Term.parse('Dec20-Aug24', IsoNewEngland.location);

  /// get prices
  final daPrice = getHourlyLmpIsone(
      ptids: [4000],
      market: Market.da,
      component: LmpComponent.lmp,
      term: historicalTerm)[4000]!;
  final rtPrice = getHourlyLmpIsone(
      ptids: [4000],
      market: Market.rt,
      component: LmpComponent.lmp,
      term: historicalTerm)[4000]!;

  /// define 4 hour battery
  final battery = Battery(
    ecoMaxMw: 200,
    efficiencyRating: 0.875,
    totalCapacityMWh: 4 * 200,
    maxCyclesPerYear: 365,
    degradationFactor: TimeSeries<num>(),
  );

  /// set up the report
  final report = ReportDriver(
    battery: battery,
    initialState: Empty(cycleNumber: 0, cyclesInCalendarYear: 0),
    daPrices: daPrice,
    rtPrices: rtPrice,
  );

  ///
  report.run(Term.parse('Jan21-Aug24', IsoNewEngland.location));

  // oneDayAnalysis(
  //     day: Date(2024, 1, 1, location: IsoNewEngland.location), report: report);

  // oneDayAnalysis(
  //     day: Date(2024, 8, 4, location: IsoNewEngland.location), report: report);


  // priceStats(daPrice);
}










///
// var traces = <Map<String, dynamic>>[
//   {
//     'x': rt5MinPrice.intervals
//         .map((e) => e.start.toIso8601String())
//         .toList(),
//     'y': rt5MinPrice.values.toList(),
//   }
// ];
// var layout = <String, dynamic>{
//   'width': 900,
//   'height': 650,
//   'yaxis': {
//     'title': 'Hub Price, \$/MWh',
//   },
// };
// final file = File('${ReportDriver.outDir.path}/rt_lmp_5min.html');
// Plotly.now(traces, layout, file: file);
