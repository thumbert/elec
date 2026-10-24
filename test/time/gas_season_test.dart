import 'package:elec/src/time/gas_season.dart';
import 'package:test/test.dart';

void tests() {
  group('Gas season tests:', () {
    test('empty', () {
      expect(gasSeason(2026, 11), 'Nov26-Mar27');
      expect(gasSeason(2026, 4), 'Apr26-Oct26');
      expect(gasSeason(2026, 3), 'Nov25-Mar26');
    });
  });
}

void main() async {
  tests();
}
