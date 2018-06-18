

import 'package:date/date.dart';

enum DayType {
  weekday,
  weekend,
  holiday,     // holidays are classified using a Calendar
  extremeCold,
  extremeHeat,
  heatWave1,   // day 1 of a heat wave
  heatWave2,   // day 2 of a heat wave
  heatWave3,
  coldSpell1,
  coldSpell2,
  coldSpell3,
  snowStorm,
  sunny,
}


bool isWeekend(Date date) => date.isWeekend();
bool isWeekday(Date date) => !date.isWeekend();
