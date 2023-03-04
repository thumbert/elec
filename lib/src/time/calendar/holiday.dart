library holiday;

import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holidays/christmas.dart';
import 'package:elec/src/time/calendar/holidays/columbus_day.dart';
import 'package:elec/src/time/calendar/holidays/day_after_thanksgiving.dart';
import 'package:elec/src/time/calendar/holidays/election_day.dart';
import 'package:elec/src/time/calendar/holidays/good_friday.dart';
import 'package:elec/src/time/calendar/holidays/independence_day.dart';
import 'package:elec/src/time/calendar/holidays/juneteenth.dart';
import 'package:elec/src/time/calendar/holidays/labor_day.dart';
import 'package:elec/src/time/calendar/holidays/lincoln_birthday.dart';
import 'package:elec/src/time/calendar/holidays/memorial_day.dart';
import 'package:elec/src/time/calendar/holidays/mlk_birthday.dart';
import 'package:elec/src/time/calendar/holidays/new_year.dart';
import 'package:elec/src/time/calendar/holidays/patriots_day.dart';
import 'package:elec/src/time/calendar/holidays/thanksgiving.dart';
import 'package:elec/src/time/calendar/holidays/veterans_day.dart';
import 'package:elec/src/time/calendar/holidays/victory_day.dart';
import 'package:elec/src/time/calendar/holidays/washington_birthday.dart';
import 'package:timezone/timezone.dart';

enum HolidayType {
  christmas('Christmas'),
  columbusDay('Columbus Day'),
  dayAfterThanksgiving('Day-After Thanksgiving'),
  electionDay('Election Day'),
  goodFriday('Good Friday'),
  independenceDay('Independence Day'),
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
  washingtonBirthday('Presidents Day');

  const HolidayType(this.name);

  final String name;
}

abstract class Holiday {
  late HolidayType holidayType;
  /// Needs to be nullable because sometimes holidays are added or retired.
  /// For example Juneteenth.
  Date? forYear(int year, {required Location location});
  bool isDate(Date date);

  static Holiday parse(String name) {
    var out = holidays[name];
    if (out == null) {
      throw ArgumentError('Unknown holiday name $name');
    }
    return out;
  }

  static final christmas = Christmas();
  static final columbusDay = ColumbusDay();
  static final dayAfterThanksgiving = DayAfterThanksgiving();
  static final electionDay = ElectionDay();
  static final goodFriday = GoodFriday();
  static final independenceDay = IndependenceDay();
  static final juneteenth = Juneteenth();
  static final laborDay = LaborDay();
  static final lincolnBirthday = LincolnBirthday();
  static final memorialDay = MemorialDay();
  static final mlkBirthday = MlkBirthday();
  static final newYear = NewYear();
  static final patriotsDay = PatriotsDay();
  static final thanksgiving = Thanksgiving();
  static final veteransDay = VeteransDay();
  static final victoryDay = VictoryDay();
  static final washingtonBirthday = WashingtonBirthday();

  static final Map<String,Holiday> holidays = {
    'Christmas': Holiday.christmas,
    'Columbus Day': Holiday.columbusDay,
    'Day-After Thanksgiving': Holiday.dayAfterThanksgiving,
    'Election Day': Holiday.electionDay,
    'Good Friday': Holiday.goodFriday,
    'Independence Day': Holiday.independenceDay,
    'Juneteenth': Holiday.juneteenth,
    'Labor Day': Holiday.laborDay,
    'Lincoln\'s Day': Holiday.lincolnBirthday,
    'Memorial Day': Holiday.memorialDay,
    'MLK Day': Holiday.mlkBirthday,
    'New Year': Holiday.newYear,
    'Patriots Day': Holiday.patriotsDay,
    'Presidents Day': Holiday.washingtonBirthday,
    'Thanksgiving': Holiday.thanksgiving,
    'Veterans Day': Holiday.veteransDay,
    'Victory Day': Holiday.victoryDay,
  };

}
