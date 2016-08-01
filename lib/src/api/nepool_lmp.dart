library api.nepool_lmp;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';

import 'package:elec/elec.dart';
import 'package:elec/src/iso/nepool/config.dart';
import 'package:elec/src/time/bucket/bucket.dart';


/**
 * +0400 for EDT, +0500 for EST
 * db.DA_LMP.find({ptid: 321, hourBeginning: {$lte: ISODate('2014-11-03T04:00:00Z')}})
 * db.DA_LMP.find({ptid: 321, hourBeginning: {$gte: ISODate('2014-11-05T05:00:00Z')}}).limit(5)
 *
 *
 */
@ApiClass(name: 'dalmp', version: 'v1')
class DaLmp {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");

  DaLmp() {
    ComponentConfig component = config.nepool_dam_lmp_hourly;
    coll = component.db.collection(component.collectionName);
    _location = getLocation('US/Eastern');
  }


  /**
   * Get the hourly congestion data between two dates,
   * from [startDate, endDate] Date.   This includes the hours from
   * endDate.  Both startDate and endDate need to be in ISO format 'yyyy-mm-dd'
   *
   */
  @ApiMethod(path: 'mcc/ptid/{ptid}')
  Future<List<Map<String, String>>> apiGetHourlyCongestionData(int ptid) {
    return getHourlyCongestionData(ptid)
        .map((e) => _mccMessage(e))
        .toList();
  }

  @ApiMethod(path: 'mcc/ptid/{ptid}/start/{start}')
  Future<List<Map<String, String>>> apiGetHourlyCongestionDataStart(int ptid, String start) {
    Date startDate = Date.parse(start);
    return getHourlyCongestionData(ptid, startDate: startDate)
    .map((e) => _mccMessage(e))
    .toList();
  }

  @ApiMethod(path: 'mcc/ptid/{ptid}/end/{end}')
  Future<List<Map<String, String>>> apiGetHourlyCongestionDataEnd(int ptid, String end) {
    Date endDate = Date.parse(end);
    return getHourlyCongestionData(ptid, endDate: endDate)
    .map((e) => _mccMessage(e))
    .toList();
  }

  @ApiMethod(path: 'mcc/ptid/{ptid}/start/{start}/end/{end}')
  Future<List<Map<String, String>>> apiGetHourlyCongestionDataStartEnd(int ptid, String start, String end) {
    Date startDate = Date.parse(start);
    Date endDate = Date.parse(end);
    return getHourlyCongestionData(ptid, startDate: startDate, endDate: endDate)
    .map((e) => _mccMessage(e))
    .toList();
  }

  @ApiMethod(path: 'ptids')
  Future<List<int>> allPtids() async {
    Map res = await coll.distinct('ptid');
    return res['values'];
  }

  Map _mccMessage(Tuple2<Hour,num> e) => {
    'HB': e.item1.start.toString(),
    'mcc': e.item2
  };

  /**
   * Get the hourly congestion data between two dates,
   * from [startDate, endDate] Date.   This includes the hours from
   * endDate.  Both startDate and endDate need to be in ISO format 'yyyy-mm-dd'
   *
   */
  Stream<Tuple2<Hour,num>> getHourlyCongestionData(
      int ptid, {Date startDate, Date endDate}) {
    List pipeline = [];
    Map match = {
      'ptid': {'\$eq': ptid}
    };
    Map hb = {};
    if (startDate != null) {
      TZDateTime start = new TZDateTime(_location, startDate.year, startDate.month, startDate.day);
      hb['\$gte'] = start;
    }
    if (endDate != null) {
      endDate= endDate.add(1);
      TZDateTime end = new TZDateTime(_location, endDate.year, endDate.month, endDate.day);
      hb['\$lt'] = end;
    }
    if (hb.isNotEmpty) match['hourBeginning'] = hb;

    Map project = {'_id': 0, 'hourBeginning': 1, 'mcc': '\$price.cong'};

    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    return coll.aggregateToStream(pipeline)
    .map((e) => new Tuple2<Hour,num>(new Hour.beginning(new TZDateTime.from(e['hourBeginning'], _location)), e['mcc']));
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
//  Map<String, Map> toWideFormat(List<Map> data, String frequency) {
//    // need to traverse twice ... // TODO explore if you do this in one pass ...
//    Map idFreq = {
//      'hourly': 'hourBeginning',
//      'daily': 'date',
//      'monthly': 'month'
//    };
//    String id = idFreq[frequency];
//
//    // group all rows by ptid
//    Map<String, List> gData = {};
//    data.forEach(
//        (row) => gData.putIfAbsent(row['ptid'].toString(), () => []).add(row));
//
//    Map<String, Map> res = {};
//    gData.keys.forEach((String key) => res[key] = {'DT': [], 'CC': []});
//    for (String key in gData.keys) {
//      //print('Transposing $key ...');
//      gData[key].forEach((row) {
//        res[key]['DT'].add(row[id].millisecondsSinceEpoch);
//        res[key]['CC'].add(row['congestionComponent']);
//      });
//    }
//
//    return res;
//  }

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


  /**
   * Get the low and high limit for the data to define the yScale for plotting.
   * [start] a day in the yyyy-mm-dd format, e.g. '2015-01-01',
   * [end] a day in the yyyy-mm-dd format, e.g. '2015-01-09'.  This is inclusive of end date.
   * db.DA_LMP.aggregate([{$match: {ptid: {$in: [4001, 4000]}}},
   *   {$group: {_id: null, yMin: {$min: '$congestionComponent'}, yMax: {$max: '$congestionComponent'}}}])
   */
  //@ApiMethod(path: 'minmax/{maskedUnitId}')
  //url http://127.0.0.1:8080/dalmp/v1/maskedunitid/60802
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



}
