library test_holiday;

import 'package:elec/src/time/calendar/holidays/juneteenth.dart';
import 'package:test/test.dart';
import 'package:date/date.dart';
import 'package:elec/src/time/calendar/holiday.dart';
import 'package:elec/src/time/calendar/holidays/lincoln_birthday.dart';
import 'package:elec/src/time/calendar/holidays/good_friday.dart';
import 'package:elec/src/time/calendar/holidays/labor_day.dart';
import 'package:elec/src/time/calendar/holidays/memorial_day.dart';
import 'package:elec/src/time/calendar/holidays/thanksgiving.dart';
import 'package:elec/src/time/calendar/holidays/mlk_birthday.dart';
import 'package:elec/src/time/calendar/holidays/washington_birthday.dart';
import 'package:elec/src/time/calendar/holidays/columbus_day.dart';
import 'package:elec/src/time/calendar/holidays/veterans_day.dart';
import 'package:elec/src/time/calendar/holidays/election_day.dart';
import 'package:elec/src/time/calendar/holidays/victory_day.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('Test Holidays: ', () {
    test('Columbus day ', () {
      expect(
          '2017-10-09', ColumbusDay().forYear(2017, location: UTC).toString());
      expect(
          '2018-10-08', ColumbusDay().forYear(2018, location: UTC).toString());
      expect(
          '2019-10-14', ColumbusDay().forYear(2019, location: UTC).toString());
      expect(ColumbusDay().isDate(Date(2017, 10, 9, location: UTC)), true);
    });

    test('Election Day ', () {
      expect(
          '2017-11-07', ElectionDay().forYear(2017, location: UTC).toString());
      expect(
          '2019-11-05', ElectionDay().forYear(2019, location: UTC).toString());
      expect(
          '2020-11-03', ElectionDay().forYear(2020, location: UTC).toString());
      expect(ElectionDay().isDate(Date(2017, 11, 07, location: UTC)), true);
      expect(ElectionDay().holidayType, HolidayType.electionDay);
    });

    test('Good Friday ', () {
      expect(
          '2018-03-30', GoodFriday().forYear(2018, location: UTC).toString());
      expect(
          '2017-04-14', GoodFriday().forYear(2017, location: UTC).toString());
      expect(GoodFriday().isDate(Date(2017, 4, 14, location: UTC)), true);
      expect(GoodFriday().isDate(Date(2017, 4, 15, location: UTC)), false);
    });

    test('Juneteenth', () {
      expect(Juneteenth().forYear(2020, location: UTC), null);
      expect(
          Juneteenth().forYear(2021, location: UTC).toString(), '2021-06-18');
      expect(
          Juneteenth().forYear(2022, location: UTC).toString(), '2022-06-20');
      expect(
          Juneteenth().forYear(2023, location: UTC).toString(), '2023-06-19');
      expect(Juneteenth().isDate(Date(2022, 6, 20, location: UTC)), true);
      expect(Juneteenth().isDate(Date(2020, 6, 19, location: UTC)), false);
    });

    test('Labor Day ', () {
      expect('2012-09-03', LaborDay().forYear(2012, location: UTC).toString());
      expect('2013-09-02', LaborDay().forYear(2013, location: UTC).toString());
      expect('2014-09-01', LaborDay().forYear(2014, location: UTC).toString());
      expect(LaborDay().isDate(Date(2012, 9, 3, location: UTC)), true);
    });

    test('Lincoln\'s birthday ', () {
      expect('2011-02-11',
          LincolnBirthday().forYear(2011, location: UTC).toString());
      expect('2017-02-13',
          LincolnBirthday().forYear(2017, location: UTC).toString());
      expect('2016-02-12',
          LincolnBirthday().forYear(2016, location: UTC).toString());
      expect('2015-02-12',
          LincolnBirthday().forYear(2015, location: UTC).toString());
      expect(LincolnBirthday().isDate(Date(2017, 2, 13, location: UTC)), true);
      expect(LincolnBirthday().isDate(Date(2017, 2, 12, location: UTC)), false);
    });

    test('Martin Luther King birthday ', () {
      expect(
          '2012-01-16', MlkBirthday().forYear(2012, location: UTC).toString());
      expect(
          '2013-01-21', MlkBirthday().forYear(2013, location: UTC).toString());
      expect(
          '2014-01-20', MlkBirthday().forYear(2014, location: UTC).toString());
      expect(MlkBirthday().isDate(Date(2012, 1, 16, location: UTC)), true);
    });

    test('Memorial Day ', () {
      expect(
          '2012-05-28', MemorialDay().forYear(2012, location: UTC).toString());
      expect(
          '2013-05-27', MemorialDay().forYear(2013, location: UTC).toString());
      expect(
          '2014-05-26', MemorialDay().forYear(2014, location: UTC).toString());
      expect(MemorialDay().isDate(Date(2012, 5, 28, location: UTC)), true);
      expect(MemorialDay().isDate(Date(2022, 5, 30, location: UTC)), true);
      expect(MemorialDay().isDate(Date(2023, 5, 29, location: UTC)), true);
    });

    test('Thanksgiving ', () {
      expect(
          '2012-11-22', Thanksgiving().forYear(2012, location: UTC).toString());
      expect(
          '2013-11-28', Thanksgiving().forYear(2013, location: UTC).toString());
      expect(
          '2014-11-27', Thanksgiving().forYear(2014, location: UTC).toString());
      expect(Thanksgiving().isDate(Date(2012, 11, 22, location: UTC)), true);
    });

    test('Veterans Day ', () {
      expect(
          '2012-11-12', VeteransDay().forYear(2012, location: UTC).toString());
      expect(
          '2019-11-11', VeteransDay().forYear(2019, location: UTC).toString());
      expect(
          '2017-11-10', VeteransDay().forYear(2017, location: UTC).toString());
      expect(VeteransDay().isDate(Date(2017, 11, 10, location: UTC)), true);
      expect(VeteransDay().isDate(Date(2017, 4, 15, location: UTC)), false);
      expect(VeteransDay().holidayType, HolidayType.veteransDay);
    });

    test('Victory Day ', () {
      expect(
          '2017-08-14', VictoryDay().forYear(2017, location: UTC).toString());
      expect(
          '2018-08-13', VictoryDay().forYear(2018, location: UTC).toString());
      expect(
          '2019-08-12', VictoryDay().forYear(2019, location: UTC).toString());
      expect(VictoryDay().isDate(Date(2017, 8, 14, location: UTC)), true);
      expect(VictoryDay().isDate(Date(2017, 4, 15, location: UTC)), false);
      expect(VictoryDay().holidayType, HolidayType.victoryDay);
    });

    test('Washington\'s birthday ', () {
      expect('2017-02-20',
          WashingtonBirthday().forYear(2017, location: UTC).toString());
      expect('2018-02-19',
          WashingtonBirthday().forYear(2018, location: UTC).toString());
      expect('2021-02-15',
          WashingtonBirthday().forYear(2021, location: UTC).toString());
      expect(
          WashingtonBirthday().isDate(Date(2017, 2, 20, location: UTC)), true);
    });
  });
}

void main() => tests();
