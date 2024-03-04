library test.time.last_trading_day_test;

import 'package:date/date.dart';
import 'package:elec/src/time/last_trading_day.dart';
import 'package:elec/time.dart';
import 'package:test/test.dart';

void tests() {
  group('Last trading day tests:', () {
    test('Last business day', () {
      expect(lastBusinessDayPrior(Month.utc(2021, 1)), Date.utc(2020, 12, 31));
      expect(lastBusinessDayPrior(Month.utc(2021, 2)), Date.utc(2021, 1, 29));
      expect(lastBusinessDayPrior(Month.utc(2021, 3)), Date.utc(2021, 2, 26));
    });

    test('NG futures expiration', () {
      expect(
          threeBusinessDaysPrior(Month.utc(2021, 1)), Date.utc(2020, 12, 29));
      expect(threeBusinessDaysPrior(Month.utc(2021, 3)), Date.utc(2021, 2, 24));
      expect(threeBusinessDaysPrior(Month.utc(2021, 6)), Date.utc(2021, 5, 26));
      expect(threeBusinessDaysPrior(Month.utc(2021, 9)), Date.utc(2021, 8, 27));
      expect(
          threeBusinessDaysPrior(Month.utc(2021, 10)), Date.utc(2021, 9, 28));
      expect(
          threeBusinessDaysPrior(Month.utc(2021, 11)), Date.utc(2021, 10, 27));
      expect(
          threeBusinessDaysPrior(Month.utc(2021, 12)), Date.utc(2021, 11, 26));
    });

    test('Monthly electricity options expiration', () {
      // should be 2024-03-28, but Fri 3/29 is Good Friday an ICE holiday
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 4)),
          Date.utc(2024, 3, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 5)),
          Date.utc(2024, 4, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 6)),
          Date.utc(2024, 5, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 7)),
          Date.utc(2024, 6, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 8)),
          Date.utc(2024, 7, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 9)),
          Date.utc(2024, 8, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 10)),
          Date.utc(2024, 9, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 11)),
          Date.utc(2024, 10, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2024, 12)),
          Date.utc(2024, 11, 26));
      // 2025
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 1)),
          Date.utc(2024, 12, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 2)),
          Date.utc(2025, 1, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 3)),
          Date.utc(2025, 2, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 4)),
          Date.utc(2025, 3, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 5)),
          Date.utc(2025, 4, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 6)),
          Date.utc(2025, 5, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 7)),
          Date.utc(2025, 6, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 8)),
          Date.utc(2025, 7, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 9)),
          Date.utc(2025, 8, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 10)),
          Date.utc(2025, 9, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 11)),
          Date.utc(2025, 10, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2025, 12)),
          Date.utc(2025, 11, 25));
      // 2026
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 1)),
          Date.utc(2025, 12, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 2)),
          Date.utc(2026, 1, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 3)),
          Date.utc(2026, 2, 26));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 4)),
          Date.utc(2026, 3, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 5)),
          Date.utc(2026, 4, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 6)),
          Date.utc(2026, 5, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 7)),
          Date.utc(2026, 6, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 8)),
          Date.utc(2026, 7, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 9)),
          Date.utc(2026, 8, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 10)),
          Date.utc(2026, 9, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 11)),
          Date.utc(2026, 10, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2026, 12)),
          Date.utc(2026, 11, 25));
      // 2027
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 1)),
          Date.utc(2026, 12, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 2)),
          Date.utc(2027, 1, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 3)),
          Date.utc(2027, 2, 25));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 4)),
          Date.utc(2027, 3, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 5)),
          Date.utc(2027, 4, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 6)),
          Date.utc(2027, 5, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 7)),
          Date.utc(2027, 6, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 8)),
          Date.utc(2027, 7, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 9)),
          Date.utc(2027, 8, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 10)),
          Date.utc(2027, 9, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 11)),
          Date.utc(2027, 10, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2027, 12)),
          Date.utc(2027, 11, 29));
      // 2028
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 1)),
          Date.utc(2027, 12, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 2)),
          Date.utc(2028, 1, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 3)),
          Date.utc(2028, 2, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 4)),
          Date.utc(2028, 3, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 5)),
          Date.utc(2028, 4, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 6)),
          Date.utc(2028, 5, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 7)),
          Date.utc(2028, 6, 29));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 8)),
          Date.utc(2028, 7, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 9)),
          Date.utc(2028, 8, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 10)),
          Date.utc(2028, 9, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 11)),
          Date.utc(2028, 10, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2028, 12)),
          Date.utc(2028, 11, 29));
      // 2029
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 1)),
          Date.utc(2028, 12, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 2)),
          Date.utc(2029, 1, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 3)),
          Date.utc(2029, 2, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 4)),
          Date.utc(2029, 3, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 5)),
          Date.utc(2029, 4, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 6)),
          Date.utc(2029, 5, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 7)),
          Date.utc(2029, 6, 28));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 8)),
          Date.utc(2029, 7, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 9)),
          Date.utc(2029, 8, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 10)),
          Date.utc(2029, 9, 27));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 11)),
          Date.utc(2029, 10, 30));
      expect(lastTradingDayForMonthlyElecOptions(Month.utc(2029, 12)),
          Date.utc(2029, 11, 29));
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
  // print(lastBusinessDayPrior(Month.utc(2023, 1)));
  // print('here');
}
