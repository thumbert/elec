import 'dart:io';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec/elec.dart';

/// Data available for download at
/// https://www.ncei.noaa.gov/orders/cdo/926924.csv
/// link is available only for a number of days (10?)
List<Map> getNoaaCsvData() {
  Map env = Platform.environment;
  File file =
      new File(env['HOME'] + '/Downloads/Archive/temperature/noaa/926924.csv');

  List<Map> res = [];
  List<String> keys = [
    'station',
    'station name',
    'elevation',
    'latitude',
    'longitude',
    'date',
    'tmax',
    'tmin'
  ];

  var aux =
      const CsvToListConverter(eol: '\n').convert(file.readAsStringSync());
  aux.skip(1).forEach((e) {
    res.add(new Map.fromIterables(
        keys, [e[0], e[1], e[2], e[3], e[4], e[5], e[11], e[16]]));
  });

  return res;
}

/// Insert daily temperature data into mongodb
/// One document looks like this
/// {station: GHCND:USW00014739, station name: BOSTON MA US, elevation: 6.1, latitude: 42.36667, longitude: -71.03333, date: 1980-01-01 00:00:00.000Z, tmax: 38, tmin: 26}
///
insertTemperatureDataMongo(List<Map> data) async {
  Db db = new Db("mongodb://localhost:27017/weather");
  await db.open();
  await db.ensureIndex('daily', keys: {
    'station': 1,
    'date': 1,
  });
  var coll = db.collection('daily');
  await coll.insertAll(data, writeConcern: WriteConcern.ACKNOWLEDGED);
  await db.close();
}

/// Parse a date in the yyyymmdd format.
/// Return a UTC DateTime object.
DateTime _parseDate(num yyyymmdd) {
  int year = (yyyymmdd / 10000).truncate();
  int month = ((yyyymmdd - 10000 * year) / 100).truncate();
  int day = yyyymmdd - 10000 * year - 100 * month;
  return new DateTime.utc(year, month, day);
}

/// Test the contents of the database.
//Future<List<Map>> getTemperatureMongo() async{
//  var api = new ApiTemperatureNoaa();
//  await api.init();
//  var aux = await api.getTemperature('USW00014739');
//  await api.db.close();
//
//  List<String> keys = ['date', 'tmin','tmax'];
//
//
//  return res.result;
//}

main() async {
//  List data = getNoaaCsvData();
//  data.take(3).forEach(print);
//  await insertTemperatureDataMongo(data);

//  var res = await getTemperatureMongo();
//  res.take(5).forEach(print);


}
