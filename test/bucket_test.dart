library test_bucket;

import 'package:timezone/standalone.dart';
import 'package:test/test.dart';
import 'package:elec/src/time/bucket/bucket.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:date/date.dart';

List<int> countByMonth(int year, Bucket bucket) {
  var months = new TimeIterable(new Month(year,1), new Month(year, 12));
  return months.map((Month m) {
    Hour start = new Hour.beginning(new TZDateTime(Nepool.location, m.year, m.month));
    Hour end = new Hour.ending(new TZDateTime(Nepool.location, m.next.year, m.next.month));
    return new TimeIterable(start, end).where((hour) => bucket.containsHour(hour)).length;
  }).toList();
}

List<String> daysInBucket(int year, int month, Bucket bucket) {
  Month next = new Month(year, month).next;
  Hour start = new Hour.beginning(new TZDateTime(Nepool.location, year, month));
  Hour end = new Hour.ending(new TZDateTime(Nepool.location, next.year, next.month));
  Iterable<Hour> hrs = new TimeIterable(start, end);
  List days = hrs.where((hour) => bucket.containsHour(hour))
    .map((hour) => hour.currentDate.toString()).toSet().toList();

  return days;
}

//showHourBeginning(int year, int month, Bucket bucket) {
//  Month next = new Month(year, month).next;
//  TZDateTime start = new TZDateTime(Nepool.location, year, month, 1);
//  TZDateTime end = new TZDateTime(Nepool.location, next.year, next.month).subtract(new Duration(hours: 1));
//  List<DateTime> hrs = seqHours(start, end);
//  hrs.where((hour) => bucket.containsHourBeginning(hour)).forEach((hr) => print(hr));
//}



test_bucket() {

  group("Test the 5x16 bucket NEPOOL", () {
    Bucket b5x16 = Nepool.bucket5x16;
    test("peak hours by year", () {
      List res = [];
      for (int year in [2012, 2013, 2014, 2015, 2016]) {
        Hour start = new Hour.beginning(new TZDateTime(Nepool.location, year));
        Hour end = new Hour.ending(new TZDateTime(Nepool.location, year+1));
        var hrs = new TimeIterable(start, end);
        res.add(hrs.where((hour) => b5x16.containsHour(hour)).length);
      }
      expect(res, [4080, 4080, 4080, 4096, 4080]);
    });
    test("peak hours by month in 2012", () {
      expect(countByMonth(2012, Nepool.bucket5x16),
      [336, 336, 352, 336, 352, 336, 336, 368, 304, 368, 336, 320]);
    });
    test("peak hours by month in 2014", () {
      expect(countByMonth(2014, Nepool.bucket5x16),
      [352, 320, 336, 352, 336, 336, 352, 336, 336, 368, 304, 352]);
    });
    test("peak hours by month in 2015", () {
      expect(countByMonth(2015, Nepool.bucket5x16),
      [336, 320, 352, 352, 320, 352, 368, 336, 336, 352, 320, 352]);
    });
  });


  group("Test the 2x16H bucket NEPOOL", () {
    test("2x16H hours by month in 2012", () {
//      daysInBucket(2012, 1, Nepool.bucket2x16H).forEach((e) => print(e));
//      showHourBeginning(2012, 2, Nepool.bucket2x16H);
      expect(countByMonth(2012, Nepool.bucket2x16H),
      [160, 128, 144, 144, 144, 144, 160, 128, 176, 128, 144,	176]);
    });
    test("2x16H hours by month in 2013", () {
      expect(countByMonth(2013, Nepool.bucket2x16H),
      [144,	128,	160,	128,	144,	160,	144,	144,	160,	128,	160,	160]);
    });
  });


  group("Test the 7x8 bucket NEPOOL", () {
    test("7x8 hours by month in 2012", () {
      expect(countByMonth(2012, Nepool.bucket7x8),
      [248,	232,	247,	240,	248,	240,	248,	248,	240,	248,	241,	248]);
    });
    test("7x8 hours by month in 2013", () {
      expect(countByMonth(2013, Nepool.bucket7x8),
      [248,	224,	247,	240,	248,	240,	248,	248,	240,	248,	241,	248]);
    });
  });

  group("Test the Offpeak bucket NEPOOL", () {
    test("Offpeak hours by month in 2012", () {
      expect(countByMonth(2012, Nepool.bucketOffpeak),
      [408,	360,	391,	384,	392,	384,	408,	376,	416,	376,	385,	424]);
    });
    test("Offpeak hours by month in 2013", () {
      expect(countByMonth(2013, Nepool.bucketOffpeak),
      [392,	352,	407,	368,	392,	400,	392,	392,	400,	376,	401,	408]);
    });
  });


}

main() async {
  await initializeTimeZone();
  test_bucket();
}
