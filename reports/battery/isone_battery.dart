import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/physical/gen/battery.dart';
import 'package:elec/src/price/lib_hourly_lmp.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

TimeSeries<BidsOffers> makeBidsOffers({
  required Term term,
  required ({int min, int max}) chargeHours,
  required ({int min, int max}) dischargeHours,
  required num hourlyQuantity,
  required num maxPrice,
  required num minPrice,
}) {
  var hours = term.hours();
  var bidHours = <int>{};
  for (var i = chargeHours.min; i < chargeHours.max; i++) {
    bidHours.add(i);
  }
  var offerHours = <int>{};
  for (var i = dischargeHours.min; i < dischargeHours.max; i++) {
    offerHours.add(i);
  }
  var out = TimeSeries<BidsOffers>();
  for (var hour in hours) {
    var bids = <PriceQuantityPair>[];
    if (bidHours.contains(hour.start.hour)) {
      bids.add(PriceQuantityPair(
          maxPrice, hourlyQuantity)); // charge if price is < 500
    } else {
      bids.add(PriceQuantityPair(minPrice, hourlyQuantity));
    }
    var offers = <PriceQuantityPair>[];
    if (offerHours.contains(hour.start.hour)) {
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
  // print(getBidsOffers());

  final initialState = EmptyState(
      interval:
          Hour.beginning(TZDateTime(IsoNewEngland.location, 2023, 12, 31, 23)),
      cyclesInCalendarYear: 0);

  final daPrice = getHourlyLmpIsone(
      ptids: [4000],
      market: Market.da,
      component: LmpComponent.lmp,
      term: term)[4000]!;

  final opt = BatteryOptimization(
    battery: battery,
    daPrice: daPrice,
    rtPrice: daPrice,
    bidsOffers: makeBidsOffers(
        term: term,
        chargeHours: (min: 1, max: 4),
        dischargeHours: (min: 17, max: 20),
        hourlyQuantity: 100,
        maxPrice: 400,
        minPrice: 1),
  );
  final res = opt.dispatchDa(initialState: initialState);
}

void main(List<String> args) {}
