import 'dart:io';

import 'package:dama/basic/count.dart';
import 'package:date/date.dart';
import 'package:elec/battery.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/offer_curve.dart';
import 'package:elec/src/price/lib_hourly_lmp.dart';
import 'package:table/table_base.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';

TimeSeries<BidsOffers> makeBidsOffers({
  required Term term,
  required Set<int> chargeHours,
  required Set<int> dischargeHours,
  required num hourlyQuantity,
  required num maxPrice,
  required num minPrice,
}) {
  var hours = term.hours();
  var out = TimeSeries<BidsOffers>();
  for (var hour in hours) {
    var bids = BidCurve();
    if (chargeHours.contains(hour.start.hour)) {
      bids.add(PriceQuantityPair(
          maxPrice, hourlyQuantity)); // charge if price is < 500
    } else {
      bids.add(PriceQuantityPair(minPrice, hourlyQuantity));
    }
    var offers = OfferCurve();
    if (dischargeHours.contains(hour.start.hour)) {
      offers.add(PriceQuantityPair(
          minPrice, hourlyQuantity)); // charge if price is > 0
    } else {
      offers.add(PriceQuantityPair(maxPrice, hourlyQuantity));
    }

    out.add(IntervalTuple(hour, BidsOffers(bids: bids, offers: offers)));
  }

  return out;
}

void analyze() {
  final term = Term.parse('Jan22', IsoNewEngland.location);
  final battery = Battery(
    ecoMaxMw: 100,
    maxLoadMw: 125,
    totalCapacityMWh: 400,
    maxCyclesPerYear: 400,
  );

  final initialState = EmptyState(cycleNumber: 0, cyclesInCalendarYear: 0);

  final daPrice = getHourlyLmpIsone(
      ptids: [4000],
      market: Market.da,
      component: LmpComponent.lmp,
      term: term)[4000]!;

  final opt = BatteryOptimization(
    battery: battery,
    initialBatteryState: initialState,
    daPrice: daPrice,
    rtPrice: daPrice,
    daBidsOffers: makeBidsOffers(
        term: term,
        chargeHours: {1, 2, 3, 4},
        dischargeHours: {17, 18, 19, 20},
        hourlyQuantity: 100,
        maxPrice: 400,
        minPrice: 1),
    rtBidsOffers: makeBidsOffers(
        term: term,
        chargeHours: {1, 2, 3, 4},
        dischargeHours: {17, 18, 19, 20},
        hourlyQuantity: 100,
        maxPrice: 400,
        minPrice: 1),
  );
  opt.run();
  print(opt.dispatchDa);

  // // calcualte PnL
  // print('PnL DAM:');
  // print(opt.pnlDa);

  // print('Daily PnL:');
  // print(opt.pnlDa.toDaily(sum));
}

void makeHtmlTableBestBlocks(
    List<Term> terms, TimeSeries<num> hourlyPrices, int n) {
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

void priceStats() {
  final term = Term.parse('Dec20-Aug24', IsoNewEngland.location);
  final n = 4; // 4 hour battery
  final daPrice = getHourlyLmpIsone(
      ptids: [4000],
      market: Market.da,
      component: LmpComponent.lmp,
      term: term)[4000]!;
  // final rtPrice = getHourlyLmpIsone(
  //     ptids: [4000],
  //     market: Market.rt,
  //     component: LmpComponent.lmp,
  //     term: term)[4000]!;

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

  makeHtmlTableBestBlocks(terms, daPrice, n);

  // var hourlyStats = SummaryStats(daPrice);
  // final statsDa = hourlyStats.minMaxDailyPriceForBlock(4);
  // print(statsDa);
}

final outDir = Directory(
    '${Platform.environment['HOME']}/Documents/repos/git/thumbert/rascal/presentations/energy/battery/assets/isone');

void main(List<String> args) {
  initializeTimeZones();

  // analyze();
  priceStats();
}
