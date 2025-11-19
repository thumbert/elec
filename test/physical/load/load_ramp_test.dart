import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec/src/physical/load/load_ramp.dart';
import 'package:test/test.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  group('Lib load ramp tests', () {
    test('winter day with double ramp', () async {
      var term = Term.parse('14Nov25', IsoNewEngland.location);
      var ts = TimeSeries.from(term.hours(), [
        11225,
        10894,
        10729,
        10767,
        11114,
        12011,
        13356,
        13802,
        13182,
        12546,
        12219,
        12220,
        12441,
        12927,
        13387,
        13974,
        14747,
        15120,
        14812,
        14349,
        13851,
        13216,
        12436,
        11655,
      ]);
      var ramps = calculateLoadRamp(ts);
      expect(ramps.length, 1); // one day
      expect(ramps.first.value.length, 2); // two ramps
      expect(
          ramps.first.value[0] ==
              Ramp(
                  endHourBeginning: 7,
                  maxLoad: 13802,
                  minLoad: 10729,
                  startHourBeginning: 2),
          true);
      expect(
          ramps.first.value[1] ==
              Ramp(
                  endHourBeginning: 17,
                  maxLoad: 15120,
                  minLoad: 12219,
                  startHourBeginning: 10),
          true);
    });

    test('summer day with single ramp', () async {
      var term = Term.parse('17Jul25', IsoNewEngland.location);

      var ts = TimeSeries.from(term.hours(), [
        17249,
        16343,
        15723,
        15396,
        15440,
        15971,
        17001,
        18157,
        18957,
        19464,
        19967,
        20533,
        20954,
        21554,
        21847,
        22159,
        22844,
        23243,
        23399,
        23157,
        22713,
        21742,
        20143,
        18423,
      ]);
      var ramps = calculateLoadRamp(ts);
      expect(ramps.length, 1); // one day
      expect(ramps.first.value.length, 1); // one ramp
      expect(
          ramps.first.value[0] ==
              Ramp(
                  endHourBeginning: 18,
                  maxLoad: 23399,
                  minLoad: 15396,
                  startHourBeginning: 3),
          true);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests(dotenv.env['ROOT_URL']!);
}
