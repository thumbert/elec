import 'package:dama/analysis/interpolation/multi_linear_interpolator.dart';
import 'package:date/date.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';

void interpolateIcapToDailySeries() {
  final location = IsoNewEngland.location;
  var ts = TimeSeries.fromIterable([
    IntervalTuple(Date(2022, 1, 31, location: location), 924.515),
    IntervalTuple(Date(2022, 2, 28, location: location), 926.990),
    IntervalTuple(Date(2022, 3, 31, location: location), 924.582),
    IntervalTuple(Date(2022, 4, 30, location: location), 923.960),
    IntervalTuple(Date(2022, 5, 31, location: location), 920.350),
    IntervalTuple(Date(2022, 6, 1, location: location), 941.416),
    IntervalTuple(Date(2022, 6, 30, location: location), 938.518),
    IntervalTuple(Date(2022, 7, 31, location: location), 937.055),
  ]);
  var interpolator = MultiLinearInterpolator(
      ts.intervals.map((e) => (e as Date).value).toList(), ts.values.toList());
  var days = (ts.first.interval as Date).upTo(ts.last.interval as Date);

  var out = TimeSeries<num>();
  for (var day in days) {
    var value = interpolator.valueAt(day.value);
    out.add(IntervalTuple(day, value));
  }
  print(out);
}

Future<void> main() async {
  initializeTimeZones();
  interpolateIcapToDailySeries();
}
