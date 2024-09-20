import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/physical/bid_curve.dart';
import 'package:elec/src/physical/gen/battery/battery.dart';
import 'package:elec/src/physical/gen/battery/battery_optimization.dart';
import 'package:elec/src/physical/offer_curve.dart';
import 'package:elec/src/price/lib_hourly_lmp.dart';
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
  opt.run(initialState);
  print(opt.dispatchDa);

  // // calcualte PnL
  // print('PnL DAM:');
  // print(opt.pnlDa);

  // print('Daily PnL:');
  // print(opt.pnlDa.toDaily(sum));
}

void main(List<String> args) {
  initializeTimeZones();
  analyze();
}
