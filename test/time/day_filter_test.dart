library test.time.day_filter_test;

import 'package:date/date.dart';
import 'package:elec/src/time/day_filter.dart';
import 'package:elec/time.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Day filter tests:', () {
    test('empty', () {
      final filter = DayFilter.empty();
      final term = Term.parse('Cal24', UTC);
      final res = filter.getDays(term);
      expect(res.length, 366);
    });
    test('with year, month, day', () {
      final filter = DayFilter.empty()
          .copyWith(years: {2023, 2024}, months: {1, 12}, days: {10, 12});
      final term = Term.parse('1Jan22-31Dec24', UTC);
      expect(filter.hasDay(Date.utc(2023, 1, 10)), true);
      final res = filter.getDays(term);
      expect(res.length, 8);
    });
    test('with day only', () {
      final filter = DayFilter.empty().copyWith(days: {10, 12});
      final term = Term.parse('1Jan22-31Dec24', UTC);
      final res = filter.getDays(term);
      expect(res.length, 72);
    });

    test('with holidays only', () {
      final filter = DayFilter.empty().copyWith(holidays: {Holiday.christmas});
      final term = Term.parse('1Jan22-31Dec24', UTC);
      final res = filter.getDays(term);
      expect(res.length, 3);
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
