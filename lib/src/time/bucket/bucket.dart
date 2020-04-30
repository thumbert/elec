library elec.bucket;

import 'package:date/date.dart';
import 'package:quiver/core.dart';
import 'package:timezone/timezone.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec/src/iso/iso.dart';

abstract class Bucket {
  Calendar calendar;
  String get name;
  Location location;

  /// The permissible hour beginnings for this bucket.  Used by hourly bucket
  /// weights.  Should be a sorted list.
  List<int> hourBeginning;

  ///Is this hour in the bucket?
  bool containsHour(Hour hour);
  @override
  String toString() => name;

  /// a cache for the number of hours in the interval for this bucket
  Map<Interval, int> _hoursCache;

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
  int get hashCode => hash2(name, location);

  /// Count the number of hours in the interval
  int countHours(Interval interval) {
    if (!_hoursCache.containsKey(interval)) {
      if (!isBeginningOfHour(interval.start) ||
          !isBeginningOfHour(interval.end)) {
        throw ArgumentError(
            'Input interval $interval doesn\'t start/end at hour boundaries');
      }

      var hrs = interval.splitLeft((dt) => Hour.beginning(dt)).cast<Hour>();
      _hoursCache[interval] = hrs.where((e) => containsHour(e)).length;
    }
    return _hoursCache[interval];
  }
}

class CustomBucket extends Bucket {
  String name;
  final Location location;
  final Bucket bucket;
  final List<int> hourBeginning;

  Set<int> _hours;

  /// Define a custom bucket by starting from a bucket and adding on an hour
  /// filter, that is, retain only a list of hours.
  /// For example, to select the hours 12 to 18
  /// for all peak days of the year.
  CustomBucket.withHours(this.location, this.bucket, this.hourBeginning) {
    hourBeginning.sort();
    if (hourBeginning.first < 0 || hourBeginning.last > 23) {
      throw ArgumentError('Invalid hourBeginning $hourBeginning');
    }
    name =
        'Bucket ${bucket.name} Hours:${hourBeginning.join('|')}_${location.name}';
    _hours = hourBeginning.toSet();
  }

  bool containsHour(Hour hour) =>
      _hours.contains(hour.start.hour) && bucket.containsHour(hour);
}

class Bucket7x24 extends Bucket {
  final String name = '7x24';
  Location location;
  final List<int> hourBeginning = List.generate(24, (i) => i, growable: false);

  var _hoursCache = <Month, int>{};

  Bucket7x24(this.location);

  bool containsHour(Hour hour) => true;

  bool operator ==(dynamic other) {
    if (other is! Bucket7x24) return false;
    Bucket7x24 bucket = other;
    return name == bucket.name && location == bucket.location;
  }
}

class Bucket7x8 extends Bucket {
  @override
  final String name = '7x8';
  @override
  Location location;
  @override
  final List<int> hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];

  var _hoursCache = <Month, int>{};

  /// Overnight hours for all days of the year
  Bucket7x8(this.location);

  bool containsHour(Hour hour) {
    if (hour.start.hour <= 6 || hour.start.hour == 23) return true;
    return false;
  }

  bool operator ==(dynamic other) {
    if (other is! Bucket7x8) return false;
    Bucket7x8 bucket7x8 = other;
    return name == bucket7x8.name && location == bucket7x8.location;
  }
}

class Bucket2x8 extends Bucket {
  final String name = '2x8';
  Location location;
  final List<int> hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];

  var _hoursCache = <Month, int>{};

  /// Overnight hours for weekend only (no weekday holidays)
  Bucket2x8(this.location);

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
    Bucket2x8 bucket2x8 = other;
    return name == bucket2x8.name && location == bucket2x8.location;
  }
}

class Bucket5x8 extends Bucket {
  final String name = '5x8';
  Location location;
  final List<int> hourBeginning = [0, 1, 2, 3, 4, 5, 6, 23];

  var _hoursCache = <Month, int>{};

  /// Overnight hours for weekday only (with weekday holidays)
  Bucket5x8(this.location);

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
    Bucket2x8 bucket2x8 = other;
    return name == bucket2x8.name && location == bucket2x8.location;
  }
}

class Bucket7x16 extends Bucket {
  @override
  final String name = '7x16';
  @override
  Location location;
  @override
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  var _hoursCache = <Month, int>{};

  /// Peak hours for all days of the week.
  Bucket7x16(this.location);

  bool containsHour(Hour hour) {
    if (hour.start.hour >= 7 && hour.start.hour < 23) return true;
    return false;
  }

  bool operator ==(dynamic other) {
    if (other is! Bucket7x16) return false;
    Bucket7x16 bucket = other;
    return name == bucket.name && location == bucket.location;
  }
}

class Bucket5x16 extends Bucket {
  final String name = '5x16';
  Location location;
  var calendar = NercCalendar();
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  var _hoursCache = <Month, int>{};

  Bucket5x16(this.location);

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
    Bucket5x16 bucket = other;
    return name == bucket.name && location == bucket.location;
  }
}

class Bucket2x16H extends Bucket {
  final String name = '2x16H';
  Location location;
  var calendar = NercCalendar();
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);

  var _hoursCache = <Month, int>{};

  Bucket2x16H(this.location);

  bool containsHour(Hour hour) {
    int dayOfWeek = hour.currentDate.weekday;
    if (hour.start.hour < 7 || hour.start.hour == 23) return false;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (calendar.isHoliday(hour.currentDate))
        return true;
      else
        return false;
    }
  }

  bool operator ==(dynamic other) {
    if (other is! Bucket2x16H) return false;
    Bucket2x16H bucket = other;
    return name == bucket.name && location == bucket.location;
  }
}

class Bucket2x16 extends Bucket {
  final String name = '2x16';
  Location location;
  Calendar calendar;
  final List<int> hourBeginning =
      List.generate(16, (i) => i + 7, growable: false);
  var _hoursCache = <Month, int>{};

  /// Peak hours, weekends only (no weekday holidays included)
  Bucket2x16(this.location);

  bool containsHour(Hour hour) {
    int dayOfWeek = hour.currentDate.weekday;
    if (hour.start.hour < 7 || hour.start.hour == 23) return false;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      return false;
    }
  }
}

class BucketOffpeak extends Bucket {
  final String name = 'Offpeak';
  Location location;
  Calendar calendar = NercCalendar();
  final List<int> hourBeginning = List.generate(24, (i) => i, growable: false);

  var _hoursCache = <Month, int>{};

  BucketOffpeak(Location this.location);

  bool containsHour(Hour hour) {
    int dayOfWeek = hour.start.weekday;
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return true;
    } else {
      if (hour.start.hour < 7 || hour.start.hour == 23) return true;
      if (calendar.isHoliday(hour.currentDate)) return true;
    }
    return false;
  }
}
