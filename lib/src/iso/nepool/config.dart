library iso.nepool.config;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';


class ComponentConfig {
  Db _db;
  /// name of the mongo database
  String dbName;
  /// name of the computer that houses the collection
  String host;
  /// name of the mongo collection
  String collectionName;
  /// location on hard drive where external data is held
  String DIR;
  /// get the mongo database
  Db get db {
    if (_db == null) _db = new Db('mongodb://$host/$dbName');
    return _db;
  }
  DbCollection get coll => db.collection(collectionName);
}


abstract class Config {
  String configName; // prod, test, etc.
  String host;

  ComponentConfig nepool_binding_constraints_da;
  ComponentConfig nepool_dam_lmp_hourly;

  Future open() async {
    initializeTimeZoneSync();
    await nepool_dam_lmp_hourly.db.open();
    await nepool_binding_constraints_da.db.open();
  }

  Future close() async {
    await nepool_dam_lmp_hourly.db.close();
    await nepool_binding_constraints_da.db.close();
  }

}


class TestConfig extends Config {
  String configName = 'test';
  String host = '127.0.0.1';

  TestConfig() {
    Map env = Platform.environment;

    nepool_binding_constraints_da = new ComponentConfig()
      ..host = host
      ..dbName = 'nepool'
      ..collectionName = 'binding_constraints'
      ..DIR = env['HOME'] + '/Downloads/Archive/DA_BindingConstraints/Raw/';

    nepool_dam_lmp_hourly = new ComponentConfig()
      ..host = host
      ..dbName = 'nepool_dam'
      ..collectionName = 'lmp_hourly'
      ..DIR = env['HOME'] + '/Downloads/Archive/DA_LMP/Raw/Csv';

  }


}
