library test_all;

import 'bucket_test.dart' as bucket_test;
import 'holiday_test.dart' as holiday_test;

import 'package:elec/src/iso/nepool/config.dart';

main() async {
  await bucket_test.main();
  holiday_test.main();

  LocalConfig config = new LocalConfig();
  print(config.components['nepool_dam_lmp_hourly'].host);

}