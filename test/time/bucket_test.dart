library test_bucket;

import 'dart:math' show pow;
import 'package:timezone/standalone.dart';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:table/table.dart';
import '../data.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/time/bucket/bucket_utils.dart';

num round(num x, {int digits: 2}) =>
    (x * pow(10, digits)).round() / pow(10, digits);

aggregateByBucketMonth() {
  List<Bucket> buckets = [
    IsoNewEngland.bucket5x16,
    IsoNewEngland.bucket2x16H,
    IsoNewEngland.bucket7x8
  ];
  var lmp = hourlyHubPrices();

  var nest = Nest()
    ..key((e) => Month.fromTZDateTime(e['hourBeginning']))
    ..key((e) => buckets.firstWhere(
        (bucket) => bucket.containsHour(Hour.beginning(e['hourBeginning']))))
    ..rollup((Iterable x) =>
        x.map((e) => e['lmp']).reduce((a, b) => a + b) / x.length);

  var res = nest.map(lmp);
  var out = flattenMap(res, ['month', 'bucket', 'lmp']);
  test('monthly hub da price', () {
    expect(round(out[0]['lmp'], digits: 3), 18.993);
    expect(round(out[1]['lmp'], digits: 3), 26.950);
    expect(round(out[2]['lmp'], digits: 3), 34.638);
  });
}

List<int> countByMonth(int year, Bucket bucket) {
  var tzLocation = bucket.location;
  var months =
      Interval(TZDateTime(tzLocation, year), TZDateTime(tzLocation, year + 1))
          .splitLeft((dt) => Month.fromTZDateTime(dt));
  return months.map((m) {
    var hours = m.splitLeft((dt) => Hour.beginning(dt));
    return hours.where((hour) => bucket.containsHour(hour)).length;
  }).toList();
}

