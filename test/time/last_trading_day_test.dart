library test.time.last_trading_day_test;

import 'package:date/date.dart';
import 'package:elec/src/time/last_trading_day.dart';
import 'package:test/test.dart';

void tests() {
  group('Last trading day tests:', () {
    test('Last business day', () {
      expect(lastBusinessDayPrior(Month.utc(2021, 1)), Date.utc(2020, 12, 31));
      expect(lastBusinessDayPrior(Month.utc(2021, 2)), Date.utc(2021, 1, 29));
      expect(lastBusinessDayPrior(Month.utc(2021, 3)), Date.utc(2021, 2, 26));
    });

    test('NG futures expiration', () {
      expect(threeBusinessDaysPrior(Month.utc(2021, 1)), Date.utc(2020, 12, 29));
      expect(threeBusinessDaysPrior(Month.utc(2021, 3)), Date.utc(2021, 2, 24));
      expect(threeBusinessDaysPrior(Month.utc(2021, 6)), Date.utc(2021, 5, 26));
      expect(threeBusinessDaysPrior(Month.utc(2021, 9)), Date.utc(2021, 8, 27));
      expect(threeBusinessDaysPrior(Month.utc(2021, 10)), Date.utc(2021, 9, 28));
      expect(threeBusinessDaysPrior(Month.utc(2021, 11)), Date.utc(2021, 10, 27));
      expect(threeBusinessDaysPrior(Month.utc(2021, 12)), Date.utc(2021, 11, 26));
    });
    test('CL futures expiration', () {
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 1)),
          Date.utc(2020, 12, 21));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 2)),
          Date.utc(2021, 1, 20));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 3)),
          Date.utc(2021, 2, 22));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 4)),
          Date.utc(2021, 3, 22));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 5)),
          Date.utc(2021, 4, 20));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 6)),
          Date.utc(2021, 5, 20));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 7)),
          Date.utc(2021, 6, 22));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 8)),
          Date.utc(2021, 7, 20));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 9)),
          Date.utc(2021, 8, 20));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 10)),
          Date.utc(2021, 9, 21));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 11)),
          Date.utc(2021, 10, 20));
      expect(fourBusinessDaysPriorTo25thPreceding(Month.utc(2021, 12)),
          Date.utc(2021, 11, 19));
    });
  });
}

void main() {
  tests();
}
