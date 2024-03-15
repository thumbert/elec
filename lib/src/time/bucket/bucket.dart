library elec.bucket;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec/time.dart';

abstract class Bucket {
  late final String name;

  /// The permissible hour beginnings for this bucket.  Used by hourly bucket
  /// weights.  Should be a sorted list.
  late final List<int> hourBeginning;

  ///Is this hour in the bucket?
  bool containsHour(Hour hour);
  @override
  String toString() => name;

  /// a cache for the number of hours in the interval for this bucket
  final Map<Interval, int> _hoursCache = {};

  static final atc = Bucket7x24();
  static final b1x16H = Bucket1x16H();
  static final b1x16HCaiso = Bucket1x16HCaiso();
  static final b2x8 = Bucket2x8();
  static final b2x16 = Bucket2x16();
  static final b2x16H = Bucket2x16H();
  static final b2x16HErcot = Bucket2x16HErcot();
  static final b5x8 = Bucket5x8();
  static final b5x16 = Bucket5x16();
  static final b5xHE1017 = Bucket5xHE1017();
  static final b5xHE1822 = Bucket5xHE1822();
  static final b5x16_7 = Bucket5x16_7();
  static final b5x16_8 = Bucket5x16_8();
  static final b5x16_9 = Bucket5x16_9();
  static final b5x16_10 = Bucket5x16_10();
  static final b5x16_11 = Bucket5x16_11();
  static final b5x16_12 = Bucket5x16_12();
  static final b5x16_13 = Bucket5x16_13();
  static final b5x16_14 = Bucket5x16_14();
  static final b5x16_15 = Bucket5x16_15();
  static final b5x16_16 = Bucket5x16_16();
  static final b5x16_17 = Bucket5x16_17();
  static final b5x16_18 = Bucket5x16_18();
  static final b5x16_19 = Bucket5x16_19();
  static final b5x16_20 = Bucket5x16_20();
  static final b5x16_21 = Bucket5x16_21();
  static final b5x16_22 = Bucket5x16_22();
  static final b6x16 = Bucket6x16();
  static final b7x8 = Bucket7x8();
  static final b7x8Caiso = Bucket7x8Caiso();
  static final b7x8Ercot = Bucket7x8Ercot();
  static final b7x16 = Bucket7x16();
  static final b7xHE1017 = Bucket7xHE1017();
  static final b7xHE1822 = Bucket7xHE1822();
  static final b7x16Ercot = Bucket7x16Ercot();
  static final peakCaiso = BucketPeakCaiso();
  static final peakErcot = BucketPeakErcot();
  static final offpeak = BucketOffpeak();
  static final offpeakAeso = BucketOffpeakAeso();
  static final offpeakCaiso = BucketOffpeakCaiso();
  static final offpeakErcot = BucketOffpeakErcot();

  static final Map<String, Bucket> buckets = {
    'ATC': Bucket.atc,
    'FLAT': Bucket.atc,
    'PEAK': Bucket.b5x16,
    'PEAK CAISO': Bucket.peakCaiso,
    'PEAK ERCOT': Bucket.peakErcot,
    'ONPEAK': Bucket.b5x16,
    'OFFPEAK': Bucket.offpeak,
    'OFFPEAK AESO': Bucket.offpeakAeso,
    'OFFPEAK CAISO': Bucket.offpeakCaiso,
    'OFFPEAK ERCOT': Bucket.offpeakErcot,
    'WRAP': Bucket.offpeak,
    '1x16H': Bucket.b1x16H,
    '1x16H CAISO': Bucket.b1x16HCaiso,
    '2X16': Bucket.b2x16,
    '2X16H': Bucket.b2x16H,
    '2X16H ERCOT': Bucket.b2x16HErcot,
    '5X8': Bucket.b5x8,
    '5X16': Bucket.b5x16,
    '5X16_7': Bucket.b5x16_7,
    '5X16_8': Bucket.b5x16_8,
    '5X16_9': Bucket.b5x16_9,
    '5X16_10': Bucket.b5x16_10,
    '5XHE10-17': Bucket.b5xHE1017,
    '5XHE18-22': Bucket.b5xHE1822,
    '5X16_11': Bucket.b5x16_11,
    '5X16_12': Bucket.b5x16_12,
    '5X16_13': Bucket.b5x16_13,
    '5X16_14': Bucket.b5x16_14,
    '5X16_15': Bucket.b5x16_15,
    '5X16_16': Bucket.b5x16_16,
    '5X16_17': Bucket.b5x16_17,
    '5X16_18': Bucket.b5x16_18,
    '5X16_19': Bucket.b5x16_19,
    '5X16_20': Bucket.b5x16_20,
    '5X16_21': Bucket.b5x16_21,
    '5X16_22': Bucket.b5x16_22,
    '6X16': Bucket.b6x16,
    '7X8': Bucket.b7x8,
    '7X8 CAISO': Bucket.b7x8Caiso,
    '7X8 ERCOT': Bucket.b7x8Ercot,
    '7X16': Bucket.b7x16,
    '7XHE10-17': Bucket.b7xHE1017,
    '7XHE18-22': Bucket.b7xHE1822,
    '7X16 ERCOT': Bucket.b7x16Ercot,
    '7X24': Bucket.atc,
  };

