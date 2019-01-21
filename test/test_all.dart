library test_all;

import 'package:timezone/standalone.dart';
import 'bucket_test.dart' as bucket_test;
import 'holiday_test.dart' as holiday_test;
import 'calendar_test.dart' as calendar_test;

main() async {
  await initializeTimeZone();

  bucket_test.test_bucket();
  bucket_test.aggregateByBucketMonth();
  calendar_test.main();
  holiday_test.main();



}