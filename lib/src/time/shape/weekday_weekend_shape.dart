library time.shape.weekday_weekend_shape;

import 'package:collection/collection.dart';
import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec/time.dart';
import 'package:timeseries/timeseries.dart';

/// Input [xs] is a daily timeseries.
///
List<Map<String,dynamic>> weekdayWeekendShapeByMonth(Iterable<IntervalTuple<num>> xs,
    {Calendar? calendar}) {
  calendar ??= Calendar.nerc;

  var groups = groupBy(xs, (e) => Month.containing(e.interval.start));
  var mData = <Map<String, dynamic>>[];
  for (var month in groups.keys) {
    var ts = groups[month]!.groupListsBy((e) {
      var date = e.interval as Date;
      return date.isWeekend() || calendar!.isHoliday(date);
    });
    var weekdayValue = mean(ts[false]!.map((e) => e.value));
    var weekendValue = mean(ts[true]!.map((e) => e.value));

    mData.add({
      'month': month,
      'ratio': weekdayValue / weekendValue,
    });
  }


  return mData;
}