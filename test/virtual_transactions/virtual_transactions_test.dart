
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/virtual_transactions/lib_virtuals.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';


virtualTest() {
  Date day = new Date(2018, 8, 23, location: getLocation('US/Eastern'));
  var hours = day.splitLeft((dt) => new Hour.beginning(dt))
      .where((hour) => hour.start.hour >= 12)
      .where((hour) => hour.start.hour <= 21)
      .toList();
  var scheduleInc = new TimeSeries.from(hours,
      hours.map((hour) => PriceQuantityPair(30, 75)));
  var inc = new Virtual(scheduleInc, 4006, VirtualType.increment);
  var scheduleDec = new TimeSeries.from(hours,
      hours.map((hour) => PriceQuantityPair(300, 75)));
  var dec = new Virtual(scheduleDec, 4000, VirtualType.decrement);

  var virtuals = <Virtual>[inc, dec];
  print(toXml(virtuals));


}


main()  async {
  await initializeTimeZone();
  virtualTest();
}