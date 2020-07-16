
import 'dart:io';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/virtual_transactions/lib_virtuals.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';


virtualTest() {
  Date day = new Date(2019, 5, 20, location: getLocation('America/New_York'));
  var hours = day.splitLeft((dt) => Hour.beginning(dt))
      .where((hour) => hour.start.hour >= 7)
      .where((hour) => hour.start.hour <= 21)
      .toList();
  var scheduleInc = TimeSeries.from(hours,
      hours.map((hour) => PriceQuantityPair(20, 75)));
  var inc = Virtual(scheduleInc, 4006, VirtualType.increment);
  var scheduleDec = TimeSeries.from(hours,
      hours.map((hour) => PriceQuantityPair(300, 75)));
  var dec = Virtual(scheduleDec, 4000, VirtualType.decrement);

  var virtuals = <Virtual>[inc, dec];
  print(toXml(virtuals));
  File('sema_hub_2019-05-20.xml').writeAsStringSync(toXml(virtuals));


}


main()  async {
  await initializeTimeZone();
  virtualTest();
}