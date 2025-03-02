

import 'package:date/date.dart';
import 'package:elec/src/iso/isone/lib_utils.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  group('ISONE utils tests', (){
    test('isDamPublished tests', () async {
      expect(await isDamPublished(Date.utc(2025, 3, 2)), true);
    });
  });

}

void main() async {
  initializeTimeZones();
  await tests();
}