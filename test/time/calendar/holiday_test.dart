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

void tests() {
  group( 'Test Holidays: ', (){
    
    test( 'Columbus day ', () {
      expect( '2017-10-09',  ColumbusDay().forYear(2017).toString());
      expect( '2018-10-08',  ColumbusDay().forYear(2018).toString());
      expect( '2019-10-14',  ColumbusDay().forYear(2019).toString());
      expect( ColumbusDay().isDate( Date(2017, 10, 9)), true);
    });

    test( 'Election Day ', (){
      expect( '2017-11-07',  ElectionDay().forYear(2017).toString());
      expect( '2019-11-05',  ElectionDay().forYear(2019).toString());
      expect( '2020-11-03',  ElectionDay().forYear(2020).toString());
      expect( ElectionDay().isDate( Date(2017,11,07)), true);
      expect( ElectionDay().holidayType, HolidayType.electionDay);
    });

    test( 'Good Friday ', (){
      expect( '2018-03-30',  GoodFriday().forYear(2018).toString());
      expect( '2017-04-14',  GoodFriday().forYear(2017).toString());
      expect( GoodFriday().isDate( Date(2017,4,14)), true);
      expect( GoodFriday().isDate( Date(2017,4,15)), false);
    });

    test( 'Labor Day ', (){
      expect( '2012-09-03',  LaborDay().forYear(2012).toString());
      expect( '2013-09-02',  LaborDay().forYear(2013).toString());
      expect( '2014-09-01',  LaborDay().forYear(2014).toString());
      expect( LaborDay().isDate( Date(2012,9,3)), true);
    });

    test( 'Lincoln\'s birthday ', (){
      expect( '2011-02-11',  LincolnBirthday().forYear(2011).toString());
      expect( '2017-02-13',  LincolnBirthday().forYear(2017).toString());
      expect( '2016-02-12',  LincolnBirthday().forYear(2016).toString());
      expect( '2015-02-12',  LincolnBirthday().forYear(2015).toString());
      expect( LincolnBirthday().isDate( Date(2017,2,13)), true);
      expect( LincolnBirthday().isDate( Date(2017,2,12)), false);
    });

    test( 'Martin Luther King birthday ', (){
      expect( '2012-01-16',  MlkBirthday().forYear(2012).toString());
      expect( '2013-01-21',  MlkBirthday().forYear(2013).toString());
      expect( '2014-01-20',  MlkBirthday().forYear(2014).toString());
      expect( MlkBirthday().isDate( Date(2012, 1, 16)), true);
    });

    test( 'Memorial Day ', (){
      expect( '2012-05-28',  MemorialDay().forYear(2012).toString());
      expect( '2013-05-27',  MemorialDay().forYear(2013).toString());
      expect( '2014-05-26',  MemorialDay().forYear(2014).toString());
      expect( MemorialDay().isDate( Date(2012, 5, 28)), true);
    });

    test( 'Thanksgiving ', () {
      expect( '2012-11-22',  Thanksgiving().forYear(2012).toString());
      expect( '2013-11-28',  Thanksgiving().forYear(2013).toString());
      expect( '2014-11-27',  Thanksgiving().forYear(2014).toString());
      expect( Thanksgiving().isDate( Date(2012, 11, 22)), true);
    });

    test( 'Veterans Day ', (){
      expect( '2012-11-12',  VeteransDay().forYear(2012).toString());
      expect( '2019-11-11',  VeteransDay().forYear(2019).toString());
      expect( '2017-11-10',  VeteransDay().forYear(2017).toString());
      expect( VeteransDay().isDate( Date(2017,11,10)), true);
      expect( VeteransDay().isDate( Date(2017,4,15)), false);
      expect( VeteransDay().holidayType, HolidayType.veteransDay);
    });

    test( 'Victory Day ', (){
      expect( '2017-08-14',  VictoryDay().forYear(2017).toString());
      expect( '2018-08-13',  VictoryDay().forYear(2018).toString());
      expect( '2019-08-12',  VictoryDay().forYear(2019).toString());
      expect( VictoryDay().isDate( Date(2017,8,14)), true);
      expect( VictoryDay().isDate( Date(2017,4,15)), false);
      expect( VictoryDay().holidayType, HolidayType.victoryDay);
    });

    test( 'Washington\'s birthday ', (){
      expect( '2017-02-20',  WashingtonBirthday().forYear(2017).toString());
      expect( '2018-02-19',  WashingtonBirthday().forYear(2018).toString());
      expect( '2021-02-15',  WashingtonBirthday().forYear(2021).toString());
      expect( WashingtonBirthday().isDate( Date(2017,2,20)), true);
    });


  });

}

void main() => tests();