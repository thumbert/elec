library holiday;

import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

enum HolidayType {
  christmas('Christmas'),
  columbusDay('Columbus Day'),
  dayAfterThanksgiving('Day-After Thanksgiving'),
  electionDay('Election Day'),
  goodFriday('Good Friday'),
  independenceDay('Independence day'),
  juneteenth('Juneteenth'),
  laborDay('Labor Day'),
  lincolnBirthday('Lincoln\'s Day'),
  memorialDay('Memorial Day'),
  mlkBirthday('MLK Day'),
  newYear('New Year'),
  patriotsDay('Patriots Day'),
  thanksgiving('Thanksgiving'),
  veteransDay('Veterans Day'),
  victoryDay('Victory Day'),
  washingtonBirthday('Presidents birthday');

  const HolidayType(this.name);

  final String name;
}

abstract class Holiday {
  late HolidayType holidayType;
  Date? forYear(int year, {required Location location});
  bool isDate(Date date);
}