testBucket() {
  var location = getLocation('US/Eastern');
  group("Test buckets", () {
    test('equality for buckets', () {
      expect(Bucket2x16H(location), Bucket2x16H(location));
      expect(Bucket5x16(location), Bucket5x16(location));
      expect(Bucket7x8(location), Bucket7x8(location));
      expect(Bucket7x8(location).hashCode, Bucket7x8(location).hashCode);
    });

    var b5x16 = IsoNewEngland.bucket5x16;
    test('5x16 and Peak are the same', () {
      var onpeak = IsoNewEngland.bucketPeak;
      expect(onpeak, b5x16);
    });

    test("peak hours by year", () {
      var res = <int>[];
      for (int year in [2012, 2013, 2014, 2015, 2016]) {
        var start = TZDateTime(b5x16.location, year);
        var end = TZDateTime(b5x16.location, year + 1);
        var hrs = Interval(start, end).splitLeft((dt) => Hour.beginning(dt));
        res.add(hrs.where((hour) => b5x16.containsHour(hour)).length);
      }
      expect(res, [4080, 4080, 4080, 4096, 4080]);
    });
    test("peak hours by month in 2012", () {
      expect(countByMonth(2012, IsoNewEngland.bucket5x16),
          [336, 336, 352, 336, 352, 336, 336, 368, 304, 368, 336, 320]);
    });
    test("peak hours by month in 2014", () {
      expect(countByMonth(2014, IsoNewEngland.bucket5x16),
          [352, 320, 336, 352, 336, 336, 352, 336, 336, 368, 304, 352]);
    });
    test("peak hours by month in 2015", () {
      expect(countByMonth(2015, IsoNewEngland.bucket5x16),
          [336, 320, 352, 352, 320, 352, 368, 336, 336, 352, 320, 352]);
    });
  });

  group("Test the 2x16H bucket NEPOOL", () {
    var location = getLocation('US/Eastern');
    test("2x16H hours by month in 2012", () {
      expect(countByMonth(2012, IsoNewEngland.bucket2x16H),
          [160, 128, 144, 144, 144, 144, 160, 128, 176, 128, 144, 176]);
    });
    test("2x16H hours by month in 2013", () {
      expect(countByMonth(2013, IsoNewEngland.bucket2x16H),
          [144, 128, 160, 128, 144, 160, 144, 144, 160, 128, 160, 160]);
    });
    test('hours method', () {
      var month = Month(2013, 1, location: location);
      expect(IsoNewEngland.bucket2x16H.countHours(month), 144);
    });
  });

  group('Test the 7x16 bucket ISO New England', () {
    test('7x16 hours by month in 2012', () {
      var hours = countByMonth(2012, IsoNewEngland.bucket7x16);
      expect(
          hours, [496, 464, 496, 480, 496, 480, 496, 496, 480, 496, 480, 496]);
    });
  });

  group("Test the 7x8 bucket NEPOOL", () {
    test("7x8 hours by month in 2012", () {
      expect(countByMonth(2012, IsoNewEngland.bucket7x8),
          [248, 232, 247, 240, 248, 240, 248, 248, 240, 248, 241, 248]);
    });
    test("7x8 hours by month in 2013", () {
      expect(countByMonth(2013, IsoNewEngland.bucket7x8),
          [248, 224, 247, 240, 248, 240, 248, 248, 240, 248, 241, 248]);
    });
  });

  group("Test the 2x8 bucket NEPOOL", () {
    var bucket = Bucket2x8(location);
    test("2x8 hours in first week of Jun-2019", () {
      var interval = Interval(
          TZDateTime(location, 2019, 6, 1), TZDateTime(location, 2019, 6, 8));
      var hours = interval.splitLeft((dt) => Hour.beginning(dt));
      expect(bucket.containsHour(hours.first), true);
      var mask = hours
          .map((hour) => bucket.containsHour(hour) == true ? 1 : 0)
          .toList();
      var total = mask.reduce((a, b) => a + b);
      expect(total, 16);
    });
  });

  group("Test the Offpeak bucket NEPOOL", () {
    test("Offpeak hours by month in 2012", () {
      expect(countByMonth(2012, IsoNewEngland.bucketOffpeak),
          [408, 360, 391, 384, 392, 384, 408, 376, 416, 376, 385, 424]);
    });
    test("Offpeak hours by month in 2013", () {
      expect(countByMonth(2013, IsoNewEngland.bucketOffpeak),
          [392, 352, 407, 368, 392, 400, 392, 392, 400, 376, 401, 408]);
    });
  });

  group('Test Bucket.parse()', () {
    test('5x16, Peak', () {
      expect(Bucket.parse('5x16'), IsoNewEngland.bucket5x16);
      expect(Bucket.parse('Peak'), IsoNewEngland.bucket5x16);
    });
    test('Wrap, OffPeak', () {
      expect(Bucket.parse('Wrap'), IsoNewEngland.bucketOffpeak);
      expect(Bucket.parse('OffPeak'), IsoNewEngland.bucketOffpeak);
    });
  });

  group('Split by bucket:', () {
    var location = getLocation('US/Eastern');
    test('count hours', () {
      var month = Month(2018, 1, location: location);
      var hours = month.splitLeft((dt) => new Hour.beginning(dt));
      var ts = TimeSeries.fill(hours, 1);
      var buckets = [
        IsoNewEngland.bucket7x16,
        IsoNewEngland.bucket5x16,
        IsoNewEngland.bucket2x16H,
        IsoNewEngland.bucket7x8,
      ];
      var res = splitByBucket(ts.observations, buckets);
      var count = res.map((k, v) => MapEntry(k, v.length));
      expect(count, Map.fromIterables(buckets, [496, 352, 144, 248]));
    });
  });

  group('hours count by bucket/interval', () {
    test('calculation', () {
      var year =
          Interval(TZDateTime(location, 2013), TZDateTime(location, 2014));
      var months = year.splitLeft((dt) => Month.fromTZDateTime(dt));
      var b2x16H = IsoNewEngland.bucket2x16H;
      var count =
          months.map((month) => b2x16H.countHours(month)).toList();
      expect(
          count, [144, 128, 160, 128, 144, 160, 144, 144, 160, 128, 160, 160]);
    });
  });
}

main() async {
  await initializeTimeZone();
  testBucket();

  aggregateByBucketMonth();
}
