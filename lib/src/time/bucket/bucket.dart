library elec.bucket;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';

abstract class Bucket {
  String get name;

  /// The permissible hour beginnings for this bucket.  Used by hourly bucket
  /// weights.  Should be a sorted list.
  late List<int> hourBeginning;

  ///Is this hour in the bucket?
  bool containsHour(Hour hour);
  @override
  String toString() => name;

  /// a cache for the number of hours in the interval for this bucket
  Map<Interval, int> _hoursCache = {};

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
  static final offpeak = BucketOffpeak();

  static final Map<String,Bucket> buckets = {
    'ATC' : Bucket.atc,
    'PEAK' : Bucket.b5x16,
    'ONPEAK' : Bucket.b5x16,
    'OFFPEAK' : Bucket.offpeak,
    '2X16' : Bucket.b2x16,
    '2X16H' : Bucket.b2x16H,
    '5X8' : Bucket.b5x8,
    '5X16' : Bucket.b5x16,
    '5X16_7' : Bucket.b5x16_7,
    '5X16_8' : Bucket.b5x16_8,
    '5X16_9' : Bucket.b5x16_9,
    '5X16_10' : Bucket.b5x16_10,
    '5X16_11' : Bucket.b5x16_11,
    '5X16_12' : Bucket.b5x16_12,
    '5X16_13' : Bucket.b5x16_13,
    '5X16_14' : Bucket.b5x16_14,
    '5X16_15' : Bucket.b5x16_15,
    '5X16_16' : Bucket.b5x16_16,
    '5X16_17' : Bucket.b5x16_17,
    '5X16_18' : Bucket.b5x16_18,
    '5X16_19' : Bucket.b5x16_19,
    '5X16_20' : Bucket.b5x16_20,
    '5X16_21' : Bucket.b5x16_21,
    '5X16_22' : Bucket.b5x16_22,
    'WRAP' : Bucket.offpeak,
    'FLAT' : Bucket.atc,
    '6X16' : Bucket.b6x16,
    '7X8' : Bucket.b7x8,
    '7X16' : Bucket.b7x16,
    '7X24' : Bucket.atc,
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
    //_hoursCache ??= <Interval, int>{};
    if (!_hoursCache.containsKey(interval)) {
      if (!isBeginningOfHour(interval.start) ||
          !isBeginningOfHour(interval.end)) {
        throw ArgumentError(
            'Input interval $interval doesn\'t start/end at hour boundaries');
      }
      var hrs = interval.splitLeft((dt) => Hour.beginning(dt));
      _hoursCache[interval] = hrs.where((e) => containsHour(e)).length;
    }
    return _hoursCache[interval]!;
  }
}

class CustomBucket extends Bucket {
  @override
  late String name;
  final Bucket bucket;
  @override
  final List<int> hourBeginning;

  late Set<int> _hours;

  /// Define a custom bucket by starting from a bucket and adding on an hour
  /// filter, that is, retain only a list of hours.
  /// For example, to select the hours 12 to 18
  /// for all peak days of the year.
  CustomBucket.withHours(this.bucket, this.hourBeginning) {
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
  @override
  final String name = '7x24';
  @override
  final List<int> hourBeginning = List.generate(24, (i) => i, growable: false);

  Bucket7x24();

  @override
  bool containsHour(Hour hour) => true;

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket7x24) return false;
    return true;
  }
}

class Bucket7x8 extends Bucket {
  @override
  final String name = '7x8';
  @override
  final List<int> hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];

  /// Overnight hours for all days of the year
  Bucket7x8();

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour <= 6 || hour.start.hour == 23) return true;
    return false;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket7x8) return false;
    return true;
  }
}

class Bucket2x8 extends Bucket {
  @override
  final String name = '2x8';
  @override
  final List<int> hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];

  /// Overnight hours for weekend only (no weekday holidays)
  Bucket2x8();

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek != 6 && dayOfWeek != 7) return false;
    if (hour.start.hour <= 6 || hour.start.hour == 23) return true;
    return false;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket2x8) return false;
    return true;
  }
}

class Bucket5x8 extends Bucket {
  @override
  final String name = '5x8';
  @override
  final List<int> hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];

  /// Overnight hours for weekday only (with weekday holidays)
  Bucket5x8();

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.currentDate.weekday;
    if (dayOfWeek > 5) return false;
    if (hour.start.hour <= 6 || hour.start.hour == 23) return true;
    return false;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket2x8) return false;
    return true;
  }
}

class Bucket6x16 extends Bucket {
  @override
  final String name = '6x16';
  @override
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  /// Peak hours for Mon-Sat.
  Bucket6x16();

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour >= 7 && hour.start.hour < 23 && hour.currentDate.weekday != 7) return true;
    return false;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket6x16) return false;
    return true;
  }
}

class Bucket7x16 extends Bucket {
  @override
  final String name = '7x16';
  @override
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  /// Peak hours for all days of the week.
  Bucket7x16();

