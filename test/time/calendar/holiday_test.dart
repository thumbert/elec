library test_holiday;

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

test_holiday() {
  group("Test Holidays:", (){
    
    test("Columbus day", () {
      expect("2017-10-09", new ColumbusDay().forYear(2017).toString());
      expect("2018-10-08", new ColumbusDay().forYear(2018).toString());
      expect("2019-10-14", new ColumbusDay().forYear(2019).toString());
      expect(new ColumbusDay().isDate(new Date(2017, 10, 9)), true);
    });

    test("Election Day", (){
      expect("2017-11-07", new ElectionDay().forYear(2017).toString());
      expect("2019-11-05", new ElectionDay().forYear(2019).toString());
      expect("2020-11-03", new ElectionDay().forYear(2020).toString());
      expect(new ElectionDay().isDate(new Date(2017,11,07)), true);
      expect(new ElectionDay().holidayType, HolidayType.electionDay);
    });

    test("Good Friday", (){
      expect("2018-03-30", new GoodFriday().forYear(2018).toString());
      expect("2017-04-14", new GoodFriday().forYear(2017).toString());
      expect(new GoodFriday().isDate(new Date(2017,4,14)), true);
      expect(new GoodFriday().isDate(new Date(2017,4,15)), false);
    });

    test("Labor Day", (){
      expect("2012-09-03", new LaborDay().forYear(2012).toString());
      expect("2013-09-02", new LaborDay().forYear(2013).toString());
      expect("2014-09-01", new LaborDay().forYear(2014).toString());
      expect(new LaborDay().isDate(new Date(2012,9,3)), true);
    });

    test("Lincoln\'s birthday", (){
      expect("2011-02-11", new LincolnBirthday().forYear(2011).toString());
      expect("2017-02-13", new LincolnBirthday().forYear(2017).toString());
      expect("2016-02-12", new LincolnBirthday().forYear(2016).toString());
      expect("2015-02-12", new LincolnBirthday().forYear(2015).toString());
      expect(new LincolnBirthday().isDate(new Date(2017,2,13)), true);
      expect(new LincolnBirthday().isDate(new Date(2017,2,12)), false);
    });

    test("Martin Luther King birthday", (){
      expect("2012-01-16", new MlkBirthday().forYear(2012).toString());
      expect("2013-01-21", new MlkBirthday().forYear(2013).toString());
      expect("2014-01-20", new MlkBirthday().forYear(2014).toString());
      expect(new MlkBirthday().isDate(new Date(2012, 1, 16)), true);
    });

    test("Memorial Day", (){
      expect("2012-05-28", new MemorialDay().forYear(2012).toString());
      expect("2013-05-27", new MemorialDay().forYear(2013).toString());
      expect("2014-05-26", new MemorialDay().forYear(2014).toString());
      expect(new MemorialDay().isDate(new Date(2012, 5, 28)), true);
    });

    test("Thanksgiving", () {
      expect("2012-11-22", new Thanksgiving().forYear(2012).toString());
      expect("2013-11-28", new Thanksgiving().forYear(2013).toString());
      expect("2014-11-27", new Thanksgiving().forYear(2014).toString());
      expect(new Thanksgiving().isDate(new Date(2012, 11, 22)), true);
    });

    test("Veterans Day", (){
      expect("2012-11-12", new VeteransDay().forYear(2012).toString());
      expect("2019-11-11", new VeteransDay().forYear(2019).toString());
      expect("2017-11-10", new VeteransDay().forYear(2017).toString());
      expect(new VeteransDay().isDate(new Date(2017,11,10)), true);
      expect(new VeteransDay().isDate(new Date(2017,4,15)), false);
      expect(new VeteransDay().holidayType, HolidayType.veteransDay);
    });

    test("Victory Day", (){
      expect("2017-08-14", new VictoryDay().forYear(2017).toString());
      expect("2018-08-13", new VictoryDay().forYear(2018).toString());
      expect("2019-08-12", new VictoryDay().forYear(2019).toString());
      expect(new VictoryDay().isDate(new Date(2017,8,14)), true);
      expect(new VictoryDay().isDate(new Date(2017,4,15)), false);
      expect(new VictoryDay().holidayType, HolidayType.victoryDay);
    });

    test("Washington\'s birthday", (){
      expect("2017-02-20", new WashingtonBirthday().forYear(2017).toString());
      expect("2018-02-19", new WashingtonBirthday().forYear(2018).toString());
      expect("2021-02-15", new WashingtonBirthday().forYear(2021).toString());
      expect(new WashingtonBirthday().isDate(new Date(2017,2,20)), true);
    });


  });

}

main() => test_holiday();