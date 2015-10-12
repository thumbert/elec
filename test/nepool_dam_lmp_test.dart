library nepool_dam_lmp_test;

import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec/src/iso/nepool/nepool_da_lmp.dart';


setup() async {
  DamArchive arch = new DamArchive();
  await arch.setup();

  await arch.updateDb(new Date(2015,1,1), new Date(2015,5,1));
}

test_nepool_dam() async {
  DamArchive arch = new DamArchive();

  await arch.db.open();
  Date end = await arch.lastDayInserted();
  print('Last day inserted is: $end');
  await arch.removeDataForDay(end);
  print('Last day inserted is: ${await arch.lastDayInserted()}');
  await arch.db.close();
}


main() async {
  await test_nepool_dam();
}