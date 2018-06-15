
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec/src/load/load_model.dart';


loadModelTests() {
  Location location = getLocation('US/Eastern');
  group('Load model simple tests', () {
    test('similar days', (){
      Interval interval = new Interval(
          new TZDateTime(location, 2014,11), new TZDateTime(location, 2016, 6, 1));
      TimeSeries x = new TimeSeries.fill(
          interval.splitLeft((dt) => new Hour.beginning(dt)), {'y': 1});
      LoadModel model = new LoadModel(x, dayBand: 3);
      var days = model.similarDays(new Date(2016, 2, 29, location: location));
      expect(days.length, 14);
    });
  });
}

main() {
  /// line below crashes all_tests if not removed.
  initializeTimeZoneSync(getLocationTzdb());
  loadModelTests();
}
