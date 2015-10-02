library mongo.nepool_dalmp;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:rpc/rpc.dart';

import 'package:elec/src/iso/nepool/iso_timestamp.dart';
import 'package:elec/src/iso/nepool/archive.dart';
import 'package:elec/src/iso/nepool/config.dart';




/**
 * +0400 for EDT, +0500 for EST
 * db.DA_LMP.find({ptid: 321, hourBeginning: {$lte: ISODate('2014-11-03T04:00:00Z')}})
 * db.DA_LMP.find({ptid: 321, hourBeginning: {$gte: ISODate('2014-11-05T05:00:00Z')}}).limit(5)
 *
 *
 */
@ApiClass(name: 'dalmp', version: 'v1')
class DaLmp extends ComponentConfig {
  DbCollection coll;
  Location location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");

  DaLmp({ComponentConfig component}) {
    if (component == null) {
      Config config = new LocalConfig();
      component = config.components[''];
    }
    dbName = component.dbName;
    DIR = component.DIR;
    collectionName = component.collectionName;

    coll = db.collection(collectionName);
    initializeTimeZoneSync();
    location = getLocation('America/New_York');
  }

  /**
   * Get the low and high limit for the data to define the yScale for plotting.
   * [start] a day in the yyyy-mm-dd format, e.g. '2015-01-01',
   * [end] a day in the yyyy-mm-dd format, e.g. '2015-01-09'.  This is inclusive of end date.
   * db.DA_LMP.aggregate([{$match: {ptid: {$in: [4001, 4000]}}},
   *   {$group: {_id: null, yMin: {$min: '$congestionComponent'}, yMax: {$max: '$congestionComponent'}}}])
   */
    @ApiMethod(path: 'minmax/{maskedUnitId}')
    //url http://127.0.0.1:8080/energyoffers/v1/maskedunitid/60802
    Future<Map> getLimits(List<int> ptids, String start, String end,
      {String frequency: 'hourly'}) {
    List pipeline = [];
    var groupId;
    Map group;
//    String startDate = new DateFormat('yyyy-MM-dd').format(start);
//    String endDate = new DateFormat('yyyy-MM-dd').format(end);

    var match = {'\$match': _constructMatchClause(ptids, start, end)};

    if (frequency == 'daily') {
      groupId = {
        'ptid': '\$ptid',
        'year': {'\$year': '\$hourBeginning'},
        'month': {'\$month': '\$hourBeginning'},
        'day': {'\$dayOfMonth': '\$hourBeginning'}
      };
    } else if (frequency == 'monthly') {
      groupId = {
        'ptid': '\$ptid',
        'year': {'\$year': '\$hourBeginning'},
        'month': {'\$month': '\$hourBeginning'}
      };
    }

    if (frequency != 'hourly') {
      // i need to average it first
      group = {
        '\$group': {
          '_id': groupId,
          'congestionComponent': {'\$avg': '\$congestionComponent'}
        }
      };
    } else {
      // for hourly data calculate the min and max directly
      group = {
        '\$group': {
          '_id': null,
          'yMin': {'\$min': '\$congestionComponent'},
          'yMax': {'\$max': '\$congestionComponent'}
        }
      };
    }
    ;

    pipeline.add(match);
    pipeline.add(group);

    if (frequency != 'hourly') {
      // i need to aggregate further (the days or the months)
      var group2 = {
        '\$group': {
          '_id': null,
          'yMin': {'\$min': '\$congestionComponent'},
          'yMax': {'\$max': '\$congestionComponent'}
        }
      };
      pipeline.add(group2);
    }

    ///print(pipeline);
    return coll.aggregate(pipeline).then((v) {
      ///print(v['result']);
      return v['result'].first;
    });
  }

