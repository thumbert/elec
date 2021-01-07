library time.last_trading_day;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:tuple/tuple.dart';

var _cache = <Tuple2<String, Month>, Date>{};

/// The last business day before the beginning of the month.
/// Last trading day for the ICE daily options on ISONE .
Date lastBusinessDayPrior(Month month, {Calendar calendar}) {
  calendar ??= NercCalendar();
  var t2 = Tuple2('-1b', month);
  if (_cache.containsKey(t2)) return _cache[t2];
  var i = 0;
  var candidate = month.startDate;
  while (i < 1) {
    candidate = candidate.subtract(1);
    if (candidate.weekday < 6 && !calendar.isHoliday(candidate)) {
      i++;
    }
  }
  _cache[t2] = candidate;
  return candidate;
}

//TODO: Implement penultimate business day of the month (HO futures)

/// Three business days prior to beginning of the month.
/// Last trading day for the ICE Henry Hub Natural Gas Futures Contract.
///
/// See https://www.energygps.com/HomeTools/ExpiryCalendar
Date threeBusinessDaysPrior(Month month, {Calendar calendar}) {
  calendar ??= NercCalendar();
  var t2 = Tuple2('-3b', month);
  if (_cache.containsKey(t2)) return _cache[t2];
  var i = 0;
  var candidate = month.startDate;
  while (i < 3) {
    candidate = candidate.subtract(1);
    if (candidate.weekday < 6 && !calendar.isHoliday(candidate)) {
      i++;
    }
  }
  _cache[t2] = candidate;
  return candidate;
}

/// Last trading day for WTI futures.
/// Trading shall cease at the end of the designated settlement period on the
/// 4th US business day prior to the 25th calendar day of the month preceding
/// the contract month. If the 25th calendar day of the month is not a US
/// business day the Final Trade Day shall be the Trading Day which is the
/// fourth US business day prior to the last US business day preceding the
/// 25th calendar day of the month preceding the contract month.
///
/// See https://www.energygps.com/HomeTools/ExpiryCalendar
Date fourBusinessDaysPriorTo25thPreceding(Month month, {Calendar calendar}) {
  calendar ??= NercCalendar();
  var t2 = Tuple2('-1m+25d-4b', month);
  if (_cache.containsKey(t2)) return _cache[t2];
  var candidate = month.previous.startDate.add(24); // the 25th calendar day
  if (candidate.weekday > 5 || calendar.isHoliday(candidate)) {
    candidate = candidate.subtract(1);
  }
  if (candidate.weekday > 5 || calendar.isHoliday(candidate)) {
    candidate = candidate.subtract(1);
  }
  if (calendar.isHoliday(candidate)) {
    candidate = candidate.subtract(1);
  }
  var i = 1;
  while (i < 4) {
    candidate = candidate.subtract(1);
    if (candidate.weekday < 6 && !calendar.isHoliday(candidate)) {
      i++;
    }
  }
  _cache[t2] = candidate;
  return candidate;
}