  /// Return a bucket from a String.  Throw if it fails.
  static Bucket parse(String bucket) {
    var out = buckets[bucket.toUpperCase()];
    if (out == null) {
      throw ArgumentError('Unknown bucket $bucket');
    }
    return out;
  }

  @override
  int get hashCode => name.hashCode;

  /// Count the number of hours in the interval
  int countHours(Interval interval) {
    if (!_hoursCache.containsKey(interval)) {
      if (!isBeginningOfHour(interval.start) ||
          !isBeginningOfHour(interval.end)) {
        throw ArgumentError(
            'Input interval $interval doesn\'t start/end at hour boundaries');
      }
      var hrs = interval.splitLeft((dt) => Hour.beginning(dt));
      var count = hrs.where((e) => containsHour(e)).length;
      // cache only if interval is long enough, don't do it for just a few days
      if (hrs.length >= 168) {
        _hoursCache[interval] = count;
      } else {
        return count;
      }
    }
    return _hoursCache[interval]!;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Bucket) return false;
    return name == other.name;
  }
}

class CustomBucket extends Bucket {
  final Bucket bucket;

  late Set<int> _hours;

  /// Define a custom bucket by starting from a bucket and adding on an hour
  /// filter, that is, retain only a list of hours.
  /// For example, to select the hours 12 to 18
  /// for all peak days of the year.
  CustomBucket(this.bucket, List<int> hourBeginning) {
    this.hourBeginning = hourBeginning;
    hourBeginning.sort();
    if (hourBeginning.first < 0 || hourBeginning.last > 23) {
      throw ArgumentError('Invalid hourBeginning $hourBeginning');
    }
    name = 'Bucket ${bucket.name} Hours:${hourBeginning.join('|')}';
    _hours = hourBeginning.toSet();
  }

  @override
  bool containsHour(Hour hour) =>
      _hours.contains(hour.start.hour) && bucket.containsHour(hour);
}

class Bucket7x24 extends Bucket {
  Bucket7x24() {
    name = '7x24';
    hourBeginning = List.generate(24, (i) => i, growable: false);
  }
  @override
  bool containsHour(Hour hour) => true;
}

class Bucket7x8 extends Bucket {
  /// Overnight hours for all days of the year
  Bucket7x8() {
    name = '7x8';
    hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];
  }
  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour <= 6 || hour.start.hour == 23) return true;
    return false;
  }
}

class Bucket7x8Caiso extends Bucket {
  /// Overnight hours for all days of the year
  Bucket7x8Caiso() {
    name = '7x8 Caiso';
    hourBeginning = [0, 1, 2, 3, 4, 5, 22, 23];
  }
  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour < 6 || hour.start.hour > 21) return true;
    return false;
  }
}

class Bucket7x8Ercot extends Bucket {
  /// Overnight hours for all days of the year
  Bucket7x8Ercot() {
    name = '7x8 Ercot';
    hourBeginning = [0, 1, 2, 3, 4, 5, 22, 23];
  }
  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour < 6 || hour.start.hour >= 22) return true;
    return false;
  }
}

class Bucket2x8 extends Bucket {
  /// Overnight hours for weekend only (no weekday holidays)
  Bucket2x8() {
    name = '2x8';
    hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek != 6 && dayOfWeek != 7) return false;
    if (hour.start.hour <= 6 || hour.start.hour == 23) return true;
    return false;
  }
}

class Bucket5x8 extends Bucket {
  /// Overnight hours for weekday only (with weekday holidays)
  Bucket5x8() {
    name = '5x8';
    hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek > 5) return false;
    if (hour.start.hour <= 6 || hour.start.hour == 23) return true;
    return false;
  }
}

class Bucket6x16 extends Bucket {
  /// Peak hours for Mon-Sat.
  Bucket6x16() {
    name = '6x16';
    hourBeginning = List.generate(16, (i) => i + 7, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour >= 7 &&
        hour.start.hour < 23 &&
        hour.currentDate.weekday != 7) return true;
    return false;
  }
}

