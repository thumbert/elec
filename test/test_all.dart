library test_all;

import 'bucket_test.dart' as bucket_test;
import 'holiday_test.dart' as holiday_test;


main() async {
  await bucket_test.main();
  holiday_test.main();

}