  /**
   * Get the hourly congestion data from the table,
   * from [start, end) DateTime.   Note that end is exclusive!
   * Try to to get too much data at once (Should I worry about this here?!).
   * db.DA_LMP.find({ptid: {$in: [321, 4000]}}, {_id: 0}).limit(10)
   * TODO: does the result need to be ordered by ptid and hourBeginning?  Don't think so...
   */
  Future<List<Map>> getHourlyCongestionData(
      List<int> ptids, DateTime start, DateTime end) {
    assert(start.isUtc);
    assert(end.isUtc);
    SelectorBuilder sb = where;

    if (ptids != null && ptids.isNotEmpty) sb = sb.oneFrom('ptid', ptids);

    // if you want to pull all the ptids at once, better to be a bit careful ...
    if (start != null) sb = sb.gte('hourBeginning', start);

    if (end != null) sb = sb.lt('hourBeginning', end);

    //print(sb.toString());
    return coll
        .find(sb.excludeFields(['_id']).sortBy('ptid').sortBy('hourBeginning'))
        .toList();
    //return coll.find(sb.excludeFields(['_id'])).toList();
  }

  /**
   * Aggregate the hourly data daily between start and end dates inclusive.
   * [start] a day in the yyyy-mm-dd format, e.g. '2015-01-01'
   * [end] a day in the yyyy-mm-dd format, e.g. '2015-01-09'
   *
   *
   * db.DA_LMP.aggregate([{$match: {ptid: {$in: [321, 4000]}}}, {$group: {_id: {ptid: {$ptid}, localDate: {$localDate}}, congestionComponent: {$avg: '$congestionComponent'}}}])
   */
  Future<List<Map>> getDailyCongestionData(

      List<int> ptids, String start, String end) {
    assert(start.compareTo(end) < 1);
    List pipeline = [];
    var match = {'\$match': _constructMatchClause(ptids, start, end)};
    var group = {
      '\$group': {
        '_id': {'ptid': '\$ptid', 'localDate': '\$localDate'},
        'congestionComponent': {'\$avg': '\$congestionComponent'}
      }
    };
    var sort = {
      '\$sort': {'_id.ptid': 1, '_id.localDate': 1}
    };
    pipeline.add(match);
    pipeline.add(group);
    pipeline.add(sort);
    //print(pipeline);
    return coll.aggregate(pipeline).then((v) {
      //print(v['result']);
      return v['result'].map((Map doc) {
        return {
          'date': DateTime.parse('${doc['_id']['localDate']}'),
          'ptid': doc['_id']['ptid'],
          'congestionComponent': doc['congestionComponent']
        };
      }).toList();
    });
    // {date: DateTime(2014,12,26), ptid: 321, congestionComponent: 4.381666666666667}
    // {date: DateTime(2014,12,27), ptid: 321, congestionComponent: 11.077083333333334}
  }

  /**
   * Aggregate data monthly between the months start and end inclusive.
   * start a String representing a date in yyyy-mm-dd format, beginning of the month
   * end a String representing a date in yyyy-mm-dd format, beginning of the month
   * Result looks like this:
   * [{month: DateTime(2014,1), ptid: 4005, congestionComponent: 1.1392876344086023},
   * {month: DateTime(2014,2), ptid: 4005, congestionComponent: 0.6015029761904762}
   * {month: DateTime(2014,3), ptid: 4005, congestionComponent: 0.8584656796769845}
   * {month: DateTime(2014,4), ptid: 4005, congestionComponent: -0.09127777777777786}]
   * db.DA_LMP.aggregate([{$match: {ptid: {$in: [321]}, localDate: {$gte: '2014-12-01', $lte: '2014-12-01'}}}, {$project: {congestionComponent: 1, ptid: 1, month: {$substr: ['$localDate', 0, 7]}}},
      {$group: {}}])
   */
  Future<List<Map>> getMonthlyCongestionData(
      List<int> ptids, String start, String end) {
    assert(start.substring(7) == '-01');
    assert(end.substring(7) == '-01');
    assert(start.compareTo(end) < 1);
    var startDate = start;
    // go to the end of month for the end Date
    var aux =
        nextMonth(from: DateTime.parse(end)).subtract(new Duration(days: 1));
    var endDate = new DateFormat('yyyy-MM-dd').format(aux);

    List pipeline = [];

    var match = {'\$match': _constructMatchClause(ptids, startDate, endDate)};
    var project = {
      '\$project': {
        'congestionComponent': 1,
        'ptid': 1,
        'month': {
          '\$substr': ['\$localDate', 0, 7]
        }
      }
    };
    var group = {
      '\$group': {
        '_id': {'ptid': '\$ptid', 'month': '\$month'},
        'congestionComponent': {'\$avg': '\$congestionComponent'}
      }
    };
    var sort = {
      '\$sort': {'_id.ptid': 1, '_id.month': 1}
    };
    pipeline.add(match);
    pipeline.add(project);
    pipeline.add(group);
    pipeline.add(sort);
    //print(pipeline);
    return coll.aggregate(pipeline).then((v) {
      //print(v['result']);
      return v['result'].map((Map doc) {
        return {
          'month': DateTime.parse('${doc['_id']['month']}-01'),
          'ptid': doc['_id']['ptid'],
          'congestionComponent': doc['congestionComponent']
        };
      }).toList();
    });
  }

