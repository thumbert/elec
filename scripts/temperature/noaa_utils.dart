

import 'dart:convert';
import 'dart:io';
import 'dart:async';

/// Data available for download at
/// https://www.ncei.noaa.gov/orders/cdo/926924.csv
Future<List<Map>> getNoaaCsvData() async {
  String url = 'https://www.ncei.noaa.gov/orders/cdo/926924.csv';
  HttpClient client = new HttpClient();
  var request = await client.getUrl(Uri.parse(url));
  var response = await request.close();

  List<Map> res = [];
  List<String> names = ['station', 'station name', 'elevation',
    'latitude', 'longitude', 'date', 'tmax', 'tmin'];
  response.transform(UTF8.decoder).listen((contents){
    print(contents);
  });

  return res;
}

/// insert the data into mongodb
insertDailyTemperatureData(List<Map> x) {

}

main() {
  getNoaaCsvData();
}