  @override
  bool containsHour(Hour hour) {
    if (hour.start.hour >= 7 && hour.start.hour < 23) return true;
    return false;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket7x16) return false;
    return true;
  }
}

class Bucket5x16 extends Bucket {
  @override
  final String name = '5x16';
  final calendar = NercCalendar();
  @override
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  Bucket5x16();

  @override
  bool containsHour(Hour hour) {
    var dayOfWeek = hour.start.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      /// not the right day of the week
      return false;
    } else {
      if (hour.start.hour < 7 || hour.start.hour == 23) {
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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16) return false;
    return true;
  }
}

class Bucket5x16_7 extends Bucket {
  @override
  final String name = '5x16_7';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[7];

  Bucket5x16_7();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_7) return false;
    return true;
  }
}

class Bucket5x16_8 extends Bucket {
  @override
  final String name = '5x16_8';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[8];

  Bucket5x16_8();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_8) return false;
    return true;
  }
}

class Bucket5x16_9 extends Bucket {
  @override
  final String name = '5x16_9';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[9];

  /// The 5x16 hour beginning 9 bucket
  Bucket5x16_9();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_9) return false;
    return true;
  }
}

class Bucket5x16_10 extends Bucket {
  @override
  final String name = '5x16_10';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[10];

  /// The 5x16 hour beginning 10 bucket
  Bucket5x16_10();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_10) return false;
    return true;
  }
}

class Bucket5x16_11 extends Bucket {
  @override
  final String name = '5x16_11';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[11];

  /// The 5x16 hour beginning 11 bucket
  Bucket5x16_11();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_11) return false;
    return true;
  }
}

class Bucket5x16_12 extends Bucket {
  @override
  final String name = '5x16_12';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[12];

  /// The 5x16 hour beginning 12 bucket
  Bucket5x16_12();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_12) return false;
    return true;
  }
}

class Bucket5x16_13 extends Bucket {
  @override
  final String name = '5x16_13';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[13];

  /// The 5x16 hour beginning 13 bucket
  Bucket5x16_13();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_13) return false;
    return true;
  }
}

class Bucket5x16_14 extends Bucket {
  @override
  final String name = '5x16_14';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[14];

  /// The 5x16 hour beginning 14 bucket
  Bucket5x16_14();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_14) return false;
    return true;
  }
}

class Bucket5x16_15 extends Bucket {
  @override
  final String name = '5x16_15';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[15];

  /// The 5x16 hour beginning 15 bucket
  Bucket5x16_15();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_15) return false;
    return true;
  }
}

class Bucket5x16_16 extends Bucket {
  @override
  final String name = '5x16_16';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[16];

  /// The 5x16 hour beginning 16 bucket
  Bucket5x16_16();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_16) return false;
    return true;
  }
}

class Bucket5x16_17 extends Bucket {
  @override
  final String name = '5x16_17';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[17];

  /// The 5x16 hour beginning 17 bucket
  Bucket5x16_17();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_17) return false;
    return true;
  }
}

class Bucket5x16_18 extends Bucket {
  @override
  final String name = '5x16_18';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[18];

  /// The 5x16 hour beginning 18 bucket
  Bucket5x16_18();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_18) return false;
    return true;
  }
}

class Bucket5x16_19 extends Bucket {
  @override
  final String name = '5x16_19';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[19];

  /// The 5x16 hour beginning 19 bucket
  Bucket5x16_19();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_19) return false;
    return true;
  }
}

class Bucket5x16_20 extends Bucket {
  @override
  final String name = '5x16_20';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[20];

  /// The 5x16 hour beginning 20 bucket
  Bucket5x16_20();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_20) return false;
    return true;
  }
}

class Bucket5x16_21 extends Bucket {
  @override
  final String name = '5x16_21';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[21];

  /// The 5x16 hour beginning 21 bucket
  Bucket5x16_21();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_21) return false;
    return true;
  }
}

class Bucket5x16_22 extends Bucket {
  @override
  final String name = '5x16_22';
  final calendar = NercCalendar();
  @override
  final hourBeginning = <int>[22];

  /// The 5x16 hour beginning 22 bucket
  Bucket5x16_22();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket5x16_22) return false;
    return true;
  }
}

class Bucket2x16H extends Bucket {
  @override
  final String name = '2x16H';
  final calendar = NercCalendar();
  @override
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  Bucket2x16H();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket2x16H) return false;
    return true;
  }
}

class Bucket2x16 extends Bucket {
  @override
  final String name = '2x16';
  @override
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  /// Peak hours, weekends only (no weekday holidays included)
  Bucket2x16();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! Bucket2x16) return false;
    return true;
  }
}

class BucketOffpeak extends Bucket {
  @override
  final String name = 'Offpeak';
  final calendar = NercCalendar();
  @override
  final List<int> hourBeginning = List.generate(24, (i) => i, growable: false);

  BucketOffpeak();

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

  @override
  bool operator ==(dynamic other) {
    if (other is! BucketOffpeak) return false;
    return true;
  }
}