  /**
   * Format the return of getData from the long format to the wide format (to minimize
   * the amount of data transferred).  Hourly data is in hourBeginning format
   * [frequency] is one of 'hourly', 'daily', 'monthly'.
   * Argument data is in format:
   *  [{'hourBeginning': x, 'ptid': x, 'congestionComponent': x},
   *   {'hourBeginning': x, 'ptid': x, 'congestionComponent': x}]
   * Output is in format:
   *    {'321': {'DT': [dt1, dt2, ...], 'CC': [c1, c2, ...]}},
   *     '322': {'DT': [dt1, dt2, ...], 'CC': [c1, c2, ...]}},
   *    ...}
   * where dt1, dt2, etc. are int millisecondsSinceEpoch
   */
  Map<String, Map> toWideFormat(List<Map> data, String frequency) {
    // need to traverse twice ... // TODO explore if you do this in one pass ...
    Map idFreq = {
      'hourly': 'hourBeginning',
      'daily': 'date',
      'monthly': 'month'
    };
    String id = idFreq[frequency];

    // group all rows by ptid
    Map<String, List> gData = {};
    data.forEach(
        (row) => gData.putIfAbsent(row['ptid'].toString(), () => []).add(row));

    Map<String, Map> res = {};
    gData.keys.forEach((String key) => res[key] = {'DT': [], 'CC': []});
    for (String key in gData.keys) {
      //print('Transposing $key ...');
      gData[key].forEach((row) {
        res[key]['DT'].add(row[id].millisecondsSinceEpoch);
        res[key]['CC'].add(row['congestionComponent']);
      });
    }

    return res;
  }


  /**
   * For the pipeline aggregation queries
   * start and end are Strings in yyyy-mm-dd format.
   */
  Map _constructMatchClause(List<int> ptids, String start, String end) {
    Map aux = {};
    if (ptids != null) aux['ptid'] = {'\$in': ptids};
    if (start != null) {
      if (!aux.containsKey('localDate')) aux['localDate'] = {};

      aux['localDate']['\$gte'] = start;
    }
    if (end != null) {
      if (!aux.containsKey('localDate')) aux['localDate'] = {};

      aux['localDate']['\$lte'] = end;
    }

    return aux;
  }
}

/**
 * Deal with downloading the data, massaging it, and loading it into mongo.
 */
class DamArchive extends Config with DailyArchive {
  DbCollection coll;
  Location location;

  DamArchive({Config config}) {
    if (config == null) config = new DefaultConfig();
    dbName = config.dbName;
    DIR = config.DIR;
    collectionName = config.collectionName;
    db = config.db;

    coll = db.collection(collectionName);
    initializeTimeZoneSync();
    location = getLocation('America/New_York');
  }

  String yyyymmdd(Date date) {
    var mm = date.month.toString().padLeft(2, '0');
    var dd = date.day.toString().padLeft(2, '0');
    return '${date.year}$mm$dd';
  }

