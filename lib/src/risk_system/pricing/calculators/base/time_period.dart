//part of elec.calculators;

library elec.risk_system.pricing.calculators.base.time_period;

import 'package:date/date.dart';

enum TimePeriod { month, day, hour }

TimePeriod getTimePeriod(Interval interval) {
  if (interval is Month) {
    return TimePeriod.month;
  } else if (interval is Date) {
    return TimePeriod.day;
  } else if (interval is Hour) {
    return TimePeriod.hour;
  } else {
    throw ArgumentError('Unknown time period for $interval');
  }
}
