import 'dart:io';

import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

/// Read a Csv file where first column is the date, columns 1:25 are the
/// hourly values.  The date column should be either an integer (Excel date)
/// or a string that can be parsed to a date.
///
/// Treatment of DST.  If for the spring DST date, there are 24 values instead
/// of 23, use only the first 23.  If during fall DST date, there are 24 values
/// instead of 25, repeat the second value.
///
TimeSeries<num> readHourlyWideCsv(File file, Location location) {
  return TimeSeries<num>();
}
