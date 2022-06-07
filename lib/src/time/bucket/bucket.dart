library elec.bucket;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';

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
  static final b2x8 = Bucket2x8();
  static final b2x16 = Bucket2x16();
  static final b2x16H = Bucket2x16H();
  static final b5x8 = Bucket5x8();
  static final b5x16 = Bucket5x16();
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
  static final b7x16 = Bucket7x16();
  static final caisoPeak = BucketCaisoPeak();
  static final offpeak = BucketOffpeak();

  static final Map<String, Bucket> buckets = {
    'ATC': Bucket.atc,
    'PEAK': Bucket.b5x16,
    'CAISO PEAK': Bucket.caisoPeak,
    'ONPEAK': Bucket.b5x16,
    'OFFPEAK': Bucket.offpeak,
    '2X16': Bucket.b2x16,
    '2X16H': Bucket.b2x16H,
    '5X8': Bucket.b5x8,
    '5X16': Bucket.b5x16,
    '5X16_7': Bucket.b5x16_7,
    '5X16_8': Bucket.b5x16_8,
    '5X16_9': Bucket.b5x16_9,
    '5X16_10': Bucket.b5x16_10,
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
    'WRAP': Bucket.offpeak,
    'FLAT': Bucket.atc,
    '6X16': Bucket.b6x16,
    '7X8': Bucket.b7x8,
    '7X16': Bucket.b7x16,
    '7X24': Bucket.atc,
  };

  /// Return a bucket from a String, for now, from IsoNewEngland only.
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

class Bucket5x16 extends Bucket {
  final calendar = NercCalendar();

  Bucket5x16() {
    name = '5x16';
    hourBeginning = List.generate(16, (i) => i + 7, growable: false);
  }

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
        if (calendar.isHoliday(hour.currentDate)) {
          return false;
        } else {
          return true;
        }
      }
    }
  }
}

class BucketCaisoPeak extends Bucket {
  final calendar = NercCalendar();

  BucketCaisoPeak() {
    name = 'Caiso Peak';
    hourBeginning = List.generate(17, (i) => i + 6, growable: false);
  }

  @override
  bool containsHour(Hour hour) {
    final hs = hour.start;
    var dayOfWeek = hs.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hs.hour < 6 || hs.hour == 23) {
        /// not at the right hour of the day
        return false;
      } else {
        if (calendar.isHoliday(hour.currentDate)) {
          return false;
        } else {
          return true;
        }
      }
    }
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
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 7 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_8 extends Bucket {
  final calendar = NercCalendar();

  Bucket5x16_8() {
    name = '5x16_8';
    hourBeginning = <int>[8];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 8 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_9 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 9 bucket
  Bucket5x16_9() {
    name = '5x16_9';
    hourBeginning = <int>[9];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 9 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_10 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 10 bucket
  Bucket5x16_10() {
    name = '5x16_10';
    hourBeginning = <int>[10];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 10 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_11 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 11 bucket
  Bucket5x16_11() {
    name = '5x16_11';
    hourBeginning = <int>[11];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 11 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_12 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 12 bucket
  Bucket5x16_12() {
    name = '5x16_12';
    hourBeginning = <int>[12];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 12 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_13 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 13 bucket
  Bucket5x16_13() {
    name = '5x16_13';
    hourBeginning = <int>[13];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 13 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_14 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 14 bucket
  Bucket5x16_14() {
    name = '5x16_14';
    hourBeginning = <int>[14];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 14 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_15 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 15 bucket
  Bucket5x16_15() {
    name = '5x16_15';
    hourBeginning = <int>[15];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 15 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_16 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 16 bucket
  Bucket5x16_16() {
    name = '5x16_16';
    hourBeginning = <int>[16];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 16 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_17 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 17 bucket
  Bucket5x16_17() {
    name = '5x16_17';
    hourBeginning = <int>[17];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 17 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_18 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 18 bucket
  Bucket5x16_18() {
    name = '5x16_18';
    hourBeginning = <int>[18];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 18 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_19 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 19 bucket
  Bucket5x16_19() {
    name = '5x16_19';
    hourBeginning = <int>[19];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 19 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_20 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 20 bucket
  Bucket5x16_20() {
    name = '5x16_20';
    hourBeginning = <int>[20];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 20 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_21 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 21 bucket
  Bucket5x16_21() {
    name = '5x16_21';
    hourBeginning = <int>[21];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 21 && !calendar.isHoliday(hour.currentDate)) {
        return true;
      } else {
        return false;
      }
    }
  }
}

// ignore: camel_case_types
class Bucket5x16_22 extends Bucket {
  final calendar = NercCalendar();

  /// The 5x16 hour beginning 22 bucket
  Bucket5x16_22() {
    name = '5x16_22';
    hourBeginning = <int>[22];
  }

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour == 22 && !calendar.isHoliday(hour.currentDate)) {
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
    if (hour.start.hour < 7 || hour.start.hour == 23) return false;
    var dayOfWeek = hour.start.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (calendar.isHoliday(hour.currentDate)) {
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
    var dayOfWeek = hour.currentDate.weekday;
    if (hour.start.hour < 7 || hour.start.hour == 23) return false;
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
    var dayOfWeek = hour.start.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (hour.start.hour < 7 || hour.start.hour == 23) return true;
      if (calendar.isHoliday(hour.currentDate)) return true;
    }
    return false;
  }
}
