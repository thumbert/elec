library time.last_trading_day;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/calendars/ice_us_energy_calendar.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:tuple/tuple.dart';

final _cache = <Tuple2<String, Month>, Date>{};

/// The last business day before the beginning of the month.
/// Last trading day for the ICE daily options on ISONE,
/// NY Harbor USLD contract, etc.
///
Date lastBusinessDayBefore(Date date, {Calendar? calendar}) {
  calendar ??= Calendar.nerc;
  var i = 0;
  var candidate = date;
  while (i < 1) {
    candidate = candidate.subtract(1);
    if (candidate.weekday < 6 && !calendar.isHoliday(candidate)) {
      i++;
    }
  }
  return candidate;
}

@Deprecated('Use lastBusinessDayBefore')
Date lastBusinessDayPrior(Date date, {Calendar? calendar}) =>
    lastBusinessDayBefore(date, calendar: calendar);

const _exceptionsOptionsExp = <(int, int), (int, int, int)>{
  (2024, 12): (2024, 11, 26),
  (2025, 12): (2025, 11, 25),
  (2026, 12): (2026, 11, 25),
  (2027, 6): (2027, 5, 27),
};

/// Monthly electricity options expire at At 2:30pm EPT on the second
/// Business Day prior to the first calendar day of the Contract Period.
/// Use this function to calculate the last trading date.
///
/// See https://www.ice.com/products/6590526/Option-on-PJM-Western-Hub-Real-Time-Peak-1-MW-Fixed-Price-Future/expiry
Date lastTradingDayForMonthlyElecOptions(Month month) {
  if (_exceptionsOptionsExp.containsKey((month.year, month.month))) {
    final (y, m, d) = _exceptionsOptionsExp[(month.year, month.month)]!;
    return Date(y, m, d, location: month.location);
  } else {
    return twoBusinessDaysPrior(month);
  }
}

const _exceptionsCal1xExp = <int, (int, int, int)>{
  2028: (2027, 12, 23),
};

/// An Option on a basket of yearly Contract Periods, January-December,
/// of the Underlying Future Contract. For purposes of this Exchange Option,
/// the term “One Time Option” shall mean that the Option will exercise into
/// each of the Contract Periods of the Underlying Futures Contract in the
/// basket using a single reference price, as defined in Reference Price A
///
/// Expiration is at 2:30pm EPT on the second Friday prior to the first calendar
/// day of the first Contract Period in the basket.
///
/// See https://www.ice.com/products/64286936/Option-on-PJM-Western-Hub-Real-Time-Peak-Calendar-Year-One-Time-Fixed-Price-Future/expiry
///
Date lastTradingDayForCalendar1xOptions(Month month) {
  assert(month.month == 1);
  if (_exceptionsCal1xExp.containsKey(month.year)) {
    final (y, m, d) = _exceptionsCal1xExp[month.year]!;
    return Date(y, m, d, location: month.location);
  }
  var i = 0;
  var candidate = month.startDate;
  while (i < 2) {
    candidate = candidate.subtract(1);
    if (candidate.weekday == 5) {
      i++;
    }
  }
  return candidate;
}

Date twoBusinessDaysPrior(Month month, {Calendar? calendar}) {
  calendar ??= IceUsEnergyHolidaysCalendar();
  var i = 0;
  var candidate = month.startDate;
  while (i < 2) {
    candidate = candidate.subtract(1);
    if (candidate.weekday < 6 && !calendar.isHoliday(candidate)) {
      i++;
    }
  }
  return candidate;
}

/// Three business days prior to beginning of the month.
/// Last trading day for the ICE Henry Hub Natural Gas Futures Contract.
///
/// See https://www.energygps.com/HomeTools/ExpiryCalendar
Date threeBusinessDaysPrior(Month month, {Calendar? calendar}) {
  calendar ??= NercCalendar();
  var t2 = Tuple2('-3b', month);
  if (_cache.containsKey(t2)) return _cache[t2]!;
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
Date fourBusinessDaysPriorTo25thPreceding(Month month, {Calendar? calendar}) {
  calendar ??= NercCalendar();
  var t2 = Tuple2('-1m+25d-4b', month);
  if (_cache.containsKey(t2)) return _cache[t2]!;
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
