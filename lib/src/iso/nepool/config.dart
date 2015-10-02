library iso.nepool.config;

import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

class ComponentConfig {
  /// name of the computer that houses the collection
  String host;
  /// name of the mongo database
  String dbName;
  /// name of the mongo collection
  String collectionName;
  /// location on hard drive where external data is held
  String DIR;
  /// get the mongo database
  Db get db => new Db('mongodb://$host/$dbName');
}


abstract class Config {
  String configName; // prod, test, etc.
  String host;
  Map<String, ComponentConfig> components;
}


class LocalConfig implements Config {
  String configName = 'test';
  String host = '127.0.0.1';

  Map<String, ComponentConfig> components = {};

  LocalConfig() {
    Map env = Platform.environment;

    ComponentConfig nepool_dam_lmp_hourly = new ComponentConfig()
      ..host = host
      ..dbName = 'nepool_dam'
      ..collectionName = 'lmp_hourly'
      ..DIR = env['HOME'] + '/Downloads/Archive/DA_LMP/Raw/Csv';


    components['nepool_dam_lmp_hourly'] = nepool_dam_lmp_hourly;


  }
}
