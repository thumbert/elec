library nepool_binding_constraints_test;

import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec/src/iso/nepool/nepool_binding_constraints.dart';


setup() async {
  DaBindingConstraintArchive arch = new DaBindingConstraintArchive();
  await arch.setup();

  //await arch.updateDb(new Date(2015,1,1), new Date(2015,5,1));
}

test_nepool_bc() async {
  DaBindingConstraintArchive arch = new DaBindingConstraintArchive();

  await arch.db.open();
  Date end = await arch.lastDayInserted();
  print('Last day inserted is: $end');
  await arch.removeDataForDay(end);
  print('Last day inserted is: ${await arch.lastDayInserted()}');
  await arch.db.close();
}


main() async {
  await setup();

  //await test_nepool_bc();
}