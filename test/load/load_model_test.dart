import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/physical/load/load_model.dart';

void loadModelTests() {
  var location = getLocation('America/New_York');
  group('Load model simple tests', () {
    test('similar days', () {
      var interval = Interval(
          TZDateTime(location, 2014, 11), TZDateTime(location, 2016, 6, 1));
      var x = TimeSeries.fill(
          interval.splitLeft((dt) => Hour.beginning(dt)), {'y': 1});
      var model = LoadModel(x, dayBand: 3);
      var days = model.similarDays(Date(2016, 2, 29, location: location));
      expect(days.length, 14);
    });
  });
}

void main() async {
  await initializeTimeZones();
  loadModelTests();
}
