library test.risk_system.marks.electricity_marks_test;

import 'package:test/test.dart';
import 'package:elec/src/risk_system/marks/electricity_marks.dart';

tests() {
  group('Electricity marks', () {
    test('the 3 standard buckets', () {
      var marks = ElectricityMarks(81.25, 67.50, 35.60);
      print(marks);
      expect(marks.toString(), '{5x16: 81.25, 2x16H: 67.5, 7x8: 35.6}');
      expect(marks.price5x16, 81.25);
      expect(marks.price2x16H, 67.5);
      expect(marks.price7x8, 35.6);
      expect(marks.toMap(), {'5x16': 81.25, '2x16H': 67.5, '7x8': 35.6});
      var marks2 = ElectricityMarks.fromMap({'5x16': 81.25, '2x16H': 67.5, '7x8': 35.6});
      expect(marks2.toString(), '{5x16: 81.25, 2x16H: 67.5, 7x8: 35.6}');
    });
  });
}


main() {
  tests();
}