class Bucket7x16 extends Bucket {
  /// Peak hours for all days of the week.
  Bucket7x16() {
    name = '7x16';
    hourBeginning = List.generate(16, (i) => i + 7, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour >= 7 && hour.start.hour < 23) return true;
    return false;
  }
}

// ignore: camel_case_types
class Bucket7xHE1017 extends Bucket {
  /// Solar peak hours (HE 10-15) for all days of the week.
  Bucket7xHE1017() {
    name = '7xHE10-17';
    hourBeginning = <int>[9, 10, 11, 12, 13, 14, 15, 16];
  }

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour > 8 && hour.start.hour < 17) return true;
    return false;
  }
}

// ignore: camel_case_types
class Bucket7xHE1822 extends Bucket {
  /// Evening peak hours (HE 18-22) for all days of the week.
  Bucket7xHE1822() {
    name = '7xHE18-22';
    hourBeginning = <int>[17, 18, 19, 20, 21];
  }

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour > 16 && hour.start.hour < 22) return true;
    return false;
  }
}



class Bucket7x16Ercot extends Bucket {
  /// Peak hours for all days of the week.
  Bucket7x16Ercot() {
    name = '7x16 Ercot';
    hourBeginning = List.generate(16, (i) => i + 6, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour >= 6 && hour.start.hour < 22) return true;
    return false;
  }
}

class Bucket5x16 extends Bucket {
  Bucket5x16() {
    name = '5x16';
    hourBeginning = List.generate(16, (i) => i + 7, growable: false);
  }

  final calendar = Calendar.nerc;

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    var dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour < 7 || hs.hour == 23) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
          return false;
        } else {
          return true;
        }
      }
    }
  }
}

class BucketPeakCaiso extends Bucket {
  final calendar = NercCalendar();

  /// Peak hours are defined as Monday through Saturday, excluding NERC
  /// holidays, from HE 7 to HE 22 (6:00 AM to 10:00 PM).
  /// All other hours are off-peak hours.
  BucketPeakCaiso() {
    name = 'Peak Caiso';
    hourBeginning = List.generate(16, (i) => i + 6, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    if (hs.weekday == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour < 6 || hs.hour > 21) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
          return false;
        } else {
          return true;
        }
      }
    }
  }
}

class BucketPeakErcot extends Bucket {
  final calendar = NercCalendar();

  BucketPeakErcot() {
    name = 'Peak Ercot';
    hourBeginning = List.generate(16, (i) => i + 6, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    var dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour < 6 || hs.hour >= 22) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
          return false;
        } else {
          return true;
        }
      }
    }
  }
}

class Bucket1x16H extends Bucket {
  final calendar = NercCalendar();

