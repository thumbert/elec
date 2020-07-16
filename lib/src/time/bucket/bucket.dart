library elec.bucket;

import 'package:date/date.dart';
import 'package:quiver/core.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec/src/iso/iso.dart';

abstract class Bucket {
  String get name;

  /// The permissible hour beginnings for this bucket.  Used by hourly bucket
  /// weights.  Should be a sorted list.
  List<int> hourBeginning;

  ///Is this hour in the bucket?
  bool containsHour(Hour hour);
  @override
  String toString() => name;

  /// a cache for the number of hours in the interval for this bucket
  Map<Interval, int> _hoursCache;

  static final atc = Bucket7x24();
  static final b2x8 = Bucket2x8();
  static final b2x16 = Bucket2x16();
  static final b2x16H = Bucket2x16H();
  static final b5x8 = Bucket5x8();
  static final b5x16 = Bucket5x16();
  static final b7x8 = Bucket7x8();
  static final b7x16 = Bucket7x16();
  static final offpeak = BucketOffpeak();

  /// Return a bucket from a String, for now, from IsoNewEngland only.
  static Bucket parse(String bucket) {
    bucket = bucket.toUpperCase();
    Bucket out;
    if (['PEAK', 'ONPEAK', '5X16'].contains(bucket)) {
      out = IsoNewEngland.bucket5x16;
    } else if (['OFFPEAK', 'WRAP'].contains(bucket)) {
      out = IsoNewEngland.bucketOffpeak;
    } else if (['FLAT', '7X24', 'ATC'].contains(bucket)) {
      out = IsoNewEngland.bucket7x24;
    } else if (bucket == '2X16H') {
      out = IsoNewEngland.bucket2x16H;
    } else if (bucket == '7X8') {
      out = IsoNewEngland.bucket7x8;
    } else if (bucket == '7X16') {
      out = IsoNewEngland.bucket7x16;
    } else if (bucket == '2X8') {
      out = IsoNewEngland.bucket2x8;
    } else if (bucket == '2X16') {
      out = IsoNewEngland.bucket2x16;
    } else {
      throw ArgumentError('Unknown bucket $bucket');
    }
    return out;
  }

  @override
  int get hashCode => name.hashCode;

  /// Count the number of hours in the interval
  int countHours(Interval interval) {
    _hoursCache ??= <Interval, int>{};
    if (!_hoursCache.containsKey(interval)) {
      if (!isBeginningOfHour(interval.start) ||
          !isBeginningOfHour(interval.end)) {
        throw ArgumentError(
            'Input interval $interval doesn\'t start/end at hour boundaries');
      }
      var hrs = interval.splitLeft((dt) => Hour.beginning(dt));
      _hoursCache[interval] = hrs.where((e) => containsHour(e)).length;
    }
    return _hoursCache[interval];
  }
}

class CustomBucket extends Bucket {
  @override
  String name;
  final Bucket bucket;
  @override
  final List<int> hourBeginning;

  Set<int> _hours;

  /// Define a custom bucket by starting from a bucket and adding on an hour
  /// filter, that is, retain only a list of hours.
  /// For example, to select the hours 12 to 18
  /// for all peak days of the year.
  CustomBucket.withHours(this.bucket, this.hourBeginning) {
    hourBeginning.sort();
    if (hourBeginning.first < 0 || hourBeginning.last > 23) {
      throw ArgumentError('Invalid hourBeginning $hourBeginning');
    }
    name =
        'Bucket ${bucket.name} Hours:${hourBeginning.join('|')}';
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
    var dayOfWeek = hour.currentDate.weekday;
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
    var dayOfWeek = hour.currentDate.weekday;
    if (hour.start.hour < 7 || hour.start.hour == 23) return false;
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
