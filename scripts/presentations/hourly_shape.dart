library scripts.presentations.hourly_shape;

import 'dart:io';

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/physical/load/lib_duck_curve.dart';
import 'package:elec_server/client/isoexpress/zonal_demand.dart';
import 'package:elec_server/utils.dart';
import 'package:http/http.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

/// Make the plots and data needed for
/// rascal/presentations/energy/hourly_shape/

Future<Map<String, TimeSeries<num>>> getData() async {
  final start = Date(2020, 1, 1, location: IsoNewEngland.location);
  final end = Date(2023, 12, 31, location: IsoNewEngland.location);
  final client = IsoneZonalDemand(Client(), rootUrl: dotenv.env['ROOT_URL']!);
  final ts = await client.getPoolDemand(Market.rt, start, end);

  final maine = await client.getZonalDemand(4001, Market.rt, start, end);
  final nh = await client.getZonalDemand(4002, Market.rt, start, end);

  return {
    'isone': ts,
    'maine': maine,
    'nh': nh,
  };
}

/// Show the effect of a sunny and cloudy day on electricity demand.
void plotWithTwoDaysIsone(Map<String, TimeSeries<num>> data) {
  var isone = data['isone']!;
  var dHi = isone.window(Date(2023, 3, 29, location: IsoNewEngland.location));
  var meanHi = dHi.map((e) => e.value).mean();
  var wHi = <num>[...dHi.map((e) => e.value / meanHi)];
  print(duckMeasure(wHi, start: 7, end: 19));

  var dLow = isone.window(Date(2023, 3, 14, location: IsoNewEngland.location));
  var meanLow = dLow.map((e) => e.value).mean();
  var wLow = <num>[...dLow.map((e) => e.value / meanLow)];
  print(duckMeasure(wLow, start: 7, end: 19));

  var traces = [
    {
      'x': dHi.map((e) => e.interval.start.hour).toList(),
      'y': wHi,
      'name': '2023-03-29',
    },
    {
      'x': dLow.map((e) => e.interval.start.hour).toList(),
      'y': wLow,
      'name': '2023-03-14',
    },
  ];

  final layout = {
    'width': 900,
    'height': 600,
    'title': '',
    'xaxis': {
      'showgrid': true,
      'gridcolor': '#d3d3d3',
      'title': 'Hour beginning',
    },
    'yaxis': {
      'showgrid': true,
      'gridcolor': '#d3d3d3',
      'zeroline': false,
      'title': 'Hourly weight',
    },
    'showlegend': true,
    'hovermode': 'closest',
  };

  final dir = '${Platform.environment['HOME']}/Documents/repos/git/thumbert'
      '/rascal/presentations/energy/hourly_shape/src/assets';
  Plotly.now(traces, layout, file: File('$dir/two_days.html'));
}

void plotHistoricalDuckIsone(Map<String, TimeSeries<num>> data) {
  var isone = data['isone']!;
  var groups =
      isone.groupByIndex((interval) => Date.containing(interval.start));
  var duckTs = groups.map((e) {
    var avg = e.value.mean();
    var ws = <num>[...e.value.map((e) => e / avg)];
    var duck = duckMeasure(ws, start: 7, end: 19);
    return IntervalTuple(e.interval, duck);
  }).toTimeSeries();

  var traces = [
    {
      'x': duckTs.map((e) => e.interval.start.toString()).toList(),
      'y': duckTs.values.toList(),
      'type': 'scatter',
      'mode': 'markers',
    },
  ];

  final layout = {
    'width': 900,
    'height': 600,
    'title': 'ISONE',
    'xaxis': {
      'showgrid': true,
      'gridcolor': '#d3d3d3',
      'title': 'Day',
    },
    'yaxis': {
      'showgrid': true,
      'gridcolor': '#d3d3d3',
      'zeroline': false,
      'title': 'Duck strength, D',
    },
    // 'showlegend': true,
    'hovermode': 'closest',
  };

  final dir = '${Platform.environment['HOME']}/Documents/repos/git/thumbert'
      '/rascal/presentations/energy/hourly_shape/src/assets';
  Plotly.now(traces, layout, file: File('$dir/isone_duck.html'));
}

void plotCompareZonesIsone(Map<String, TimeSeries<num>> data) {
  var interval = Term.parse('Mar23-Apr23', IsoNewEngland.location).interval;
  var maine = data['maine']!.window(interval).toTimeSeries();
  var groups =
      maine.groupByIndex((interval) => Date.containing(interval.start));
  var maineTs = groups.map((e) {
    var avg = e.value.mean();
    var ws = <num>[...e.value.map((e) => e / avg)];
    var duck = duckMeasure(ws, start: 7, end: 19);
    return IntervalTuple(e.interval, duck);
  }).toTimeSeries();

  var nh = data['nh']!.window(interval).toTimeSeries();
  groups = nh.groupByIndex((interval) => Date.containing(interval.start));
  var nhTs = groups.map((e) {
    var avg = e.value.mean();
    var ws = <num>[...e.value.map((e) => e / avg)];
    var duck = duckMeasure(ws, start: 7, end: 19);
    return IntervalTuple(e.interval, duck);
  }).toTimeSeries();

  var traces = [
    {
      'x': maineTs.map((e) => e.interval.start.toString()).toList(),
      'y': maineTs.values.toList(),
      'name': 'Maine',
      'type': 'scatter',
      'mode': 'markers+lines',
    },
    {
      'x': nhTs.map((e) => e.interval.start.toString()).toList(),
      'y': nhTs.values.toList(),
      'name': 'NH',
      'type': 'scatter',
      'mode': 'markers+lines',
    },
  ];

  final layout = {
    'width': 900,
    'height': 600,
    'title': 'Comparison between two load zones',
    'xaxis': {
      'showgrid': true,
      'gridcolor': '#d3d3d3',
      'title': 'Day',
    },
    'yaxis': {
      'showgrid': true,
      'gridcolor': '#d3d3d3',
      'zeroline': false,
      'title': 'Duck strength, D',
    },
    'showlegend': true,
    'hovermode': 'closest',
  };

  final dir = '${Platform.environment['HOME']}/Documents/repos/git/thumbert'
      '/rascal/presentations/energy/hourly_shape/src/assets';
  Plotly.now(traces, layout, file: File('$dir/isone_compare_zones.html'));
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  var data = await getData();
  // plotWithTwoDaysIsone(data);
  // plotHistoricalDuckIsone(data);
  plotCompareZonesIsone(data);
}