  Bucket1x16H() {
    name = '1x16H';
    hourBeginning = List.generate(16, (i) => i + 7, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    if (hs.hour < 7 || hs.hour > 22) return false;
    if (hs.weekday == 7) {
      return true;
    } else {
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

class Bucket1x16HCaiso extends Bucket {
  final calendar = NercCalendar();

  Bucket1x16HCaiso() {
    name = '1x16H Caiso';
    hourBeginning = List.generate(16, (i) => i + 6, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    if (hs.hour < 6 || hs.hour > 21) return false;
    if (hs.weekday == 7) {
      return true;
    } else {
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

class Bucket2x16H extends Bucket {
  final calendar = NercCalendar();

  Bucket2x16H() {
    name = '2x16H';
    hourBeginning = List.generate(16, (i) => i + 7, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    if (hs.hour < 7 || hs.hour == 23) return false;
    var dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

class Bucket2x16HErcot extends Bucket {
  final calendar = NercCalendar();

  Bucket2x16HErcot() {
    name = '2x16H Ercot';
    hourBeginning = List.generate(16, (i) => i + 6, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    if (hs.hour < 6 || hs.hour >= 22) return false;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

class Bucket2x16 extends Bucket {
  /// Peak hours, weekends only (no weekday holidays included)
  Bucket2x16() {
    name = '2x16';
    hourBeginning = List.generate(16, (i) => i + 7, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (hs.hour < 7 || hs.hour == 23) return false;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      return false;
    }
  }
}

class BucketOffpeak extends Bucket {
  final calendar = NercCalendar();

  BucketOffpeak() {
    name = 'Offpeak';
    hourBeginning = List.generate(24, (i) => i, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (hs.hour < 7 || hs.hour == 23) return true;
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) return true;
    }
    return false;
  }
}

class BucketOffpeakAeso extends Bucket {
  final calendar = NercCalendar();

  BucketOffpeakAeso() {
    name = 'Offpeak Aeso';
    hourBeginning = List.generate(24, (i) => i, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    if (hs.weekday == 7) {
      return true;
    } else {
      if (hs.hour < 7 || hs.hour > 22) return true;
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) return true;
    }
    return false;
  }
}

class BucketOffpeakCaiso extends Bucket {
  final calendar = NercCalendar();

  BucketOffpeakCaiso() {
    name = 'Offpeak Caiso';
    hourBeginning = List.generate(24, (i) => i, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 7) {
      return true;
    } else {
      if (hs.hour < 6 || hs.hour > 21) return true;
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) return true;
    }
    return false;
  }
}

class BucketOffpeakErcot extends Bucket {
  final calendar = NercCalendar();

  BucketOffpeakErcot() {
    name = 'Offpeak Ercot';
    hourBeginning = List.generate(24, (i) => i, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (hs.hour < 6 || hs.hour >= 22) return true;
      if (calendar.isHoliday3(hs.year, hs.month, hs.day)) return true;
    }
    return false;
  }
}

// ignore: camel_case_types
class Bucket5x16_7 extends Bucket {
  final calendar = NercCalendar();
  Bucket5x16_7() {
    name = '5x16_7';
    hourBeginning = <int>[7];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 7 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_8 extends Bucket {
  final calendar = Calendar.nerc;

  Bucket5x16_8() {
    name = '5x16_8';
    hourBeginning = <int>[8];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 8 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_9 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 9 bucket
  Bucket5x16_9() {
    name = '5x16_9';
    hourBeginning = <int>[9];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 9 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_10 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 10 bucket
  Bucket5x16_10() {
    name = '5x16_10';
    hourBeginning = <int>[10];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 10 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5xHE1017 extends Bucket {
  /// The 5x16 hour ending 10-17 (solar peak)
  Bucket5xHE1017() {
    name = '5xHE10-17';
    hourBeginning = <int>[9, 10, 11, 12, 13, 14, 15, 16];
  }
  final calendar = Calendar.nerc;

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour < 9 || hs.hour > 16) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
          return false;
        } else {
          return true;
        }
      }
    }
  }
}


// ignore: camel_case_types
class Bucket5xHE1822 extends Bucket {
  /// The 5x16 hour ending 10-17 (solar peak)
  Bucket5xHE1822() {
    name = '5xHE18-22';
    hourBeginning = <int>[17, 18, 19, 20, 21];
  }
  final calendar = Calendar.nerc;

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour < 17 || hs.hour > 21) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday3(hs.year, hs.month, hs.day)) {
          return false;
        } else {
          return true;
        }
      }
    }
  }
}




// ignore: camel_case_types
class Bucket5x16_11 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 11 bucket
  Bucket5x16_11() {
    name = '5x16_11';
    hourBeginning = <int>[11];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 11 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_12 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 12 bucket
  Bucket5x16_12() {
    name = '5x16_12';
    hourBeginning = <int>[12];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 12 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_13 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 13 bucket
  Bucket5x16_13() {
    name = '5x16_13';
    hourBeginning = <int>[13];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 13 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_14 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 14 bucket
  Bucket5x16_14() {
    name = '5x16_14';
    hourBeginning = <int>[14];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 14 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_15 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 15 bucket
  Bucket5x16_15() {
    name = '5x16_15';
    hourBeginning = <int>[15];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 15 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_16 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 16 bucket
  Bucket5x16_16() {
    name = '5x16_16';
    hourBeginning = <int>[16];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 16 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_17 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 17 bucket
  Bucket5x16_17() {
    name = '5x16_17';
    hourBeginning = <int>[17];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 17 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_18 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 18 bucket
  Bucket5x16_18() {
    name = '5x16_18';
    hourBeginning = <int>[18];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 18 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_19 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 19 bucket
  Bucket5x16_19() {
    name = '5x16_19';
    hourBeginning = <int>[19];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 19 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_20 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 20 bucket
  Bucket5x16_20() {
    name = '5x16_20';
    hourBeginning = <int>[20];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 20 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_21 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 21 bucket
  Bucket5x16_21() {
    name = '5x16_21';
    hourBeginning = <int>[21];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 21 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_22 extends Bucket {
  final calendar = Calendar.nerc;

  /// The 5x16 hour beginning 22 bucket
  Bucket5x16_22() {
    name = '5x16_22';
    hourBeginning = <int>[22];
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    final dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour == 22 && !calendar.isHoliday3(hs.year, hs.month, hs.day)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

