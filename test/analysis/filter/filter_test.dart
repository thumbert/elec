library test.analysis.filter.filter_test;

import 'package:date/date.dart';
import 'package:test/test.dart';
import 'package:elec/analysis.dart';

void tests() async {
  group('Historical filter tests: ', () {
    test('combining filters', () async {
      var filter = DateFilter()
        ..add(DaysBeforeFilter(Date.utc(2020, 4, 9), dayCount: 10))
        ..add(WeekdayFilter());
      var days = parseTerm('25Mar20-15Apr20')!
          .splitLeft((dt) => Date.fromTZDateTime(dt));
      var filteredDays = days.where((e) => filter.contains(e)).toList();
      expect(filteredDays.length, 8);
      expect(filteredDays.first, Date.utc(2020, 3, 30));
    });
  });
}

void main() {
  tests();
}
