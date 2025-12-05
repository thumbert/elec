import 'package:elec/risk_system.dart';
import 'package:test/test.dart';

void tests() {
  group('Market tests: ', () {
    test('compareTo', () {
      var da = Market.da;
      var rt = Market.rt;
      expect(da.compareTo(rt), -1);
      expect(da.compareTo(Market.da), 0);
      expect(Market.rt.compareTo(Market.da), 1);
    });
    test('equality', () {
      expect(Market.da == Market.da, true);
      expect(Market.rt == Market.rt, true);
    });
  });
}

void main() {
  tests();
}