  /**
   * Read the csv file and prepare it for ingestion into mongo.
   * DateTimes need to be hourBeginning UTC, etc.
   */
  List<Map> oneDayRead(Date date) {
    File file = new File(DIR + "/WW_DALMP_ISO_${yyyymmdd(date)}.csv");
    if (file.existsSync()) {
      List<String> keys = ['hourBeginning', 'ptid', 'Lmp_Cong_Loss'];

      List<Map> data = file
          .readAsLinesSync()
          .map((String row) => row.split(','))
          .where((List row) => row.first == '"D"')
          .map((List row) {
        return new Map.fromIterables(keys, [
          parseHourEndingStamp(_unquote(row[1]), _unquote(row[2]), location),
          int.parse(_unquote(row[3])), // ptid
          [
            num.parse(row[6]),
            num.parse(row[8]),
            num.parse(row[9])
          ] // LMP, Congestion, Losses
        ]);
      }).toList();

      return data;
    } else {
      throw 'Could not find file for day $date';
    }
  }

  String _unquote(String x) => x.substring(1, x.length - 1);

  /**
   * Ingest one day prices in mongo
   */
  Future oneDayMongoInsert(Date date) {
    List data;
    try {
      data = oneDayRead(date);
    } catch (e) {
      return new Future.value(print('ERROR:  No file for day $date}'));
    }

    print('Inserting day $date into db');
    return coll
        .insertAll(data)
        .then((_) => print('--->  SUCCESS'))
        .catchError((e) => print('   ' + e.toString()));
  }

  /**
   * Download the file if not in the archive folder.  If file is already downloaded, no nothing.
   */
  Future oneDayDownload(Date date) async {
    File fileout = new File(DIR + "/WW_DALMP_ISO_${yyyymmdd(date)}.csv");
    if (fileout.existsSync()) {
      print('  file already downloaded');
      return new Future.value(print('Day $date was already downloaded.'));
    } else {
      String URL =
          "http://www.iso-ne.com/static-transform/csv/histRpts/da-lmp/WW_DALMP_ISO_${yyyymmdd(date)}.csv";
      HttpClient client = new HttpClient();
      HttpClientRequest request = await client.getUrl(Uri.parse(URL));
      HttpClientResponse response = await request.close();
      await response.pipe(fileout.openWrite());
      print('Downloaded short term outages for day $date.');
    }
  }

  /**
   * Return the last day that was ingested in the db.
   * db.DA_LMP.aggregate([{$group: {_id: null, firstHour: {$min: '$hourBeginning'}, lastHour: {$max: '$hourBeginning'}}}])
   */
  Future<Date> lastDayInserted() async {
    DateTime lastDay;

    List pipeline = [];
    var group = {
      '\$group': {
        '_id': null,
        'last': {'\$max': '\$hourBeginning'}
      }
    };
    pipeline.add(group);

    Map v = await coll.aggregate(pipeline);
    Map aux = v['result'].first;
    lastDay = aux['last']; // a local datetime
    return new Date(lastDay.year, lastDay.month, lastDay.day);
  }


  /**
   * Remove all the data for a given day (in case the insert fails midway)
   */
  removeDataForDay(Date date) async {
    SelectorBuilder sb = where;

    TZDateTime start = new TZDateTime(location, date.year, date.month, date.day).toUtc();
    sb = sb.gte('hourBeginning', start);

    Date next = date.next;
    TZDateTime end = new TZDateTime(location, next.year, next.month, next.day).toUtc();
    sb = sb.lt('hourBeginning', end);

    await coll.remove(sb);
  }



  /**
   * Recreate the collection from scratch.
   */
  setup() async {
    if (!new Directory(DIR).existsSync()) new Directory(DIR)
        .createSync(recursive: true);
    await oneDayDownload(new Date(2014, 1, 1));

    await db.open();
    List<String> collections = await db.getCollectionNames();
    print('Collections in db:');
    print(collections);
    if (collections.contains(collectionName)) await coll.drop();
    await oneDayMongoInsert(new Date(2014, 1, 1));

    // this indexing assures that I don't insert the same data twice
    await db.createIndex(collectionName,
        keys: {'hourBeginning': 1, 'ptid': 1}, unique: true);

    await db.close();
  }

  /**
   * Bring the table up to date.
   */
  updateDb(Date start, Date end) async {
    // TODO: make start/end dependent on the data.
    await db.open();
    Date day = start;
    while (day < end) {
      await oneDayDownload(day);
      await oneDayMongoInsert(day);
      day = day.next;
    }
    await db.close();
  }
}
